import Foundation

enum LearningTopic: String, CaseIterable, Codable, Identifiable, Sendable {
    case business = "Business"
    case techAI = "Tech/AI"
    case geopolitics = "Geopolitics"
    case history = "History"
    case psychology = "Psychology"
    case science = "Science"
    case economics = "Economics"
    case culture = "Culture"
    
    var id: String { rawValue }
}

enum CardDifficulty: String, CaseIterable, Codable, Sendable {
    case beginner
    case intermediate
    case advanced
}

enum CardFeedbackAction: String, CaseIterable, Codable, Sendable {
    case like
    case dislike
    case tooBasic
    case tooComplex
    case save
    case quizMe
    case skip
}

enum QuizQuestionType: String, CaseIterable, Codable, Sendable {
    case recall
    case concept
    case application
}

struct SummaryCard: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let topic: LearningTopic
    let title: String
    let whyItMatters: String
    let bulletSummary: [String]
    let keyConceptTitle: String
    let keyConceptExplanation: String
    let sourceName: String
    let sourceURL: String?
    let estimatedReadingMinutes: Int
    let difficulty: CardDifficulty
    let publishedAt: Date
}

struct UserProfile: Codable, Sendable {
    var preferredTopicWeights: [String: Double]
    var savedCardIDs: [String]
    var weakTopics: [String]
    var strongTopics: [String]
    var dailyGoalMinutes: Int
    var diversityFloor: Int
    var currentStreak: Int
    var readCardIDs: Set<String>
    
    static let `default` = UserProfile(
        preferredTopicWeights: Dictionary(
            uniqueKeysWithValues: LearningTopic.allCases.map { ($0.rawValue, 1.0) }
        ),
        savedCardIDs: [],
        weakTopics: [],
        strongTopics: [],
        dailyGoalMinutes: 15,
        diversityFloor: 4,
        currentStreak: 1,
        readCardIDs: []
    )
}

struct UserInteraction: Identifiable, Codable, Sendable {
    let id: UUID
    let cardID: String
    let topic: LearningTopic
    let action: CardFeedbackAction
    let dwellTime: TimeInterval
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        cardID: String,
        topic: LearningTopic,
        action: CardFeedbackAction,
        dwellTime: TimeInterval = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.cardID = cardID
        self.topic = topic
        self.action = action
        self.dwellTime = dwellTime
        self.createdAt = createdAt
    }
}

struct QuizQuestion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let type: QuizQuestionType
    let prompt: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
    
    init(
        id: UUID = UUID(),
        type: QuizQuestionType,
        prompt: String,
        options: [String],
        correctAnswerIndex: Int,
        explanation: String
    ) {
        self.id = id
        self.type = type
        self.prompt = prompt
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
    }
}

struct Quiz: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let cardID: String
    let topic: LearningTopic
    let questions: [QuizQuestion]
    let generatedAt: Date
}

struct QuizResult: Identifiable, Codable, Sendable {
    let id: UUID
    let quizID: String
    let cardID: String
    let topic: LearningTopic
    let correctCount: Int
    let totalCount: Int
    let answeredIndices: [Int]
    let weakAreas: [String]
    let completedAt: Date
    
    init(
        id: UUID = UUID(),
        quizID: String,
        cardID: String,
        topic: LearningTopic,
        correctCount: Int,
        totalCount: Int,
        answeredIndices: [Int],
        weakAreas: [String],
        completedAt: Date = Date()
    ) {
        self.id = id
        self.quizID = quizID
        self.cardID = cardID
        self.topic = topic
        self.correctCount = correctCount
        self.totalCount = totalCount
        self.answeredIndices = answeredIndices
        self.weakAreas = weakAreas
        self.completedAt = completedAt
    }
}

struct WeeklyLearningSummary: Equatable, Sendable {
    let coveredTopics: [LearningTopic]
    let conceptsLearned: [String]
    let weakAreas: [String]
    let suggestedFocusAreas: [String]
}

struct QuizSession: Identifiable {
    let card: SummaryCard
    let quiz: Quiz
    
    var id: String { quiz.id }
}

struct LearningFollowUpQuestion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let cardID: String
    let cardTitle: String
    let topic: LearningTopic
    let prompt: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        cardID: String,
        cardTitle: String,
        topic: LearningTopic,
        prompt: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.cardID = cardID
        self.cardTitle = cardTitle
        self.topic = topic
        self.prompt = prompt
        self.createdAt = createdAt
    }
}
