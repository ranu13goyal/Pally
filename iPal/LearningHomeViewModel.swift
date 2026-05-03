import Combine
import Foundation
import SwiftUI

@MainActor
final class LearningHomeViewModel: ObservableObject {
    
    @Published var cards: [SummaryCard] = []
    @Published var weeklySummary: WeeklyLearningSummary?
    @Published var activeQuizSession: QuizSession?
    @Published var isLoading = false
    @Published var isGeneratingDeepDive = false
    @Published var deepDiveStatusMessage: String?
    @Published var searchedCard: SummaryCard?
    
    private var cancellables = Set<AnyCancellable>()
    
    let profileManager: UserProfileManager
    let questionManager: LearningQuestionManager
    private let contentService: LearningContentService
    private let aiService: AIService
    private let storyManager: StoryManager
    private let generationService = ContentGenerationService()
    
    init() {
        self.profileManager = UserProfileManager()
        self.questionManager = LearningQuestionManager()
        self.contentService = LearningContentService()
        self.aiService = AIService()
        self.storyManager = StoryManager()
        
        profileManager.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        loadDailyCards()
    }
    
    init(
        profileManager: UserProfileManager,
        questionManager: LearningQuestionManager,
        contentService: LearningContentService,
        aiService: AIService,
        storyManager: StoryManager
    ) {
        self.profileManager = profileManager
        self.questionManager = questionManager
        self.contentService = contentService
        self.aiService = aiService
        self.storyManager = storyManager
        
        profileManager.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        loadDailyCards()
    }
    
    func loadDailyCards() {
        isLoading = true
        contentService.fetchDailyCards(for: profileManager.profile) { [weak self] cards in
            guard let self else { return }
            // Filter out already read cards
            self.cards = cards.filter { !self.profileManager.profile.readCardIDs.contains($0.id) }
            self.weeklySummary = self.profileManager.weeklySummary(from: cards)
            self.isLoading = false
            self.generationService.replenishIfNeeded(profile: self.profileManager.profile)
        }
    }
    
    func handle(_ action: CardFeedbackAction, for card: SummaryCard) {
        switch action {
        case .save:
            profileManager.toggleSaved(card)
        case .quizMe:
            startQuiz(for: card)
            profileManager.handleFeedback(.quizMe, for: card)
        default:
            profileManager.handleFeedback(action, for: card)
        }
    }
    
    func startQuiz(for card: SummaryCard) {
        let quiz = contentService.quiz(for: card)
        activeQuizSession = QuizSession(card: card, quiz: quiz)
    }
    
    func completeQuiz(session: QuizSession, selectedAnswers: [Int]) {
        let correctAnswers = zip(session.quiz.questions.indices, selectedAnswers).filter { index, answer in
            session.quiz.questions[index].correctAnswerIndex == answer
        }
        
        let weakAreas = zip(session.quiz.questions, selectedAnswers).compactMap { question, answer in
            question.correctAnswerIndex == answer ? nil : question.type.rawValue.capitalized
        }
        
        let result = QuizResult(
            quizID: session.quiz.id,
            cardID: session.card.id,
            topic: session.card.topic,
            correctCount: correctAnswers.count,
            totalCount: session.quiz.questions.count,
            answeredIndices: selectedAnswers,
            weakAreas: weakAreas
        )
        
        profileManager.recordQuizResult(result)
        weeklySummary = profileManager.weeklySummary(from: cards)
        activeQuizSession = nil
        loadDailyCards()
    }
    
    func generateDeepDive(for card: SummaryCard) {
        let questions = questionManager.questions(for: card)
        guard !questions.isEmpty else {
            deepDiveStatusMessage = "Add at least one follow-up question first."
            return
        }
        
        let prompt = contentService.buildDeepDiveStoryPrompt(for: card, questions: questions)
        isGeneratingDeepDive = true
        
        storyManager.createStory(prompt: prompt) { [weak self] story in
            guard let self else { return }
            self.isGeneratingDeepDive = false
            
            if let story {
                self.deepDiveStatusMessage = "Deep story added to Stories for \(story.topic)."
            } else {
                self.deepDiveStatusMessage = "Could not generate a deeper story right now."
            }
        }
    }
    
    func clearDeepDiveStatus() {
        deepDiveStatusMessage = nil
    }
}

extension LearningHomeViewModel {
    func searchImmediateKnowledge(query: String, completion: @escaping (SummaryCard?) -> Void) {
        if let found = LearningMockData.cards.first(where: { $0.title.lowercased().contains(query.lowercased()) || $0.keyConceptTitle.lowercased().contains(query.lowercased()) }) {
            completion(found)
            return
        }
        
        isLoading = true
        aiService.generateLearningCard(query: query) { card, _ in
            self.isLoading = false
            if let generatedCard = card {
                CardStorageManager.shared.appendCard(generatedCard)
            }
            completion(card)
        }
    }
    
    func markAsRead(card: SummaryCard) {
        profileManager.markAsRead(card: card)
        generationService.replenishIfNeeded(profile: profileManager.profile)
        
        // We no longer remove it immediately from the feed.
        // Tapping Refresh will filter them out.
    }
}
