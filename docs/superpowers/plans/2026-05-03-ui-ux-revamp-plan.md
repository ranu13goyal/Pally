# UI/UX Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the UI/UX of Pally to match a "Classic Print" (Newspaper) and "Kindle" aesthetic using UI/UX Pro Max principles.

**Architecture:** We will implement custom colors and fonts in SwiftUI. `LearningCardView` will be updated to a newspaper style with serif fonts and dividers. `ExploreMoreView` will become a Kindle-like reading experience with custom background colors and typography. `HistoryView` and `AnalyticsView` will be polished to match.

**Tech Stack:** SwiftUI

---

### Task 1: Setup Custom Colors and Typography Helpers

**Files:**
- Create: `iPal/Theme.swift`

- [ ] **Step 1: Create Theme File**
Create a central place for theme-related colors and font extensions to ensure consistency.

```swift
// iPal/Theme.swift
import SwiftUI

enum Theme {
    static let paperBackground = Color(red: 253/255, green: 251/255, blue: 247/255) // #FDFBF7
    static let inkText = Color(red: 44/255, green: 44/255, blue: 44/255) // #2C2C2C
    
    // Fallbacks for dark mode
    static let darkPaperBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let darkInkText = Color(red: 235/255, green: 235/255, blue: 235/255)
}

struct PaperBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content.background(colorScheme == .dark ? Theme.darkPaperBackground : Theme.paperBackground)
    }
}

struct InkTextModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content.foregroundColor(colorScheme == .dark ? Theme.darkInkText : Theme.inkText)
    }
}

extension View {
    func paperBackground() -> some View {
        modifier(PaperBackgroundModifier())
    }
    
    func inkText() -> some View {
        modifier(InkTextModifier())
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add iPal/Theme.swift
git commit -m "feat: add Theme file for paper and ink colors"
```

### Task 2: Revamp LearningCardView (Newspaper Style)

**Files:**
- Modify: `iPal/LearningCardView.swift`

- [ ] **Step 1: Update Typography and Layout**
Change fonts to serif, remove background blob, add divider, and simplify buttons. Ensure 44pt touch targets.

```swift
// iPal/LearningCardView.swift
import SwiftUI

struct LearningCardView: View {
    let card: SummaryCard
    let isSaved: Bool
    let isRead: Bool
    let questionCount: Int
    let onFeedback: (CardFeedbackAction) -> Void
    let onGetFeedback: () -> CardFeedbackAction?
    let onMarkAsRead: () -> Void
    let onExploreMore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.topic.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .fontDesign(.sans)
                        .foregroundColor(.secondary)
                    
                    Text(card.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.serif)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: { onFeedback(.save) }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundColor(isSaved ? .primary : .secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            insightBlock(title: "Why this matters", content: card.whyItMatters)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Key takeaways")
                    .font(.headline)
                    .fontDesign(.serif)
                
                ForEach(card.bulletSummary, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .fontDesign(.serif)
                        Text(bullet)
                            .fontDesign(.serif)
                            .lineSpacing(4)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            insightBlock(
                title: card.keyConceptTitle,
                content: card.keyConceptExplanation
            )
            
            HStack {
                Text("\(card.estimatedReadingMinutes) MIN READ")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .fontDesign(.sans)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let sourceURL = card.sourceURL, let url = URL(string: sourceURL) {
                    Link(card.sourceName.uppercased(), destination: url)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .fontDesign(.sans)
                        .foregroundColor(.secondary)
                } else {
                    Text(card.sourceName.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .fontDesign(.sans)
                        .foregroundColor(.secondary)
                }
            }
            
            feedbackBar
            
            actionButtons
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }
}

private extension LearningCardView {
    func insightBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .fontDesign(.serif)
            Text(content)
                .font(.subheadline)
                .fontDesign(.serif)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
    
    var feedbackBar: some View {
        HStack(spacing: 16) {
            let currentFeedback = onGetFeedback()
            
            quickAction(
                icon: "hand.thumbsup",
                action: .like,
                isActive: currentFeedback == .like
            )
            
            quickAction(
                icon: "hand.thumbsdown",
                action: .dislike,
                isActive: currentFeedback == .dislike
            )
        }
        .padding(.top, 8)
    }
    
    func quickAction(
        icon: String,
        action: CardFeedbackAction,
        isActive: Bool = false
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onFeedback(action)
            }
        } label: {
            Image(systemName: isActive ? "\(icon).fill" : icon)
                .font(.system(size: 18))
                .foregroundColor(isActive ? .primary : .secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onMarkAsRead()
                }
            } label: {
                Text(isRead ? "Read" : "Mark as Read")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(.sans)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRead ? Color.secondary.opacity(0.3) : Color.primary, lineWidth: 1)
                    )
                    .foregroundColor(isRead ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .disabled(isRead)
            
            Button(action: onExploreMore) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Explore More")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.sans)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}
```

- [ ] **Step 2: Update LearningHomeView Background**
Remove the grouped background in `LearningHomeView.swift`.

