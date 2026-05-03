import Foundation

final class LearningContentService {
    
    func fetchDailyCards(
        for profile: UserProfile,
        completion: @escaping ([SummaryCard]) -> Void
    ) {
        let allCards = CardStorageManager.shared.getAllCards()
        let unread = allCards.filter { !profile.readCardIDs.contains($0.id) }
        
        // Fallback to mock data if buffer is empty
        let sourcePool = unread.isEmpty ? LearningMockData.cards : unread
        
        let ranked = rankedCards(from: sourcePool, profile: profile)
        let selected = diversifiedSelection(from: ranked, diversityFloor: profile.diversityFloor, targetCount: 10)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            completion(selected)
        }
    }
    
    func quiz(for card: SummaryCard) -> Quiz {
        if let quiz = LearningMockData.quizzes[card.id] {
            return quiz
        }
        
        return Quiz(
            id: "quiz-\(card.id)",
            cardID: card.id,
            topic: card.topic,
            questions: [
                QuizQuestion(
                    type: .recall,
                    prompt: "What is the main idea of this card?",
                    options: [
                        card.bulletSummary.first ?? card.whyItMatters,
                        "It has no clear thesis",
                        "It is mostly about entertainment",
                        "It is only a historical anecdote"
                    ],
                    correctAnswerIndex: 0,
                    explanation: "The first summary point usually captures the core takeaway."
                ),
                QuizQuestion(
                    type: .concept,
                    prompt: "What does \(card.keyConceptTitle.lowercased()) refer to here?",
                    options: [
                        card.keyConceptExplanation,
                        "A branding slogan",
                        "A political campaign name",
                        "A finance-only metric"
                    ],
                    correctAnswerIndex: 0,
                    explanation: "The key concept section is meant to simplify the core idea."
                ),
                QuizQuestion(
                    type: .application,
                    prompt: "Where would this insight be most useful?",
                    options: [
                        "When trying to reason about real-world implications",
                        "Only in fiction writing",
                        "Only in school exams",
                        "It has no practical use"
                    ],
                    correctAnswerIndex: 0,
                    explanation: "Application questions check whether the user can carry the idea into a real context."
                )
            ],
            generatedAt: Date()
        )
    }
    
    func buildSummarizationPrompt(for articleText: String, topic: LearningTopic) -> String {
        """
        You are writing a mobile learning card for a curious professional.
        
        Convert the article into JSON with:
        - title
        - why_it_matters
        - key_points (4 to 5 bullets)
        - key_concept_title
        - key_concept_explanation
        
        Rules:
        - Keep it concise, useful, and clear
        - Avoid jargon unless you explain it simply
        - Write for a 15-minute daily learning habit
        - Topic: \(topic.rawValue)
        
        Article:
        \(articleText)
        """
    }
    
    func buildQuizPrompt(for card: SummaryCard) -> String {
        """
        Generate exactly 3 multiple-choice questions for this summary card.
        
        Requirements:
        - 1 recall question
        - 1 concept-understanding question
        - 1 application question
        - Each question must have 4 options, one correct answer, and a short explanation
        - Return JSON
        
        Card Title: \(card.title)
        Why it matters: \(card.whyItMatters)
        Key points: \(card.bulletSummary.joined(separator: " | "))
        Key concept: \(card.keyConceptTitle) - \(card.keyConceptExplanation)
        """
    }
    
    func openAIRequestExample(for card: SummaryCard) -> [String: Any] {
        [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You create educational quiz JSON for a learning app."],
                ["role": "user", "content": buildQuizPrompt(for: card)]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3
        ]
    }
    
    func buildDeepDiveStoryPrompt(for card: SummaryCard, questions: [LearningFollowUpQuestion]) -> String {
        let numberedQuestions = questions.enumerated().map { index, question in
            "\(index + 1). \(question.prompt)"
        }.joined(separator: "\n")
        
        return """
        Build a deeper story explainer for this learning topic.
        
        Topic:
        \(card.title)
        
        Learning card context:
        - Topic category: \(card.topic.rawValue)
        - Why this matters: \(card.whyItMatters)
        - Key takeaways: \(card.bulletSummary.joined(separator: " | "))
        - Key concept: \(card.keyConceptTitle) - \(card.keyConceptExplanation)
        
        The user has follow-up questions they want answered in the deeper story:
        \(numberedQuestions)
        
        Instructions:
        - Synthesize the topic into a richer explainer, not a FAQ dump.
        - Directly answer the user's questions inside the story structure.
        - Add nuance, examples, implications, and what to watch next.
        - Keep the writing clear enough for an interested non-expert.
        - Cite and rely on strong, verifiable sources.
        """
    }
}

private extension LearningContentService {
    
    func rankedCards(from cards: [SummaryCard], profile: UserProfile) -> [SummaryCard] {
        cards.sorted { lhs, rhs in
            score(for: lhs, profile: profile) > score(for: rhs, profile: profile)
        }
    }
    
    func score(for card: SummaryCard, profile: UserProfile) -> Double {
        let preference = profile.preferredTopicWeights[card.topic.rawValue] ?? 1.0
        let difficultyAdjustment: Double
        
        switch card.difficulty {
        case .beginner:
            difficultyAdjustment = profile.weakTopics.contains(card.topic.rawValue) ? 0.45 : 0.1
        case .intermediate:
            difficultyAdjustment = 0.25
        case .advanced:
            difficultyAdjustment = profile.strongTopics.contains(card.topic.rawValue) ? 0.4 : -0.1
        }
        
        let recencyBonus = max(0, 36_000 - abs(card.publishedAt.timeIntervalSinceNow)) / 36_000
        let savedBoost = profile.savedCardIDs.contains(card.id) ? 0.6 : 0
        return preference + difficultyAdjustment + recencyBonus + savedBoost
    }
    
    func diversifiedSelection(
        from cards: [SummaryCard],
        diversityFloor: Int,
        targetCount: Int
    ) -> [SummaryCard] {
        var selected: [SummaryCard] = []
        var seenTopics = Set<LearningTopic>()
        
        for card in cards where selected.count < targetCount {
            if seenTopics.count < diversityFloor {
                guard !seenTopics.contains(card.topic) else { continue }
            }
            
            selected.append(card)
            seenTopics.insert(card.topic)
        }
        
        if selected.count < targetCount {
            for card in cards where !selected.contains(card) {
                selected.append(card)
                if selected.count == targetCount {
                    break
                }
            }
        }
        
        return selected
    }
}
