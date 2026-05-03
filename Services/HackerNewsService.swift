import Foundation

final class HackerNewsService {
    
    private let maxArticleAgeDays = 15
    
    func fetchStories(for topic: String, completion: @escaping ([Article]) -> Void) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxArticleAgeDays, to: Date()) ?? .distantPast
        let searchTerms = searchTerms(for: topic)
        
        guard !searchTerms.isEmpty else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }
        
        let keywords = self.keywords(for: topic)
        let group = DispatchGroup()
        let lock = NSLock()
        var collected: [Article] = []
        
        for term in searchTerms {
            guard let url = searchURL(for: term, cutoffDate: cutoffDate) else { continue }
            
            group.enter()
            URLSession.shared.dataTask(with: url) { data, _, _ in
                defer { group.leave() }
                
                guard let data = data,
                      let response = try? JSONDecoder().decode(HNSearchResponse.self, from: data) else {
                    return
                }
                
                let matches: [Article] = response.hits.compactMap { hit in
                    let title = (hit.title ?? hit.storyTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { return nil }
                    
                    let text = Self.stripHTML(hit.storyText ?? hit.commentText ?? "")
                    let combined = "\(title) \(text)".lowercased()
                    let relevanceScore = self.relevanceScore(for: combined, keywords: keywords)
                    guard relevanceScore > 0 else { return nil }
                    
                    let date = Date(timeIntervalSince1970: TimeInterval(hit.createdAtI))
                    guard date >= cutoffDate else { return nil }
                    
                    return Article(
                        topic: topic,
                        title: title,
                        bullets: ["Loading summary..."],
                        time: Self.format(date: date),
                        link: hit.url ?? "https://news.ycombinator.com/item?id=\(hit.objectID)",
                        date: date,
                        snippet: text.isEmpty
                            ? "Hacker News discussion with \(hit.numComments ?? 0) comments."
                            : text,
                        source: "Hacker News",
                        engagementScore: relevanceScore + (hit.points ?? 0) + (hit.numComments ?? 0),
                        feedSource: "Hacker News"
                    )
                }
                
                lock.lock()
                collected.append(contentsOf: matches)
                lock.unlock()
            }.resume()
        }
        
        group.notify(queue: .main) {
            let deduped = self.deduplicate(collected)
            let sorted = deduped.sorted {
                if $0.engagementScore == $1.engagementScore {
                    return $0.date > $1.date
                }
                return $0.engagementScore > $1.engagementScore
            }
            
            completion(Array(sorted.prefix(8)))
        }
    }
    
    private func searchTerms(for topic: String) -> [String] {
        let primary = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let secondaryTerms = Array(keywords(for: topic).prefix(3))
        
        var seen = Set<String>()
        var result: [String] = []
        
        for term in [primary] + secondaryTerms {
            let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { continue }
            guard !seen.contains(cleaned.lowercased()) else { continue }
            seen.insert(cleaned.lowercased())
            result.append(cleaned)
        }
        
        return result
    }
    
    private func searchURL(for term: String, cutoffDate: Date) -> URL? {
        var components = URLComponents(string: "https://hn.algolia.com/api/v1/search_by_date")
        let cutoffSeconds = Int(cutoffDate.timeIntervalSince1970)
        
        components?.queryItems = [
            URLQueryItem(name: "query", value: term),
            URLQueryItem(name: "tags", value: "story"),
            URLQueryItem(name: "hitsPerPage", value: "12"),
            URLQueryItem(name: "numericFilters", value: "created_at_i>\(cutoffSeconds)")
        ]
        
        return components?.url
    }
    
    private func deduplicate(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        var result: [Article] = []
        
        for article in articles {
            let key = article.link.isEmpty ? article.title.lowercased() : article.link.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(article)
        }
        
        return result
    }
    
    private func keywords(for topic: String) -> [String] {
        let lowered = topic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch lowered {
        case "ai":
            return [
                "ai", "artificial intelligence", "openai", "gpt", "llm",
                "language model", "anthropic", "claude", "gemini",
                "machine learning", "ml", "agent", "agents", "inference"
            ]
            
        case "startups", "startup":
            return [
                "startup", "startups", "founder", "founders", "funding",
                "seed", "series a", "vc", "venture", "saas", "incubator"
            ]
            
        case "ipo":
            return [
                "ipo", "public offering", "listing", "listed", "stock market",
                "shares", "filing", "prospectus"
            ]
            
        case "food delivery":
            return [
                "food delivery", "delivery", "restaurant tech", "quick commerce",
                "instacart", "doordash", "ubereats", "swiggy", "zomato"
            ]
            
        case "war", "wars":
            return [
                "war", "conflict", "military", "defense", "missile",
                "attack", "geopolitics", "russia", "ukraine", "iran", "israel"
            ]
            
        default:
            return [lowered]
        }
    }
    
    private func relevanceScore(for text: String, keywords: [String]) -> Int {
        var score = 0
        
        for keyword in keywords {
            if text.contains(keyword) {
                score += 30
            }
        }
        
        return score
    }
    
    private static func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, h:mm a"
        return formatter.string(from: date)
    }
    
    private static func stripHTML(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
