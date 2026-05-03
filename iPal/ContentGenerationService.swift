import Foundation
import Combine

@MainActor
final class ContentGenerationService: ObservableObject {
    private let aiService = AIService()
    private let targetBufferSize = 25
    private let replenishThreshold = 12
    @Published var isGenerating = false
    
    func replenishIfNeeded(profile: UserProfile) {
        guard !isGenerating else { return }
        
        let allCards = CardStorageManager.shared.getAllCards()
        let unreadCount = allCards.filter { !profile.readCardIDs.contains($0.id) }.count
        
        if unreadCount < replenishThreshold {
            generateNewCard(profile: profile)
        }
    }
    
    private func generateNewCard(profile: UserProfile) {
        isGenerating = true
        
        // Randomly pick between Trending and Evergreen
        let mode = Bool.random() ? "trending latest development" : "evergreen foundational concept"
        let interests = profile.preferredTopicWeights.keys.joined(separator: ", ")
        let prompt = "Generate a \(mode) related to one of these interests: \(interests). Ensure it is diverse and unique. Return valid JSON only."
        
        aiService.generateLearningCard(query: prompt) { [weak self] card, success in
            guard let self else { return }
            
            Task { @MainActor in
                self.isGenerating = false
                if let card = card, success {
                    CardStorageManager.shared.appendCard(card)
                    // Continue replenishing until threshold is met
                    self.replenishIfNeeded(profile: profile)
                }
            }
        }
    }
}
