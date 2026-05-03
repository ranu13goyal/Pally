# Learn Tab Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Story tab with a new Learn tab featuring an infinite scroll feed of learning cards, dynamic topic management, and an "Explore More" hybrid chat interface.

**Architecture:** We will modify `ContentView` to update the tab structure. We will enhance `LearningModels` to support dynamic, user-defined topics (moving beyond a static enum) and track read status. `LearningHomeView` will be updated to manage these topics and display the feed. We will create a new `ExploreMoreView` to serve as the deep-dive chat interface, accessed via a new button on `LearningCardView`.

**Tech Stack:** SwiftUI, Foundation

---

### Task 1: Update Main Tab Navigation

**Files:**
- Modify: `iPal/ContentView.swift`

- [ ] **Step 1: Remove Stories tab and reposition Learn tab**
Update `ContentView` to only have two tabs: Feed and Learn.

```swift
// iPal/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }
            
            LearningHomeView()
                .tabItem {
                    Label("Learn", systemImage: "brain.head.profile")
                }
        }
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add iPal/ContentView.swift
git commit -m "feat: replace Story tab with Learn tab in ContentView"
```

### Task 2: Track Read Status in UserProfile

**Files:**
- Modify: `iPal/LearningModels.swift`

- [ ] **Step 1: Add Read Status to UserProfile**
The feed algorithm is already handling topic diversification and like/dislike weight adjustments. We just need to track which cards the user has read.

```swift
// In iPal/LearningModels.swift, update the UserProfile struct directly

struct UserProfile: Codable {
    var preferredTopicWeights: [String: Double]
    var savedCardIDs: [String]
    var weakTopics: [String]
    var strongTopics: [String]
    var dailyGoalMinutes: Int
    var diversityFloor: Int
    var currentStreak: Int
    var readCardIDs: Set<String> // NEW: Track read cards
    
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
```

- [ ] **Step 2: Commit**
```bash
git add iPal/LearningModels.swift
git commit -m "feat: track read cards in UserProfile"
```

### Task 3: Build "Immediate Knowledge" Search

**Files:**
- Modify: `iPal/LearningHomeView.swift`
- Modify: `iPal/LearningHomeViewModel.swift`

- [ ] **Step 1: Add search logic to ViewModel**
Update `LearningHomeViewModel` to handle a specific search query to immediately pull up knowledge (a mock implementation for now).

```swift
// Add to iPal/LearningHomeViewModel.swift
extension LearningHomeViewModel {
    func searchImmediateKnowledge(query: String) -> SummaryCard? {
        // In a real app, this might call the LLM to generate a card on the fly.
        // For now, we search mock data or return a placeholder card.
        if let found = LearningMockData.cards.first(where: { $0.title.lowercased().contains(query.lowercased()) || $0.keyConceptTitle.lowercased().contains(query.lowercased()) }) {
            return found
        }
        
        // Fallback mock generated card
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
        // Also adjust weight positively as a signal of consumption
        profileManager.handleFeedback(.like, for: card)
    }
}
```

- [ ] **Step 2: Update `LearningHomeView` with Search Bar**
Add a search field at the top of the feed for on-demand knowledge.

```swift
// In iPal/LearningHomeView.swift, inside the ScrollView before ForEach(viewModel.cards)
// Add new state variables: 
// @State private var searchQuery: String = ""
// @State private var searchedCard: SummaryCard?

/*
VStack(spacing: 16) {
    HStack {
        TextField("Search for immediate knowledge (e.g. Monte Carlo)", text: $searchQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        
        Button("Learn") {
            if !searchQuery.isEmpty {
                searchedCard = viewModel.searchImmediateKnowledge(query: searchQuery)
                searchQuery = ""
            }
        }
    }
    .padding(.horizontal)
    
    if let card = searchedCard {
        VStack(alignment: .leading) {
            Text("Search Result")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            LearningCardView(...) // Use the existing init signature
        }
    }
    
    // existing cards loop
}
*/
```

- [ ] **Step 3: Commit**
```bash
git add iPal/LearningHomeView.swift iPal/LearningHomeViewModel.swift
git commit -m "feat: add immediate knowledge search UI"
```

### Task 4: Create Explore More Chat Interface

**Files:**
- Create: `iPal/ExploreMoreView.swift`
- Modify: `iPal/LearningCardView.swift`

- [ ] **Step 1: Create `ExploreMoreView`**
Create a new view that shows the card details and a chat interface.

```swift
// iPal/ExploreMoreView.swift
import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @State private var messages: [String] = [] // Placeholder for chat messages
    
    var body: some View {
        VStack {
            // Context Header
            VStack(alignment: .leading, spacing: 8) {
                Text(card.title)
                    .font(.headline)
                Text(card.keyConceptTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            
            // Chat History
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            
            // Input Area
            HStack {
                TextField("Ask about \(card.title)...", text: $chatInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    if !chatInput.isEmpty {
                        messages.append("You: \(chatInput)")
                        messages.append("iPal: Let's explore \(card.title) further. (LLM integration pending)")
                        chatInput = ""
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Explore More")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

- [ ] **Step 2: Add buttons to `LearningCardView`**
Add "Mark as Read" and "Explore More" buttons to the card.

```swift
// In iPal/LearningCardView.swift, add action closures
// let onMarkAsRead: () -> Void
// let onExploreMore: () -> Void

// Add buttons to the bottom of the card layout
/*
HStack {
    Button("Mark as Read") {
        onMarkAsRead()
    }
    .buttonStyle(.bordered)
    
    Spacer()
    
    Button("Explore More") {
        onExploreMore()
    }
    .buttonStyle(.borderedProminent)
}
*/
```

- [ ] **Step 3: Connect actions in `LearningHomeView`**
Update the `LearningCardView` initialization in `LearningHomeView` to handle the new actions and present `ExploreMoreView` (e.g., using a NavigationLink or sheet).

```swift
// In iPal/LearningHomeView.swift
// @State private var exploringCard: SummaryCard?

/*
.sheet(item: $exploringCard) { card in
    NavigationView {
        ExploreMoreView(card: card)
    }
}
*/
```

- [ ] **Step 4: Commit**
```bash
git add iPal/ExploreMoreView.swift iPal/LearningCardView.swift iPal/LearningHomeView.swift
git commit -m "feat: add Explore More view and card actions"
```