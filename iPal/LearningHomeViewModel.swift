import Combine
import Foundation

@MainActor
final class LearningHomeViewModel: ObservableObject {
    
    @Published var cards: [SummaryCard] = []
    @Published var weeklySummary: WeeklyLearningSummary?
    @Published var activeQuizSession: QuizSession?
    @Published var isLoading = false
    @Published var isGeneratingDeepDive = false
    @Published var deepDiveStatusMessage: String?
    
    let profileManager: UserProfileManager
    let questionManager: LearningQuestionManager
    private let contentService: LearningContentService
    private let storyManager: StoryManager
    
    init() {
        self.profileManager = UserProfileManager()
        self.questionManager = LearningQuestionManager()
        self.contentService = LearningContentService()
        self.storyManager = StoryManager()
        loadDailyCards()
    }
    
    init(
        profileManager: UserProfileManager,
        questionManager: LearningQuestionManager,
        contentService: LearningContentService,
        storyManager: StoryManager
    ) {
        self.profileManager = profileManager
        self.questionManager = questionManager
        self.contentService = contentService
        self.storyManager = storyManager
        loadDailyCards()
    }
    
    func loadDailyCards() {
        isLoading = true
        contentService.fetchDailyCards(for: profileManager.profile) { [weak self] cards in
            guard let self else { return }
            self.cards = cards
            self.weeklySummary = self.profileManager.weeklySummary(from: cards)
            self.isLoading = false
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
            loadDailyCards()
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
    func searchImmediateKnowledge(query: String) -> SummaryCard? {
        if let found = LearningMockData.cards.first(where: { $0.title.lowercased().contains(query.lowercased()) || $0.keyConceptTitle.lowercased().contains(query.lowercased()) }) {
            return found
        }
        
        return SummaryCard(
            id: UUID().uuidString,
            topic: .techAI,
            title: query,
            whyItMatters: "On-demand knowledge generation helps you learn what you need, right when you need it.",
            bulletSummary: ["Generated context for \(query)"],
            keyConceptTitle: query,
            keyConceptExplanation: "A generated explanation for \(query).",
            sourceName: "iPal AI",
            sourceURL: nil,
            estimatedReadingMinutes: 2,
            difficulty: .intermediate,
            publishedAt: Date()
        )
    }
    
    func markAsRead(card: SummaryCard) {
        profileManager.profile.readCardIDs.insert(card.id)
        profileManager.handleFeedback(.like, for: card)
    }
}
