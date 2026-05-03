import Combine
import Foundation

@MainActor
final class UserProfileManager: ObservableObject {
    
    @Published var profile: UserProfile
    @Published private(set) var interactions: [UserInteraction]
    @Published private(set) var quizResults: [QuizResult]
    
    private let profileKey = "learning_user_profile"
    private let interactionsKey = "learning_user_interactions"
    private let quizResultsKey = "learning_quiz_results"
    
    init() {
        self.profile = Self.loadValue(forKey: profileKey, defaultValue: .default)
        self.interactions = Self.loadValue(forKey: interactionsKey, defaultValue: [])
        self.quizResults = Self.loadValue(forKey: quizResultsKey, defaultValue: [])
    }
    
    func isSaved(_ card: SummaryCard) -> Bool {
        profile.savedCardIDs.contains(card.id)
    }
    
    func handleFeedback(_ action: CardFeedbackAction, for card: SummaryCard, dwellTime: TimeInterval = 0) {
        let interaction = UserInteraction(cardID: card.id, topic: card.topic, action: action, dwellTime: dwellTime)
        interactions.insert(interaction, at: 0)
        
        // Track visual feedback state
        if action == .like || action == .dislike {
            profile.feedbackHistory[card.id] = action
        }
        
        switch action {
        case .like:
            adjustWeight(for: card.topic, delta: 0.45)
        case .dislike:
            adjustWeight(for: card.topic, delta: -0.5)
        case .tooBasic:
            adjustWeight(for: card.topic, delta: -0.1)
            moveTopic(card.topic.rawValue, toStrongTopics: true)
        case .tooComplex:
            adjustWeight(for: card.topic, delta: 0.05)
            moveTopic(card.topic.rawValue, toStrongTopics: false)
        case .save:
            toggleSaved(card)
        case .quizMe:
            adjustWeight(for: card.topic, delta: 0.15)
        case .skip:
            adjustWeight(for: card.topic, delta: -0.05)
        }
        
        persistAll()
    }
    
    func toggleSaved(_ card: SummaryCard) {
        if let index = profile.savedCardIDs.firstIndex(of: card.id) {
            profile.savedCardIDs.remove(at: index)
        } else {
            profile.savedCardIDs.insert(card.id, at: 0)
        }
        persistProfile()
    }
    
    func markAsRead(card: SummaryCard) {
        profile.readCardIDs.insert(card.id)
        profile.readCardHistory[card.id] = Date()
        handleFeedback(.like, for: card)
    }
    
    func recordQuizResult(_ result: QuizResult) {
        quizResults.insert(result, at: 0)
        
        let accuracy = Double(result.correctCount) / Double(max(result.totalCount, 1))
        if accuracy >= 0.67 {
            moveTopic(result.topic.rawValue, toStrongTopics: true)
            adjustWeight(for: result.topic, delta: 0.2)
        } else {
            moveTopic(result.topic.rawValue, toStrongTopics: false)
            adjustWeight(for: result.topic, delta: 0.08)
        }
        
        persistAll()
    }
    
    func preferenceScore(for topic: LearningTopic) -> Double {
        profile.preferredTopicWeights[topic.rawValue] ?? 1.0
    }
    
    func weeklySummary(from cards: [SummaryCard]) -> WeeklyLearningSummary {
        let recentInteractions = interactions.filter {
            Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 99 < 7
        }
        
        let coveredTopics = Array(
            Set(recentInteractions.map(\.topic).isEmpty ? cards.map(\.topic) : recentInteractions.map(\.topic))
        ).sorted { $0.rawValue < $1.rawValue }
        
        let conceptsLearned = Array(cards.prefix(4)).map(\.keyConceptTitle)
        let weakAreas = Array(profile.weakTopics.prefix(3))
        
        let suggestedFocusAreas: [String]
        if weakAreas.isEmpty {
            suggestedFocusAreas = coveredTopics.prefix(3).map {
                "Go one level deeper into \($0.rawValue)"
            }
        } else {
            suggestedFocusAreas = weakAreas.map {
                "Revisit \($0) with simpler cards and more quizzes"
            }
        }
        
        return WeeklyLearningSummary(
            coveredTopics: coveredTopics,
            conceptsLearned: conceptsLearned,
            weakAreas: weakAreas,
            suggestedFocusAreas: suggestedFocusAreas
        )
    }
}

private extension UserProfileManager {
    
    func adjustWeight(for topic: LearningTopic, delta: Double) {
        let current = profile.preferredTopicWeights[topic.rawValue] ?? 1.0
        profile.preferredTopicWeights[topic.rawValue] = min(max(current + delta, 0.25), 3.0)
    }
    
    func moveTopic(_ value: String, toStrongTopics: Bool) {
        var strongTopics = profile.strongTopics
        var weakTopics = profile.weakTopics
        
        strongTopics.removeAll { $0 == value }
        weakTopics.removeAll { $0 == value }
        
        if toStrongTopics {
            strongTopics.insert(value, at: 0)
        } else {
            weakTopics.insert(value, at: 0)
        }
        
        profile.strongTopics = strongTopics
        profile.weakTopics = weakTopics
    }
    
    func persistAll() {
        persistProfile()
        persistInteractions()
        persistQuizResults()
    }
    
    func persistProfile() {
        Self.save(profile, forKey: profileKey)
    }
    
    func persistInteractions() {
        Self.save(interactions, forKey: interactionsKey)
    }
    
    func persistQuizResults() {
        Self.save(quizResults, forKey: quizResultsKey)
    }
    
    static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    static func loadValue<T: Decodable>(forKey key: String, defaultValue: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return defaultValue
        }
        return decoded
    }
}
