import Foundation

struct OpenRouterResponse: Decodable, Sendable {
    let model: String?
    let choices: [OpenRouterChoice]
}

struct OpenRouterChoice: Decodable, Sendable {
    let message: OpenRouterMessage
}

struct OpenRouterMessage: Decodable, Sendable {
    let content: String
}

struct OpenAIResponse: Decodable, Sendable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Decodable, Sendable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Decodable, Sendable {
    let content: String
}

struct OpenAIErrorEnvelope: Decodable, Sendable {
    let error: OpenAIErrorBody
}

struct OpenAIErrorBody: Decodable, Sendable {
    let message: String
    let type: String?
    let code: String?
}

struct HNItem: Decodable, Sendable {
    let id: Int
    let type: String?
    let title: String?
    let text: String?
    let url: String?
    let time: Int
    let score: Int?
    let descendants: Int?
}

struct HNSearchResponse: Decodable, Sendable {
    let hits: [HNSearchHit]
}

struct HNSearchHit: Decodable, Sendable {
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

// Additional models for WebResearch
struct GDELTResponse: Decodable, Sendable {
    let articles: [GDELTArticle]
}

struct GDELTArticle: Decodable, Sendable {
    let title: String
    let url: String
    let domain: String
}

struct WikipediaSearchResponse: Decodable, Sendable {
    let query: WikipediaQuery
}

struct WikipediaQuery: Decodable, Sendable {
    let search: [WikipediaSearchItem]
}

struct WikipediaSearchItem: Decodable, Sendable {
    let title: String
    let snippet: String
    let pageid: Int
}