```swift
// In iPal/LearningHomeView.swift
// Find: .background(Color(.systemGroupedBackground))
// Replace with: .background(Color(.systemBackground))

// Use sed for precision:
// sed -i '' 's/\.background(Color(.systemGroupedBackground))/\.background(Color(.systemBackground))/g' iPal/LearningHomeView.swift
```

- [ ] **Step 3: Commit**
```bash
git add iPal/LearningCardView.swift iPal/LearningHomeView.swift
git commit -m "style: revamp LearningCardView to Newspaper aesthetic"
```

### Task 3: Revamp ExploreMoreView (Kindle Reader)

**Files:**
- Modify: `iPal/ExploreMoreView.swift`

- [ ] **Step 1: Update ExploreMoreView**
Apply Kindle aesthetic: paper background, ink text, generous line spacing, serif fonts for reading, and minimal user bubbles.

```swift
// iPal/ExploreMoreView.swift
import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @ObservedObject var historyManager = ChatHistoryManager.shared
    @State private var isTyping = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    private let aiService = AIService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Card Context Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(card.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.serif)
                        .inkText()
                    
                    Text(card.keyConceptTitle)
                        .font(.subheadline)
                        .fontDesign(.serif)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Chat Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        let messages = historyManager.messages(for: card.id)
                        
                        if messages.isEmpty {
                            VStack(spacing: 16) {
                                Text("Ask anything about \(card.title) to dive deeper.")
                                    .font(.body)
                                    .fontDesign(.serif)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                            }
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }
                            
                            if isTyping {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .fontDesign(.serif)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .fontDesign(.serif)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
                
                Divider()
                
                // Chat Input
                HStack(spacing: 12) {
                    TextField("Ask a question...", text: $chatInput)
                        .fontDesign(.serif)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: sendMessage) {
                        if isTyping {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 44, height: 44)
                                .background(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.3) : Color.primary)
                                .foregroundColor(Color(.systemBackground))
                                .clipShape(Circle())
                        }
                    }
                    .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                }
                .padding(16)
            }
            .paperBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontDesign(.sans)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        errorMessage = nil
        historyManager.saveMessage(trimmedInput, isUser: true, for: card.id)
        
        chatInput = ""
        isTyping = true
        
        let messagesToSend = historyManager.messages(for: card.id)
        let aiMessages = messagesToSend.map { $0.isUser ? "You: \($0.text)" : "iPal: \($0.text)" }
        
        aiService.generateChatResponse(card: card, messages: aiMessages) { response, success in
            isTyping = false
            if success {
                historyManager.saveMessage(response, isUser: false, for: card.id)
            } else {
                errorMessage = response
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.body)
                    .fontDesign(.serif)
                    .lineSpacing(6)
                    .padding(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
            } else {
                Text(message.text)
                    .font(.body)
                    .fontDesign(.serif)
                    .lineSpacing(8)
                    .inkText()
                    .padding(.horizontal, 24)
                Spacer(minLength: 40)
            }
        }
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add iPal/ExploreMoreView.swift
git commit -m "style: revamp ExploreMoreView to Kindle aesthetic"
```

### Task 4: Polish HistoryView and AnalyticsView

**Files:**
- Modify: `iPal/HistoryView.swift`
- Modify: `iPal/AnalyticsView.swift`

- [ ] **Step 1: Update HistoryRow Typography**
Align `HistoryRow` with the new serif aesthetic and spacing.

```swift
// In iPal/HistoryView.swift (replace HistoryRow struct)

struct HistoryRow: View {
    let card: SummaryCard
    let lastMessage: ChatMessage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.topic.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .fontDesign(.sans)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let timestamp = lastMessage?.timestamp {
                    Text(timestamp, style: .date)
                        .font(.caption2)
                        .fontDesign(.sans)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(card.title)
                .font(.headline)
                .fontDesign(.serif)
                .lineLimit(2)
            
            if let lastText = lastMessage?.text {
                Text(lastText)
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(4)
            } else {
                Text("Start exploring...")
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 12)
    }
}
```

- [ ] **Step 2: Update AnalyticsView Typography**
Make typography consistent in `AnalyticsView.swift`.

```swift
// In iPal/AnalyticsView.swift, for StatBox and TopicRow, add `.fontDesign(.sans)` to fonts to keep them clean as metadata, or serif if preferred.
// Let's add .fontDesign(.sans) to the Analytics elements for a clean dashboard look.
// Specifically, in StatBox:
/*
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.serif) // Use serif for the big number
            Text(title)
                .font(.caption)
                .fontDesign(.sans)
                .foregroundColor(.secondary)
        }
...
*/

// Using sed for quick targeted updates in AnalyticsView.swift is tricky.
// We'll instruct the subagent to update the fonts manually in StatBox, TopicRow, and DailyTrendChart to use .fontDesign(.sans) for labels and .fontDesign(.serif) for main numbers/headers.
```
*Agent note: The subagent will replace the specific structs `StatBox` and `TopicRow` in `AnalyticsView.swift` to add `.fontDesign()` modifiers.*

- [ ] **Step 3: Commit**
```bash
git add iPal/HistoryView.swift iPal/AnalyticsView.swift
git commit -m "style: polish History and Analytics typography"
```
