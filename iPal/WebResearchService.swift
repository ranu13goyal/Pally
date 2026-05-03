import Foundation

struct WebResearchBundle {
    let researchInput: String
    let sourceCount: Int
    let sourceNames: [String]
    let sourceReferences: [StorySourceReference]
}

private struct WebResearchSource: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let snippet: String
    let sourceName: String
    let credibilityScore: Int
}

final class WebResearchService {
    
    private let contentFetcher = ContentFetcher()
    private let newsService = NewsService()
    
    func buildResearchBundle(
        userPrompt: String,
        theme: String,
        completion: @escaping (WebResearchBundle) -> Void
    ) {
        let group = DispatchGroup()
        let lock = NSLock()
        var discoveredSources: [WebResearchSource] = []
        
        let queries = searchQueries(for: userPrompt, theme: theme)
        
        for query in queries {
            group.enter()
            fetchGDELTResults(for: query) { results in
                lock.lock()
                discoveredSources.append(contentsOf: results)
                lock.unlock()
                group.leave()
            }
        }
        
        group.enter()
        fetchWikipediaResults(for: theme) { results in
            lock.lock()
            discoveredSources.append(contentsOf: results)
            lock.unlock()
            group.leave()
        }
        
        group.enter()
        newsService.fetchNews(for: theme) { articles in
            let results = articles.compactMap { article -> WebResearchSource? in
                let cleanedTitle = self.cleanedHeadline(article.title)
                guard self.isUsefulHeadline(cleanedTitle, for: theme) else { return nil }
                
                return WebResearchSource(
                    title: cleanedTitle,
                    url: article.link,
                    snippet: article.snippet,
                    sourceName: self.cleanedSourceName(article.source, fallbackURL: article.link),
                    credibilityScore: self.credibilityScore(for: article.link, sourceName: article.source) + 10
                )
            }
            lock.lock()
            discoveredSources.append(contentsOf: results)
            lock.unlock()
            group.leave()
        }
        
        group.notify(queue: .main) {
            let rankedSources = self.rankAndDeduplicate(discoveredSources)
            let selectedSources = Array(rankedSources.prefix(8))
            
            self.buildResearchInput(
                userPrompt: userPrompt,
                theme: theme,
                sources: selectedSources,
                completion: completion
            )
        }
    }
}

private extension WebResearchService {
    
    func buildResearchInput(
        userPrompt: String,
        theme: String,
        sources: [WebResearchSource],
        completion: @escaping (WebResearchBundle) -> Void
    ) {
        guard !sources.isEmpty else {
            completion(
                WebResearchBundle(
                    researchInput: """
                    User prompt: \(userPrompt)
                    
                    Story theme: \(theme)
                    
                    No reliable web sources were extracted yet. Build a careful explainer, flag uncertainty, and avoid fabricated specifics.
                    """,
                    sourceCount: 0,
                    sourceNames: [],
                    sourceReferences: []
                )
            )
            return
        }
        
        let group = DispatchGroup()
        let lock = NSLock()
        var sourceSections: [String] = []
        
        for source in sources {
            group.enter()
            contentFetcher.fetchSummaryInput(
                from: source.url,
                title: source.title,
                snippet: source.snippet,
                maxLength: 2200
            ) { result in
                let section = """
                Source: \(source.sourceName)
                URL: \(source.url)
                Headline: \(source.title)
                Search snippet: \(source.snippet)
                Extracted notes:
                \(result.input)
                """
                
                lock.lock()
                sourceSections.append(section)
                lock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let sourceNames = Array(NSOrderedSet(array: sources.map(\.sourceName)).array as? [String] ?? [])
            let sourceReferences = sources.map {
                StorySourceReference(
                    sourceName: $0.sourceName,
                    title: $0.title,
                    url: $0.url
                )
            }
            let researchInput = """
            User prompt: \(userPrompt)
            
            Story theme: \(theme)
            
            Build a sourced explainer from the material below.
            Rules:
            - Prefer facts supported across multiple reputable publishers such as Reuters, AP, BBC, Bloomberg, FT, WSJ, NPR, and official institutions.
            - Separate background context from recent developments.
            - If a detail is disputed or weakly sourced, say so.
            - Keep track of which source supports which point.
            
            \(sourceSections.joined(separator: "\n\n---\n\n"))
            """
            
            completion(
                WebResearchBundle(
                    researchInput: researchInput,
                    sourceCount: sources.count,
                    sourceNames: sourceNames,
                    sourceReferences: sourceReferences
                )
            )
        }
    }
    
    func searchQueries(for userPrompt: String, theme: String) -> [String] {
        var seen = Set<String>()
        let candidates = [
            userPrompt,
            theme,
            "\(theme) latest developments",
            "\(theme) explained",
            "\(theme) impact"
        ]
        
        return candidates.compactMap { candidate in
            let cleaned = candidate
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            guard !cleaned.isEmpty else { return nil }
            guard seen.insert(cleaned.lowercased()).inserted else { return nil }
            return cleaned
        }
    }
    
    func fetchGDELTResults(for query: String, completion: @escaping ([WebResearchSource]) -> Void) {
        var components = URLComponents(string: "https://api.gdeltproject.org/api/v2/doc/doc")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "mode", value: "ArtList"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "maxrecords", value: "12"),
            URLQueryItem(name: "sort", value: "HybridRel")
        ]
        
