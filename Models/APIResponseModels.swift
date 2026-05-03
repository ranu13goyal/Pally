@preconcurrency import Foundation

struct OpenRouterResponse: Sendable {
    let model: String?
    let choices: [OpenRouterChoice]
}
extension OpenRouterResponse: Decodable {}

struct OpenRouterChoice: Sendable {
    let message: OpenRouterMessage
}
extension OpenRouterChoice: Decodable {}

struct OpenRouterMessage: Sendable {
    let content: String
}
extension OpenRouterMessage: Decodable {}

struct OpenAIResponse: Sendable {
    let choices: [OpenAIChoice]
}
extension OpenAIResponse: Decodable {}

struct OpenAIChoice: Sendable {
    let message: OpenAIMessage
}
extension OpenAIChoice: Decodable {}

struct OpenAIMessage: Sendable {
    let content: String
}
extension OpenAIMessage: Decodable {}

struct OpenAIErrorEnvelope: Sendable {
    let error: OpenAIErrorBody
}
extension OpenAIErrorEnvelope: Decodable {}

struct OpenAIErrorBody: Sendable {
    let message: String
    let type: String?
    let code: String?
}
extension OpenAIErrorBody: Decodable {}

struct HNItem: Sendable {
    let id: Int
    let type: String?
    let title: String?
    let text: String?
    let url: String?
    let time: Int
    let score: Int?
    let descendants: Int?
}
extension HNItem: Decodable {}

struct HNSearchResponse: Sendable {
    let hits: [HNSearchHit]
}
extension HNSearchResponse: Decodable {}

struct HNSearchHit: Sendable {
    let objectID: String
    let title: String?
    let storyTitle: String?
    let url: String?
    let storyText: String?
    let commentText: String?
    let createdAtI: Int
    let points: Int?
    let numComments: Int?
    
    enum CodingKeys: String, CodingKey {
        case objectID
        case title
        case storyTitle = "story_title"
        case url
        case storyText = "story_text"
        case commentText = "comment_text"
        case createdAtI = "created_at_i"
        case points
        case numComments = "num_comments"
    }
}
extension HNSearchHit: Decodable {}

// Additional models for WebResearch
struct GDELTResponse: Sendable {
    let articles: [GDELTArticle]
}
extension GDELTResponse: Decodable {}

struct GDELTArticle: Sendable {
    let title: String
    let url: String
    let domain: String
}
extension GDELTArticle: Decodable {}

struct WikipediaSearchResponse: Sendable {
    let query: WikipediaQuery
}
extension WikipediaSearchResponse: Decodable {}

struct WikipediaQuery: Sendable {
    let search: [WikipediaSearchItem]
}
extension WikipediaQuery: Decodable {}

struct WikipediaSearchItem: Sendable {
    let title: String
    let snippet: String
    let pageid: Int
}
extension WikipediaSearchItem: Decodable {}
