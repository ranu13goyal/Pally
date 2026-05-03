import SwiftUI
import Foundation
import Combine   // ✅ IMPORTANT

class TopicManager: ObservableObject {
    
    @Published var topics: [String] = []
    
    private let key = "saved_topics"
    
    init() {
        loadTopics()
    }
    
    func loadTopics() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            let normalized = Self.deduplicatedTopics(from: saved)
            topics = normalized.isEmpty ? Self.defaultTopics : normalized
        } else {
            topics = Self.defaultTopics
        }
        
        saveTopics()
    }
    
    func saveTopics() {
        UserDefaults.standard.set(topics, forKey: key)
    }
    
    func addTopic(_ topic: String) {
        guard let canonicalTopic = Self.canonicalTopic(from: topic) else { return }
        guard !topics.contains(canonicalTopic) else { return }
        
        topics.append(canonicalTopic)
        topics = Self.deduplicatedTopics(from: topics)
        saveTopics()
    }
    
    func removeTopic(at offsets: IndexSet) {
        topics.remove(atOffsets: offsets)
        saveTopics()
    }
}

extension TopicManager {
    
    static let defaultTopics = ["Zomato", "AI"]
    
    static func canonicalTopic(from rawTopic: String) -> String? {
        let collapsed = rawTopic
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        guard !collapsed.isEmpty else { return nil }
        
        let normalized = collapsed
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s&+-]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalized.isEmpty else { return nil }
        
        let aliases: [String: String] = [
            "ai": "AI",
            "artificial intelligence": "AI",
            "ml": "AI",
            "machine learning": "AI",
            "startup": "Startup",
            "startups": "Startup",
            "ipo": "IPO",
            "ipos": "IPO",
            "war": "War",
            "wars": "War",
            "food delivery": "Food Delivery",
            "food deliveries": "Food Delivery",
            "food-delivery": "Food Delivery",
            "food delivery apps": "Food Delivery",
            "food delivery app": "Food Delivery",
            "quick commerce": "Food Delivery"
        ]
        
        if let alias = aliases[normalized] {
            return alias
        }
        
        if normalized.contains("food delivery") {
            return "Food Delivery"
        }
        
        let uppercaseAcronyms: Set<String> = ["ai", "ipo", "saas", "vc", "ml", "llm", "api", "uk", "us"]
        
        return normalized
            .split(separator: " ")
            .map { component in
                let token = String(component)
                if uppercaseAcronyms.contains(token) {
                    return token.uppercased()
                }
                return token.prefix(1).uppercased() + token.dropFirst()
            }
            .joined(separator: " ")
    }
    
    static func deduplicatedTopics(from rawTopics: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        
        for topic in rawTopics {
            guard let canonical = canonicalTopic(from: topic) else { continue }
            let key = canonical.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(canonical)
        }
        
        return result
    }
}