        guard let url = components?.url else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(GDELTResponse.self, from: data) else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let results = response.articles.compactMap { article -> WebResearchSource? in
                let title = self.cleanedHeadline(article.title).nonEmpty ?? article.domain
                let score = self.credibilityScore(for: article.url, sourceName: article.domain)
                guard score >= 70 else { return nil }
                guard self.isUsefulHeadline(title, for: query) else { return nil }
                
                return WebResearchSource(
                    title: title,
                    url: article.url,
                    snippet: "Coverage surfaced by GDELT from \(article.domain).",
                    sourceName: self.prettifiedSourceName(from: article.domain),
                    credibilityScore: score
                )
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }.resume()
    }
    
    func fetchWikipediaResults(for query: String, completion: @escaping ([WebResearchSource]) -> Void) {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "utf8", value: "1"),
            URLQueryItem(name: "srlimit", value: "3"),
            URLQueryItem(name: "srsearch", value: query)
        ]
        
        guard let url = components?.url else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(WikipediaSearchResponse.self, from: data) else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let results = response.query.search.map { result in
                WebResearchSource(
                    title: result.title,
                    url: "https://en.wikipedia.org/?curid=\(result.pageid)",
                    snippet: self.decodeEntities(result.snippet),
                    sourceName: "Wikipedia",
                    credibilityScore: 95
                )
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }.resume()
    }
    
    func rankAndDeduplicate(_ sources: [WebResearchSource]) -> [WebResearchSource] {
        let ranked = sources.sorted { lhs, rhs in
            if lhs.credibilityScore == rhs.credibilityScore {
                return lhs.title.count > rhs.title.count
            }
            return lhs.credibilityScore > rhs.credibilityScore
        }
        
        var seenURLs = Set<String>()
        var seenTitles = Set<String>()
        var results: [WebResearchSource] = []
        
        for source in ranked {
            let urlKey = normalizedKey(source.url)
            let titleKey = normalizedKey(source.title)
            
            if seenURLs.contains(urlKey) || seenTitles.contains(titleKey) {
                continue
            }
            
            seenURLs.insert(urlKey)
            seenTitles.insert(titleKey)
            results.append(source)
        }
        
        return results
    }
    
    func cleanedHeadline(_ text: String) -> String {
        let decoded = decodeEntities(text)
        return decoded
            .replacingOccurrences(of: #"^".*?"\s*-\s*Google News"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"Google News"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #" - [A-Za-z ]+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func cleanedSourceName(_ sourceName: String, fallbackURL: String) -> String {
        let trimmed = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.lowercased() != "google news" {
            return trimmed
        }
        
        guard let host = URL(string: fallbackURL)?.host else {
            return "Source"
        }
        
        return prettifiedSourceName(from: host)
    }
    
    func isUsefulHeadline(_ headline: String, for theme: String) -> Bool {
        let cleaned = normalizedKey(headline)
        let normalizedTheme = normalizedKey(theme)
        
        guard cleaned.count > 12 else { return false }
        guard !cleaned.contains("google news") else { return false }
        guard !cleaned.hasPrefix("layman ") else { return false }
        guard cleaned != normalizedTheme else { return false }
        return true
    }
    
    func credibilityScore(for urlString: String, sourceName: String) -> Int {
        let preferredDomains: [String: Int] = [
            "reuters.com": 150,
            "apnews.com": 150,
            "bbc.com": 145,
            "nytimes.com": 140,
            "wsj.com": 140,
            "ft.com": 140,
            "bloomberg.com": 140,
            "npr.org": 138,
            "theguardian.com": 136,
            "washingtonpost.com": 136,
            "economist.com": 135,
            "aljazeera.com": 132,
            "who.int": 150,
            "cdc.gov": 150,
            "nih.gov": 150,
            "un.org": 145,
            "state.gov": 145,
            "treasury.gov": 145,
            "worldbank.org": 142,
            "imf.org": 142,
            "wikipedia.org": 95
        ]
        
        let blockedTerms = [
            "facebook.com", "instagram.com", "x.com", "twitter.com", "youtube.com",
            "tiktok.com", "reddit.com", "linkedin.com", "pinterest.com"
        ]
        
        guard let host = URL(string: urlString)?.host?.lowercased() else {
            return 0
        }
        
        let cleanedHost = host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        
        if blockedTerms.contains(where: cleanedHost.contains) {
            return 0
        }
        
        if let exact = preferredDomains.first(where: { cleanedHost.contains($0.key) })?.value {
            return exact
        }
        
        var score = 70
        
        if cleanedHost.hasSuffix(".gov") {
            score += 55
        }
        
        if cleanedHost.hasSuffix(".edu") {
            score += 45
        }
        
        if sourceName.lowercased().contains("news") || sourceName.lowercased().contains("times") {
            score += 10
        }
        
        return score
    }
    
    func prettifiedSourceName(from domain: String) -> String {
        domain
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
            .components(separatedBy: ".")
            .first?
            .replacingOccurrences(of: "-", with: " ")
            .capitalized ?? domain
    }
    
    func normalizedKey(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func decodeEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
