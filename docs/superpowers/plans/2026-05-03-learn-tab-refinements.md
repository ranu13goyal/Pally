# Learn Tab Refinements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement UI refinements for the Learn tab, persistent chat history, a new History tab, and a learning analytics dashboard.

**Architecture:** We will create a `ChatHistoryManager` for persistent storage of messages. We will update `LearningHomeViewModel` to filter read cards on refresh. `LearningCardView` will be simplified to thumbs up/down. A new `HistoryView` and `AnalyticsView` will be introduced.

**Tech Stack:** SwiftUI, Foundation, UserDefaults

---

### Task 1: Persistent Chat History Management

**Files:**
- Create: `iPal/ChatHistoryManager.swift`

- [ ] **Step 1: Implement ChatHistoryManager**
Create a service that stores chat messages by `cardID`.

```swift
// iPal/ChatHistoryManager.swift
import Foundation

struct ChatMessage: Codable, Hashable, Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

@MainActor
final class ChatHistoryManager: ObservableObject {
    @Published private(set) var history: [String: [ChatMessage]] = [:]
    private let storageKey = "ipal_chat_history"
    
    static let shared = ChatHistoryManager()
    
    private init() {
        loadHistory()
    }
    
    func messages(for cardID: String) -> [ChatMessage] {
        history[cardID] ?? []
    }
    
    func saveMessage(_ text: String, isUser: Bool, for cardID: String) {
        let message = ChatMessage(text: text, isUser: isUser)
        var current = history[cardID] ?? []
        current.append(message)
        history[cardID] = current
        persist()
    }
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: [ChatMessage]].self, from: data) {
            history = decoded
        }
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add iPal/ChatHistoryManager.swift
git commit -m "feat: add ChatHistoryManager for persistent messaging"
```

### Task 2: Integrate History into ExploreMoreView

**Files:**
- Modify: `iPal/ExploreMoreView.swift`

- [ ] **Step 1: Update ExploreMoreView to load/save history**
Modify the view to use `ChatHistoryManager.shared`.

```swift
// In iPal/ExploreMoreView.swift

// Update messages state to use ChatMessage
// @State private var messages: [ChatMessage] = []

// Inside .onAppear or init
// messages = ChatHistoryManager.shared.messages(for: card.id)

// Inside sendMessage()
// ChatHistoryManager.shared.saveMessage(trimmedInput, isUser: true, for: card.id)
// ... in completion
// ChatHistoryManager.shared.saveMessage(response, isUser: false, for: card.id)
```

- [ ] **Step 2: Commit**
```bash
git add iPal/ExploreMoreView.swift
git commit -m "feat: make Explore More conversations persistent"
```

### Task 3: Simplify Feedback UI and Implement Card Filtering

**Files:**
- Modify: `iPal/LearningCardView.swift`
- Modify: `iPal/LearningHomeViewModel.swift`

- [ ] **Step 1: Update LearningCardView UI**
Replace the multi-button bar with Thumbs Up/Down.

- [ ] **Step 2: Update LearningHomeViewModel filtering**
Modify `loadDailyCards` to filter out `readCardIDs`.

- [ ] **Step 3: Commit**
```bash
git add iPal/LearningCardView.swift iPal/LearningHomeViewModel.swift
git commit -m "feat: simplify feedback UI and filter read cards on refresh"
```

### Task 4: Create History Tab

**Files:**
- Create: `iPal/HistoryView.swift`
- Modify: `iPal/ContentView.swift`

- [ ] **Step 1: Implement HistoryView**
A list of cards with previous conversations.

- [ ] **Step 2: Add to ContentView TabView**
Add the new tab.

- [ ] **Step 3: Commit**
```bash
git add iPal/HistoryView.swift iPal/ContentView.swift
git commit -m "feat: add History tab for previous conversations"
```

### Task 5: Analytics Dashboard

**Files:**
- Create: `iPal/AnalyticsView.swift`
- Modify: `iPal/LearningHomeView.swift`

- [ ] **Step 1: Implement AnalyticsView**
Display read counts, topics, and streaks.

- [ ] **Step 2: Add Stats button to LearningHomeView**
Add the toolbar icon to trigger the dashboard.

- [ ] **Step 3: Commit**
```bash
git add iPal/AnalyticsView.swift iPal/LearningHomeView.swift
git commit -m "feat: add learning analytics dashboard"
```
