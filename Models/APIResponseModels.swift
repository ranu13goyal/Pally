import Foundation

struct OpenRouterResponse: Decodable {
    let model: String?
    let choices: [OpenRouterChoice]
}

struct OpenRouterChoice: Decodable {
    let message: OpenRouterMessage
}

struct OpenRouterMessage: Decodable {
    let content: String
}

struct OpenAIResponse: Decodable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Decodable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Decodable {
    let content: String
}

struct OpenAIErrorEnvelope: Decodable {
    let error: OpenAIErrorBody
}

struct OpenAIErrorBody: Decodable {
    let message: String
    let type: String?
    let code: String?
}

struct HNItem: Decodable {
    let id: Int
    let type: String?
    let title: String?
    let text: String?
    let url: String?
    let time: Int
    let score: Int?
    let descendants: Int?
}

struct HNSearchResponse: Decodable {
    let hits: [HNSearchHit]
}

struct HNSearchHit: Decodable {
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
