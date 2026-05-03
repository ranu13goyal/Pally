import Foundation

final class GoogleNewsURLDecoder {
    
    func decodeIfNeeded(_ urlString: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: urlString),
              url.host?.contains("news.google.com") == true else {
            completion(urlString)
            return
        }
        
        let pathComponents = url.pathComponents
        guard let encodedID = pathComponents.last,
              pathComponents.contains("articles") || pathComponents.contains("read") else {
            completion(urlString)
            return
        }
        
        if let decodedURL = decodeLegacyURL(from: encodedID) {
            completion(decodedURL)
            return
        }
        
        fetchDecodeParameters(for: encodedID, fallbackURL: urlString) { params in
            guard let params else {
                completion(urlString)
                return
            }
            
            self.fetchDecodedURL(
                encodedID: encodedID,
                timestamp: params.timestamp,
                signature: params.signature,
                fallbackURL: urlString,
                completion: completion
            )
        }
    }
    
    private func decodeLegacyURL(from encodedID: String) -> String? {
        guard let data = Data(base64URLEncoded: encodedID),
              !data.isEmpty else {
            return nil
        }
        
        var bytes = [UInt8](data)
        let prefix: [UInt8] = [0x08, 0x13, 0x22]
        if bytes.starts(with: prefix) {
            bytes.removeFirst(prefix.count)
        }
        
        let suffix: [UInt8] = [0xd2, 0x01, 0x00]
        if bytes.count >= suffix.count && Array(bytes.suffix(suffix.count)) == suffix {
            bytes.removeLast(suffix.count)
        }
        
        guard !bytes.isEmpty else { return nil }
        
        let payloadBytes: ArraySlice<UInt8>
        let firstByte = bytes[0]
        if firstByte >= 0x80, bytes.count > 1 {
            let length = Int(bytes[1])
            guard bytes.count >= length + 2 else { return nil }
            payloadBytes = bytes[2..<(2 + length)]
        } else {
            let length = Int(firstByte)
            guard bytes.count >= length + 1 else { return nil }
            payloadBytes = bytes[1..<(1 + length)]
        }
        
        guard let payload = String(bytes: payloadBytes, encoding: .utf8),
              payload.hasPrefix("http://") || payload.hasPrefix("https://") else {
            return nil
        }
        
        return payload
    }
    
    private func fetchDecodeParameters(
        for encodedID: String,
        fallbackURL: String,
        completion: @escaping ((signature: String, timestamp: String)?) -> Void
    ) {
        let candidateURLs = [
            fallbackURL,
            "https://news.google.com/articles/\(encodedID)"
        ]
        
        fetchParameters(from: candidateURLs, index: 0, completion: completion)
    }
    
    private func fetchParameters(
        from candidates: [String],
        index: Int,
        completion: @escaping ((signature: String, timestamp: String)?) -> Void
    ) {
        guard index < candidates.count,
              let url = URL(string: candidates[index]) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode),
                  let signature = self.firstMatch(in: html, pattern: #"data-n-a-sg="([^"]+)""#),
                  let timestamp = self.firstMatch(in: html, pattern: #"data-n-a-ts="([^"]+)""#) else {
                self.fetchParameters(from: candidates, index: index + 1, completion: completion)
                return
            }
            
            completion((signature, timestamp))
        }.resume()
    }
    
    private func fetchDecodedURL(
        encodedID: String,
        timestamp: String,
        signature: String,
        fallbackURL: String,
        completion: @escaping (String) -> Void
    ) {
        guard let url = URL(string: "https://news.google.com/_/DotsSplashUi/data/batchexecute?rpcids=Fbv4je") else {
            completion(fallbackURL)
            return
        }
        
        let innerPayload = """
        ["garturlreq",[["X","X",["X","X"],null,null,1,1,"US:en",null,1,null,null,null,null,null,0,1],"X","X",1,[1,1,1],1,1,null,0,0,null,0],"\(encodedID)",\(timestamp),"\(signature)"]
        """
        let wrappedPayload = """
        [[["Fbv4je","\(escapeForBatch(innerPayload))",null,"generic"]]]
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("https://news.google.com/", forHTTPHeaderField: "Referrer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        let encodedBody = wrappedPayload.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        request.httpBody = "f.req=\(encodedBody)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let response = String(data: data, encoding: .utf8) else {
                completion(fallbackURL)
                return
            }
            
            let normalizedResponse = response.replacingOccurrences(of: "\\\"", with: "\"")
            let pattern = #"\["garturlres","(https?:[^"]+)""#
            guard let rawURL = self.firstMatch(in: normalizedResponse, pattern: pattern) else {
                completion(fallbackURL)
                return
            }
            
            let cleanedURL = rawURL
                .replacingOccurrences(of: "\\u003d", with: "=")
                .replacingOccurrences(of: "\\u0026", with: "&")
                .replacingOccurrences(of: "\\/", with: "/")
            
            completion(cleanedURL)
        }.resume()
    }
    
    private func escapeForBatch(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let swiftRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        return String(text[swiftRange])
    }
}

private extension Data {
    init?(base64URLEncoded string: String) {
        let normalized = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = String(repeating: "=", count: (4 - normalized.count % 4) % 4)
        self.init(base64Encoded: normalized + padding)
    }
}
