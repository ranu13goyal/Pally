import Foundation

struct SummaryInputResult {
    let input: String
    let usedFallback: Bool
}

final class ContentFetcher {
    
    private let minimumBodyLength = 500
    
    func fetchSummaryInput(
        from urlString: String,
        title: String,
        snippet: String,
        maxLength: Int = 5000,
        completion: @escaping (SummaryInputResult) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(fallbackInput(title: title, snippet: snippet, finalURL: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            let finalURL = response?.url?.absoluteString ?? urlString
            
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) else {
                DispatchQueue.main.async {
                    completion(self.fallbackInput(title: title, snippet: snippet, finalURL: finalURL))
                }
                return
            }
            
            let extracted = self.extractReadableText(from: html, fallbackTitle: title, fallbackSnippet: snippet)
            let result: SummaryInputResult
            
            if extracted.body.count < self.minimumBodyLength {
                result = self.fallbackInput(title: extracted.title ?? title, snippet: extracted.subtitle ?? snippet, finalURL: finalURL)
            } else {
                let merged = self.buildStrongInput(
                    title: extracted.title ?? title,
                    subtitle: extracted.subtitle,
                    body: extracted.body,
                    finalURL: finalURL,
                    maxLength: maxLength
                )
                result = SummaryInputResult(input: merged, usedFallback: false)
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }
    
    private func buildStrongInput(
        title: String,
        subtitle: String?,
        body: String,
        finalURL: String,
        maxLength: Int
    ) -> String {
        var sections: [String] = []
        sections.append("Extraction status: full article body")
        sections.append("URL:\n\(finalURL)")
        sections.append("Headline:\n\(cleanText(title))")
        
        if let subtitle, !subtitle.isEmpty {
            sections.append("Subheadline:\n\(cleanText(subtitle))")
        }
        
        sections.append("Article Body:\n\(cleanText(body))")
        return String(sections.joined(separator: "\n\n").prefix(maxLength))
    }
    
    private func fallbackInput(title: String, snippet: String, finalURL: String?) -> SummaryInputResult {
        var sections: [String] = []
        sections.append("Extraction status: limited article text")
        
        if let finalURL, !finalURL.isEmpty {
            sections.append("URL:\n\(finalURL)")
        }
        
        sections.append("Headline:\n\(cleanText(title))")
        
        let cleanedSnippet = cleanText(snippet)
        if !cleanedSnippet.isEmpty {
            sections.append("Snippet:\n\(cleanedSnippet)")
        }
        
        return SummaryInputResult(
            input: sections.joined(separator: "\n\n"),
            usedFallback: true
        )
    }
    
    private func extractReadableText(from html: String, fallbackTitle: String, fallbackSnippet: String) -> (title: String?, subtitle: String?, body: String) {
        let sanitizedHTML = sanitizeHTML(html)
        
        let title = extractTitle(from: sanitizedHTML) ?? cleanText(fallbackTitle)
        let subtitle = extractSubtitle(from: sanitizedHTML) ?? cleanText(fallbackSnippet)
        
        let jsonLDContent = extractJSONLDContent(from: html)
        let containerContent = extractContainerContent(from: sanitizedHTML)
        let paragraphContent = extractParagraphContent(from: sanitizedHTML)
        
        let candidates = [jsonLDContent.body, containerContent, paragraphContent]
            .map { cleanText($0) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }
        
        let chosenBody = candidates.first ?? ""
        
        return (
            title: cleanText(jsonLDContent.title).nonEmpty ?? title.nonEmpty,
            subtitle: cleanText(jsonLDContent.subtitle).nonEmpty ?? subtitle.nonEmpty,
            body: chosenBody
        )
    }
    
    private func sanitizeHTML(_ html: String) -> String {
        let withoutCode = html
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<noscript[^>]*>[\\s\\S]*?</noscript>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<svg[^>]*>[\\s\\S]*?</svg>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<form[^>]*>[\\s\\S]*?</form>", with: " ", options: .regularExpression)
        
        let noisePattern = #"<(nav|footer|aside|header|button)[^>]*(class|id)?[^>]*(related|recommend|trending|subscribe|newsletter|promo|advert|cookie|share|comment|social|footer|header|nav|recirculation|most-read)[^>]*>[\s\S]*?</\1>"#
        return withoutCode.replacingOccurrences(of: noisePattern, with: " ", options: [.regularExpression, .caseInsensitive])
    }
    
    private func extractTitle(from html: String) -> String? {
        let patterns = [
            #"<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+name=["']twitter:title["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<h1[^>]*>(.*?)</h1>"#,
            #"<title[^>]*>(.*?)</title>"#
        ]
        
        for pattern in patterns {
            if let value = firstMatch(in: html, pattern: pattern, dotMatchesNewlines: true) {
                let cleaned = cleanText(value)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }
        
        return nil
    }
    
    private func extractSubtitle(from html: String) -> String? {
        let patterns = [
            #"<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+name=["']twitter:description["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<h2[^>]*>(.*?)</h2>"#
        ]
        
        for pattern in patterns {
            if let value = firstMatch(in: html, pattern: pattern, dotMatchesNewlines: true) {
                let cleaned = cleanText(value)
                if cleaned.count > 30 {
                    return cleaned
                }
            }
        }
        
        return nil
    }
    
    private func extractJSONLDContent(from html: String) -> (title: String, subtitle: String, body: String) {
        let scripts = allMatches(
            in: html,
            pattern: #"<script[^>]+type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#,
            dotMatchesNewlines: true
        )
        
        var titles: [String] = []
        var subtitles: [String] = []
        var bodies: [String] = []
        
        for script in scripts {
            let data = Data(script.utf8)
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                collectJSONLDStrings(
                    from: jsonObject,
                    titles: &titles,
                    subtitles: &subtitles,
                    bodies: &bodies
                )
            }
        }
        
        return (
            title: titles.max(by: { $0.count < $1.count }) ?? "",
            subtitle: subtitles.max(by: { $0.count < $1.count }) ?? "",
            body: bodies.max(by: { $0.count < $1.count }) ?? ""
        )
    }
    
    private func collectJSONLDStrings(
        from object: Any,
        titles: inout [String],
        subtitles: inout [String],
        bodies: inout [String]
    ) {
        if let array = object as? [Any] {
            for item in array {
                collectJSONLDStrings(from: item, titles: &titles, subtitles: &subtitles, bodies: &bodies)
            }
            return
        }
        
        guard let dictionary = object as? [String: Any] else { return }
        
        if let headline = dictionary["headline"] as? String {
            titles.append(headline)
        }
        
        if let alternativeHeadline = dictionary["alternativeHeadline"] as? String {
            subtitles.append(alternativeHeadline)
        }
        
        if let description = dictionary["description"] as? String {
            subtitles.append(description)
        }
        
        if let body = dictionary["articleBody"] as? String {
            bodies.append(body)
        }
        
        if let graph = dictionary["@graph"] {
            collectJSONLDStrings(from: graph, titles: &titles, subtitles: &subtitles, bodies: &bodies)
        }
        
        for value in dictionary.values {
            if value is [String: Any] || value is [Any] {
                collectJSONLDStrings(from: value, titles: &titles, subtitles: &subtitles, bodies: &bodies)
            }
        }
    }
    
    private func extractContainerContent(from html: String) -> String {
        let patterns = [
            #"<article[^>]*>([\s\S]*?)</article>"#,
            #"<section[^>]*(?:article|story|content|body|post)[^>]*>([\s\S]*?)</section>"#,
            #"<div[^>]*(?:article-body|story-body|entry-content|post-content|article-content|main-content|content-body|story-content|article__body)[^>]*>([\s\S]*?)</div>"#,
            #"<main[^>]*>([\s\S]*?)</main>"#
        ]
        
        var candidates: [String] = []
        
        for pattern in patterns {
            let matches = allMatches(in: html, pattern: pattern, dotMatchesNewlines: true)
            for match in matches {
                let cleaned = extractParagraphContent(from: removeNoiseBlocks(from: match))
                if cleaned.count > 200 {
                    candidates.append(cleaned)
                }
            }
        }
        
        return candidates.max(by: { $0.count < $1.count }) ?? ""
    }
    
    private func removeNoiseBlocks(from html: String) -> String {
        let patterns = [
            #"<(div|section|aside)[^>]*(related|recommend|trending|subscribe|newsletter|promo|advert|cookie|share|comment|social|outbrain|taboola|footer|header|nav|most-read)[^>]*>[\s\S]*?</\1>"#,
            #"<ul[^>]*(related|recommend|trending|share|comment)[^>]*>[\s\S]*?</ul>"#
        ]
        
        return patterns.reduce(html) { partial, pattern in
            partial.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
    }
    
    private func extractParagraphContent(from html: String) -> String {
        let paragraphBlocks = allMatches(
            in: html,
            pattern: #"<p[^>]*>([\s\S]*?)</p>"#,
            dotMatchesNewlines: true
        )
        
        let cleanedParagraphs = paragraphBlocks
            .map(cleanText)
            .filter { paragraph in
                paragraph.count > 60 &&
                !looksLikeBoilerplate(paragraph)
            }
        
        return cleanedParagraphs.prefix(18).joined(separator: "\n")
    }
    
    private func looksLikeBoilerplate(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let noiseTerms = [
            "subscribe", "sign up", "newsletter", "advertisement", "follow us",
            "read more", "click here", "all rights reserved", "cookie policy",
            "create an account", "share this article", "most read", "related articles"
        ]
        
        return noiseTerms.contains { lowered.contains($0) }
    }
    
    private func cleanText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&#8211;", with: "-")
            .replacingOccurrences(of: "&mdash;", with: "-")
            .replacingOccurrences(of: "&ndash;", with: "-")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func firstMatch(in text: String, pattern: String, dotMatchesNewlines: Bool = false) -> String? {
        var options: NSRegularExpression.Options = [.caseInsensitive]
        if dotMatchesNewlines {
            options.insert(.dotMatchesLineSeparators)
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
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
    
    private func allMatches(in text: String, pattern: String, dotMatchesNewlines: Bool = false) -> [String] {
        var options: NSRegularExpression.Options = [.caseInsensitive]
        if dotMatchesNewlines {
            options.insert(.dotMatchesLineSeparators)
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let swiftRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[swiftRange])
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
