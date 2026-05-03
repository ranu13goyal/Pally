import Foundation

class NewsService {
    
    private let maxArticleAgeDays = 15
    private let googleNewsURLDecoder = GoogleNewsURLDecoder()
    
    func parseDate(_ rawDate: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let formats = [
            "E, d MMM yyyy HH:mm:ss Z",
            "EE, d MMM yyyy HH:mm:ss Z",
            "E, dd MMM yyyy HH:mm:ss Z",
            "EE, dd MMM yyyy HH:mm:ss Z"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: rawDate) {
                return date
            }
        }
        
        return nil
    }
    
    func formatDate(_ rawDate: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        
        if let date = formatter.date(from: rawDate) {
            let output = DateFormatter()
            output.dateFormat = "d MMM, h:mm a"
            return output.string(from: date)
        }
        
        return "Recently"
    }
    
    func fetchNews(for topic: String, completion: @escaping ([Article]) -> Void) {
        
        let query = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
        let urlString = "https://news.google.com/rss/search?q=\(query)"
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxArticleAgeDays, to: Date()) ?? .distantPast
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let parser = RSSParser()
            let items = parser.parse(data: data)
            
            let baseArticles: [Article] = items.compactMap { item in
                guard let parsedDate = self.parseDate(item.pubDate),
                      parsedDate >= cutoffDate else {
                    return nil
                }
                
                let formattedTime = self.formatDate(item.pubDate)
                
                return Article(
                    topic: topic,
                    title: item.title,
                    bullets: ["Loading summary..."],
                    time: formattedTime,
                    link: item.link,
                    date: parsedDate,
                    snippet: item.description,
                    source: item.source.isEmpty ? "Google News" : item.source,
                    engagementScore: 0,
                    feedSource: "Google News"
                )
            }
            
            guard !baseArticles.isEmpty else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let group = DispatchGroup()
            var resolvedArticles: [Article] = []
            let lock = NSLock()
            
            for article in baseArticles {
                group.enter()
                self.googleNewsURLDecoder.decodeIfNeeded(article.link) { resolvedURL in
                    var resolvedArticle = article
                    resolvedArticle.link = resolvedURL
                    lock.lock()
                    resolvedArticles.append(resolvedArticle)
                    lock.unlock()
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let sortedArticles = resolvedArticles.sorted { $0.date > $1.date }
                completion(sortedArticles)
            }
        }.resume()
    }
}
