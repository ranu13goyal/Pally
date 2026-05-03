import SwiftUI
import NaturalLanguage

struct HomeView: View {
    
    @State private var articles: [Article] = []
    @State private var selectedTopic: String?
    @StateObject var topicManager = TopicManager()
    
    let newsService = NewsService()
    let hackerNewsService = HackerNewsService()
    let aiService = AIService()
    let contentFetcher = ContentFetcher()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good morning, Ranu 👋")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Here’s what matters for you today")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: TopicsView(topicManager: topicManager)) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    
                    topicFilterPills
                    
                    VStack(spacing: 16) {
                        if articles.isEmpty {
                            ProgressView("Loading...")
                                .padding()
                        } else if filteredArticleIndices().isEmpty {
                            Text("No stories for this topic yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                        
                        ForEach(filteredArticleIndices(), id: \.self) { index in
                            NavigationLink(destination: ArticleDetailView(article: $articles[index])) {
                                ArticleCard(article: articles[index])
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            fetchAllTopics()
        }
        .onReceive(topicManager.$topics) { _ in
            fetchAllTopics()
        }
    }
}

extension HomeView {
    
    static let semanticEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
    static let semanticDedupWindow: TimeInterval = 7 * 24 * 60 * 60
    static let semanticStopWords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "from", "into",
        "after", "about", "over", "under", "amid", "near", "live",
        "update", "updates", "says", "say", "new", "latest", "report",
        "reports", "analysis", "opinion", "today", "week", "month",
        "year", "news", "breaking"
    ]
    
    var topicFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                topicPill(title: "All", isSelected: selectedTopic == nil) {
                    selectedTopic = nil
                }
                
                ForEach(availableTopicsForFilters(), id: \.self) { topic in
                    topicPill(title: topic, isSelected: selectedTopic == topic) {
                        selectedTopic = topic
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    func fetchAllTopics() {
        let topics = TopicManager.deduplicatedTopics(from: topicManager.topics)
        guard !topics.isEmpty else {
            self.selectedTopic = nil
            self.articles = []
            return
        }
        
        syncSelectedTopic(with: topics)
        
        var allArticles: [Article] = []
        let group = DispatchGroup()
        
        for topic in topics {
            group.enter()
            newsService.fetchNews(for: topic) { fetchedArticles in
                allArticles.append(contentsOf: fetchedArticles)
                group.leave()
            }
            
            group.enter()
            hackerNewsService.fetchStories(for: topic) { fetchedArticles in
                allArticles.append(contentsOf: fetchedArticles)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let ranked = allArticles.sorted {
                let lhs = combinedRankingScore(for: $0)
                let rhs = combinedRankingScore(for: $1)
                return lhs > rhs
            }
            self.articles = deduplicatedFeed(from: ranked)
            generateFreeSummaries()
        }
    }
    
    func generateFreeSummaries() {
        for index in articles.indices.prefix(12) {
            let articleID = articles[index].id
            
            if articles[index].isPremiumSummary || articles[index].isSummarizing {
                continue
            }
            
            articles[index].isSummarizing = true
            
            contentFetcher.fetchSummaryInput(
                from: articles[index].link,
                title: articles[index].title,
                snippet: articles[index].snippet,
                maxLength: 3500
            ) { result in
                aiService.generateFreeSummary(input: result.input) { bullets, provider, success in
                    DispatchQueue.main.async {
                        guard let liveIndex = articles.firstIndex(where: { $0.id == articleID }) else { return }
                        articles[liveIndex].bullets = bullets
                        articles[liveIndex].isSummarizing = false
                        articles[liveIndex].isPremiumSummary = false
                        articles[liveIndex].summaryProvider = result.usedFallback ? "Limited article text" : provider
                        articles = deduplicatedFeed(from: articles)
                    }
                }
            }
        }
    }

    func deduplicatedFeed(from input: [Article]) -> [Article] {
        balanceSources(in: deduplicate(input))
    }
    
    func filteredArticleIndices() -> [Int] {
        guard let selectedTopic else {
            return Array(articles.indices)
        }
        
        return articles.indices.filter { articles[$0].topic == selectedTopic }
    }
    
    func availableTopicsForFilters() -> [String] {
        let configuredTopics = TopicManager.deduplicatedTopics(from: topicManager.topics)
        let articleTopics = articles.map(\.topic)
        
        var seen = Set<String>()
        var result: [String] = []
        
        for topic in configuredTopics + articleTopics {
            guard seen.insert(topic).inserted else { continue }
            result.append(topic)
        }
        
        return result
    }
    
    func syncSelectedTopic(with availableTopics: [String]) {
        guard let selectedTopic else { return }
        guard availableTopics.contains(selectedTopic) else {
            self.selectedTopic = nil
            return
        }
    }
    
    @ViewBuilder
    func topicPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    func combinedRankingScore(for article: Article) -> Int {
        let hoursAgo = Int(Date().timeIntervalSince(article.date) / 3600)
        let recencyScore = max(0, 100 - hoursAgo)
        
        let sourceBoost: Int
        switch article.feedSource {
        case "Hacker News":
            sourceBoost = 25
        case "Google News":
            sourceBoost = 10
        default:
            sourceBoost = 0
        }
        
        return recencyScore + article.engagementScore + sourceBoost
    }
    
    func deduplicate(_ input: [Article]) -> [Article] {
        var result: [Article] = []
        var seenTitleKeys = Set<String>()
        var seenURLKeys = Set<String>()
        
        for article in input {
            let titleKey = normalizedTitleKey(for: article.title)
            let urlKey = normalizedURLKey(for: article.link)
            
            if !urlKey.isEmpty && seenURLKeys.contains(urlKey) {
                continue
            }
            
            if seenTitleKeys.contains(titleKey) {
                continue
            }
            
            if result.contains(where: { areNearDuplicate(article, $0) }) {
                continue
            }
            
            if result.contains(where: { areSemanticDuplicate(article, $0) }) {
                continue
            }
            
            seenTitleKeys.insert(titleKey)
            if !urlKey.isEmpty {
                seenURLKeys.insert(urlKey)
            }
            result.append(article)
        }
        
        return result
    }
    
    func normalizedTitleKey(for title: String) -> String {
        let strippedSuffix = removePublicationSuffix(from: title)
        
        return strippedSuffix
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\b(live|updates|update|exclusive)\\b", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func removePublicationSuffix(from title: String) -> String {
        let separators = [" | ", " - "]
        
        for separator in separators {
            let parts = title.components(separatedBy: separator)
            guard parts.count > 1 else { continue }
            
            let suffix = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let loweredSuffix = suffix.lowercased()
            let publicationHints = [
                "news", "times", "post", "express", "journal", "chronicle",
                "techcrunch", "reuters", "bloomberg", "guardian", "cnn",
                "bbc", "wire", "today", "standard", "herald", "tribune"
            ]
            
            if publicationHints.contains(where: { loweredSuffix.contains($0) }) {
                return parts.dropLast().joined(separator: separator)
            }
        }
        
        return title
    }
    
    func normalizedURLKey(for urlString: String) -> String {
        guard var components = URLComponents(string: urlString),
              let host = components.host?.lowercased() else {
            return ""
        }
        
        let strippedHost = host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        let blockedQueryItems = [
            "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
            "fbclid", "gclid", "mc_cid", "mc_eid", "cmpid", "ocid", "guccounter"
        ]
        
        components.scheme = nil
        components.host = strippedHost
        components.fragment = nil
        components.queryItems = components.queryItems?.filter { item in
            !blockedQueryItems.contains(item.name.lowercased())
        }
        
        let path = components.path
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        
        let query = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        return "\(strippedHost)\(path)\(query)"
    }
    
    func areNearDuplicate(_ lhs: Article, _ rhs: Article) -> Bool {
        let lhsTitle = normalizedTitleKey(for: lhs.title)
        let rhsTitle = normalizedTitleKey(for: rhs.title)
        
        if lhsTitle == rhsTitle {
            return true
        }
        
        let lhsTokens = significantTokens(from: lhsTitle)
        let rhsTokens = significantTokens(from: rhsTitle)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return false }
        
        let overlap = lhsTokens.intersection(rhsTokens).count
        let smallestSetCount = min(lhsTokens.count, rhsTokens.count)
        let coverage = Double(overlap) / Double(smallestSetCount)
        
        if coverage >= 0.8 {
            return true
        }
        
        let lhsSnippet = normalizedTitleKey(for: lhs.snippet)
        let rhsSnippet = normalizedTitleKey(for: rhs.snippet)
        if !lhsSnippet.isEmpty && lhsSnippet == rhsSnippet {
            return true
        }
        
        return false
    }
    
    func areSemanticDuplicate(_ lhs: Article, _ rhs: Article) -> Bool {
        let dateGap = abs(lhs.date.timeIntervalSince(rhs.date))
        guard dateGap <= Self.semanticDedupWindow else { return false }
        
        let lhsText = semanticComparisonText(for: lhs)
        let rhsText = semanticComparisonText(for: rhs)
        guard lhsText.count > 24, rhsText.count > 24 else { return false }
        
        let lhsTokens = semanticTokens(from: lhsText)
        let rhsTokens = semanticTokens(from: rhsText)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return false }
        
        let overlap = lhsTokens.intersection(rhsTokens).count
        let smallestSetCount = min(lhsTokens.count, rhsTokens.count)
        let coverage = Double(overlap) / Double(smallestSetCount)
        let unionCount = lhsTokens.union(rhsTokens).count
        let jaccard = unionCount == 0 ? 0 : Double(overlap) / Double(unionCount)
        
        guard overlap >= 3 || coverage >= 0.45 else {
            return false
        }
        
        if let embedding = Self.semanticEmbedding {
            let distance = Double(embedding.distance(between: lhsText, and: rhsText))
            
            if distance <= 0.82 {
                return true
            }
            
            if distance <= 0.93 && (overlap >= 4 || coverage >= 0.55 || jaccard >= 0.40) {
                return true
            }
            
            if distance <= 1.0 && coverage >= 0.72 {
                return true
            }
        }
        
        return overlap >= 6 && coverage >= 0.75
    }
    
    func significantTokens(from text: String) -> Set<String> {
        let stopWords: Set<String> = [
            "the", "and", "for", "with", "that", "this", "from", "into",
            "after", "about", "over", "under", "amid", "near", "live",
            "update", "updates", "says", "say", "new", "latest"
        ]
        
        return Set(
            text
                .split(separator: " ")
                .map(String.init)
                .filter { token in
                    token.count > 2 && !stopWords.contains(token)
                }
        )
    }
    
    func semanticComparisonText(for article: Article) -> String {
        let cleanedTitle = cleanSemanticText(removePublicationSuffix(from: article.title))
        let cleanedSnippet = cleanSemanticText(article.snippet)
        let cleanedBullets = article.bullets
            .filter(isMeaningfulSummaryBullet)
            .map(cleanSemanticText)
            .filter { !$0.isEmpty }
        
        var parts = [cleanedTitle]
        
        if !cleanedBullets.isEmpty {
            parts.append(cleanedBullets.joined(separator: ". "))
        }
        
        if !cleanedSnippet.isEmpty {
            parts.append(cleanedSnippet)
        }
        
        return parts
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }
    
    func semanticTokens(from text: String) -> Set<String> {
        Set(
            cleanSemanticText(text)
                .split(separator: " ")
                .map(String.init)
                .filter { token in
                    if token.allSatisfy(\.isNumber) {
                        return true
                    }
                    return token.count > 2 && !Self.semanticStopWords.contains(token)
                }
        )
    }
    
    func cleanSemanticText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "&amp;", with: " and ")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func isMeaningfulSummaryBullet(_ bullet: String) -> Bool {
        let cleaned = bullet.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }
        guard !cleaned.localizedCaseInsensitiveContains("loading summary") else { return false }
        guard !cleaned.localizedCaseInsensitiveContains("detailed summary unavailable") else { return false }
        guard !cleaned.localizedCaseInsensitiveContains("open the full article for context") else { return false }
        return true
    }
    
    func balanceSources(in articles: [Article]) -> [Article] {
        var googleNews = articles.filter { $0.feedSource == "Google News" }
        var hackerNews = articles.filter { $0.feedSource == "Hacker News" }
        var other = articles.filter { !["Google News", "Hacker News"].contains($0.feedSource) }
        var balanced: [Article] = []
        
        while !googleNews.isEmpty || !hackerNews.isEmpty || !other.isEmpty {
            if let next = hackerNews.first {
                balanced.append(next)
                hackerNews.removeFirst()
            }
            
            if let next = googleNews.first {
                balanced.append(next)
                googleNews.removeFirst()
            }
            
            if let next = other.first {
                balanced.append(next)
                other.removeFirst()
            }
            
            if hackerNews.isEmpty && other.isEmpty {
                balanced.append(contentsOf: googleNews)
                googleNews.removeAll()
            } else if googleNews.isEmpty && other.isEmpty {
                balanced.append(contentsOf: hackerNews)
                hackerNews.removeAll()
            } else if googleNews.isEmpty && hackerNews.isEmpty {
                balanced.append(contentsOf: other)
                other.removeAll()
            }
        }
        
        return balanced
    }
}
