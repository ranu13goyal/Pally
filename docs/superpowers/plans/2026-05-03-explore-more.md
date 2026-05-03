# Explore More Chat Interface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the "Explore More" chat interface and "Mark as Read" functionality for learning cards.

**Architecture:** 
1. Add `markAsRead` to `UserProfileManager` for persistence.
2. Create `ExploreMoreView` for the chat interface.
3. Update `LearningCardView` to support new actions and display read status.
4. Integrate everything into `LearningHomeView`.

**Tech Stack:** SwiftUI

---

### Task 1: Update UserProfileManager

**Files:**
- Modify: `iPal/UserProfileManager.swift`

- [ ] **Step 1: Add markAsRead method to UserProfileManager**

```swift
    func toggleSaved(_ card: SummaryCard) {
        // ... existing code ...
    }

    // Add this:
    func markAsRead(card: SummaryCard) {
        profile.readCardIDs.insert(card.id)
        handleFeedback(.like, for: card) // Also treat it as a positive signal
    }
```

- [ ] **Step 2: Commit**

```bash
git add iPal/UserProfileManager.swift
git commit -m "feat: add markAsRead persistence to UserProfileManager"
```

### Task 2: Create ExploreMoreView

**Files:**
- Create: `iPal/ExploreMoreView.swift`

- [ ] **Step 1: Create ExploreMoreView.swift**

```swift
import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @State private var messages: [String] = [] 
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Card Context Header
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
                
                // Chat Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange.opacity(0.8))
                                Text("Ask anything about \(card.title) to dive deeper.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(messages, id: \.self) { message in
                                MessageBubble(text: message)
                            }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Chat Input
                HStack(spacing: 12) {
                    TextField("Ask about \(card.title)...", text: $chatInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Explore More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        messages.append("You: \(trimmedInput)")
        chatInput = ""
        
        // Mock response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append("iPal: Let's explore \(card.title) further. (LLM integration pending)")
        }
    }
}

struct MessageBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            if text.hasPrefix("You:") {
                Spacer()
            }
            
            Text(text.replacingOccurrences(of: "You: ", with: "").replacingOccurrences(of: "iPal: ", with: ""))
                .padding(12)
                .background(text.hasPrefix("You:") ? Color.blue : Color(.systemGray5))
                .foregroundColor(text.hasPrefix("You:") ? .white : .primary)
                .cornerRadius(16)
            
            if text.hasPrefix("iPal:") {
                Spacer()
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add iPal/ExploreMoreView.swift
git commit -m "feat: add ExploreMoreView for interactive learning"
```

### Task 3: Update LearningCardView

**Files:**
- Modify: `iPal/LearningCardView.swift`

- [ ] **Step 1: Update initializer and properties**

```swift
struct LearningCardView: View {
    
    let card: SummaryCard
    let isSaved: Bool
    let isRead: Bool // New
    let questionCount: Int
    let onFeedback: (CardFeedbackAction) -> Void
    let onAskQuestion: () -> Void
    let onMarkAsRead: () -> Void // New
    let onExploreMore: () -> Void // New
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ...
            
            feedbackBar
            
            actionButtons // New
        }
        // ...
    }
}
```

- [ ] **Step 2: Add actionButtons view**

```swift
private extension LearningCardView {
    // ... (rest of methods)
    
    var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onMarkAsRead) {
                Label(isRead ? "Read" : "Mark as Read", systemImage: isRead ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isRead ? Color.green.opacity(0.15) : Color.blue.opacity(0.1))
                    .foregroundColor(isRead ? .green : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isRead)
            
            Button(action: onExploreMore) {
                Label("Explore More", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add iPal/LearningCardView.swift
git commit -m "feat: add Mark as Read and Explore More actions to LearningCardView"
```

### Task 4: Update LearningHomeView

**Files:**
- Modify: `iPal/LearningHomeView.swift`

- [ ] **Step 1: Add exploringCard state and update sheets**

```swift
    @State private var activeQuestionCard: SummaryCard?
    @State private var exploringCard: SummaryCard? // New
    @State private var searchQuery: String = ""
```

And update sheets at bottom:

```swift
        .sheet(item: $exploringCard) { card in
            ExploreMoreView(card: card)
        }
```

- [ ] **Step 2: Update LearningCardView calls**

In two places (search result and main loop):

```swift
                            LearningCardView(
                                card: card,
                                isSaved: viewModel.profileManager.isSaved(card),
                                isRead: viewModel.profileManager.profile.readCardIDs.contains(card.id),
                                questionCount: viewModel.questionManager.questionCount(for: card),
                                onFeedback: { action in
                                    viewModel.handle(action, for: card)
                                },
                                onAskQuestion: {
                                    activeQuestionCard = card
                                },
                                onMarkAsRead: {
                                    viewModel.markAsRead(card: card)
                                },
                                onExploreMore: {
                                    exploringCard = card
                                }
                            )
```

- [ ] **Step 3: Commit**

```bash
git add iPal/LearningHomeView.swift
git commit -m "feat: integrate Explore More and Mark as Read in LearningHomeView"
```
