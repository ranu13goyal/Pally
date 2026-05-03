import Combine
import Foundation

@MainActor
final class LearningQuestionManager: ObservableObject {
    
    @Published private(set) var questions: [LearningFollowUpQuestion]
    
    private let storageKey = "learning_follow_up_questions"
    
    init() {
        self.questions = Self.loadValue(forKey: storageKey, defaultValue: [])
    }
    
    func questions(for card: SummaryCard) -> [LearningFollowUpQuestion] {
        questions
            .filter { $0.cardID == card.id }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    func questionCount(for card: SummaryCard) -> Int {
        questions(for: card).count
    }
    
    func addQuestion(_ prompt: String, for card: SummaryCard) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        
        let question = LearningFollowUpQuestion(
            cardID: card.id,
            cardTitle: card.title,
            topic: card.topic,
            prompt: trimmedPrompt
        )
        
        questions.append(question)
        persist()
    }
    
    func removeQuestion(_ question: LearningFollowUpQuestion) {
        questions.removeAll { $0.id == question.id }
        persist()
    }
    
    private func persist() {
        Self.save(questions, forKey: storageKey)
    }
    
    private static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private static func loadValue<T: Decodable>(forKey key: String, defaultValue: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return defaultValue
        }
        return decoded
    }
}
