import Foundation

struct Article: Identifiable {
    let id = UUID()
    let topic: String
    let title: String
    var bullets: [String]
    let time: String
    var link: String
    let date: Date
    let snippet: String
    let source: String
    let engagementScore: Int
    var feedSource: String = "Direct"
    
    var isPremiumSummary: Bool = false
    var isSummarizing: Bool = false
    var summaryProvider: String = "None"
}
