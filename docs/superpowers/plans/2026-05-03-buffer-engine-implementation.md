# Continuous Content Buffer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a background content engine that maintains a buffer of unread learning cards using the Groq LLM and local persistence.

**Architecture:** We will create `CardStorageManager` for local file persistence, `ContentGenerationService` for background replenishing logic, and update `LearningHomeViewModel` to orchestrate these components.

**Tech Stack:** SwiftUI, Foundation, FileSystem

---

### Task 1: CardStorageManager (Persistence Layer)

**Files:**
- Create: `iPal/CardStorageManager.swift`

- [ ] **Step 1: Implement CardStorageManager**
Create a singleton class to manage saving and loading cards from a local JSON file.

```swift
// iPal/CardStorageManager.swift
import Foundation

final class CardStorageManager {
    static let shared = CardStorageManager()
    private let fileName = "buffered_cards.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    private init() {}
    
    func getAllCards() -> [SummaryCard] {
        guard let data = try? Data(contentsOf: fileURL),
              let cards = try? JSONDecoder().decode([SummaryCard].self, from: data) else {
            return []
        }
        return cards
    }
    
    func saveCards(_ cards: [SummaryCard]) {
        if let data = try? JSONEncoder().encode(cards) {
            try? data.write(to: fileURL)
        }
    }
    
    func appendCard(_ card: SummaryCard) {
        var current = getAllCards()
        current.append(card)
        saveCards(current)
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add iPal/CardStorageManager.swift
git commit -m "feat: add CardStorageManager for local card persistence"
```

### Task 2: ContentGenerationService (Background Logic)

**Files:**
- Create: `iPal/ContentGenerationService.swift`

- [ ] **Step 1: Implement ContentGenerationService**
Logic to check buffer and call LLM.

```swift
// iPal/ContentGenerationService.swift
import Foundation

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
        let prompt = "Generate a \(mode) related to one of these interests: \(profile.preferredTopicWeights.keys.joined(separator: ", ")). Ensure it is diverse and unique."
        
        aiService.generateLearningCard(query: prompt) { [weak self] card, success in
            guard let self else { return }
            self.isGenerating = false
            
            if let card = card, success {
                CardStorageManager.shared.appendCard(card)
                // Recursive call to fill buffer up to threshold
                self.replenishIfNeeded(profile: profile)
            }
        }
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add iPal/ContentGenerationService.swift
git commit -m "feat: add ContentGenerationService for background replenishing"
```

### Task 3: Integrate with LearningHomeViewModel

**Files:**
- Modify: `iPal/LearningHomeViewModel.swift`
- Modify: `iPal/LearningContentService.swift`

- [ ] **Step 1: Update LearningContentService to use Storage**
Modify `fetchDailyCards` to pull from the buffer.

```swift
// iPal/LearningContentService.swift
func fetchDailyCards(for profile: UserProfile, completion: @escaping ([SummaryCard]) -> Void) {
    let allCards = CardStorageManager.shared.getAllCards()
    let unread = allCards.filter { !profile.readCardIDs.contains($0.id) }
    
    // Fallback to mock data if buffer is empty
    let sourcePool = unread.isEmpty ? LearningMockData.cards : unread
    
    let ranked = rankedCards(from: sourcePool, profile: profile)
    let selected = diversifiedSelection(from: ranked, diversityFloor: profile.diversityFloor, targetCount: 10)
    completion(selected)
}
```

- [ ] **Step 2: Update ViewModel to trigger replenish**
Initialize the service and call it on load/mark as read.

```swift
// iPal/LearningHomeViewModel.swift
private let generationService = ContentGenerationService()

// In loadDailyCards and markAsRead
generationService.replenishIfNeeded(profile: profileManager.profile)
```

- [ ] **Step 3: Commit**
```bash
git add iPal/LearningHomeViewModel.swift iPal/LearningContentService.swift
git commit -m "feat: integrate buffer engine into the Learn feed"
```
