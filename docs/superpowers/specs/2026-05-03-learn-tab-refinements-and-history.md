# Learn Tab Refinements & History Tab Design

## Overview
This design covers the next set of refinements for the Pally app, focusing on improving the "Learn" tab user experience, introducing persistent chat history, adding a new "History" tab for past conversations, and implementing a learning analytics dashboard.

## Core Features

### 1. Learn Tab Improvements
- **Read-Aware Filtering:** The `LearningHomeViewModel` will filter out cards whose IDs exist in the `UserProfile.readCardIDs` set whenever the feed is refreshed.
- **Simplified Card Feedback:** The UI for learning cards will be updated to replace the multi-button feedback bar with a simple **Thumbs Up / Thumbs Down** interface. These will continue to map to `.like` and `.dislike` feedback actions to adjust topic weights.

### 2. Persistent Chat History
- **Data Model:** A new `ChatHistoryManager` will be created to store and retrieve chat messages locally (linked by `cardID`).
- **Resuming Conversations:** When `ExploreMoreView` is initialized for a card, it will first load any existing messages from the `ChatHistoryManager`. New messages sent during the session will be saved in real-time.

### 3. "History" (or "Stories") Tab
- **Navigation:** A new tab will be added to the `TabView` in `ContentView`.
- **UI Layout:** A list-based view showing previous "Explore More" sessions. Each row will display the card title, topic, and a snippet of the last message.
- **Functionality:** Tapping a row will navigate the user to the `ExploreMoreView` for that specific card, with all previous messages loaded.

### 4. Analytics Dashboard
- **UI Trigger:** A new toolbar button (stats icon) in the `LearningHomeView` navigation bar.
- **Analytics View:** A modal sheet showing:
  - **Daily/Weekly Stats:** Count of cards marked as read.
  - **Topic Breakdown:** A list or chart showing the distribution of topics the user has engaged with.
  - **Streaks:** Current learning streak.

## Data Flow
1. **User Action (Chat):** User sends message in `ExploreMoreView` -> `AIService` provides response -> Both messages saved to `ChatHistoryManager`.
2. **User Action (Read):** User marks card as read -> Card ID added to `UserProfile.readCardIDs`.
3. **User Action (Refresh):** User triggers refresh -> ViewModel fetches cards and filters out any in `readCardIDs`.
4. **User Action (View History):** User opens History tab -> `ChatHistoryManager` lists all cards with stored conversations.

## Implementation Considerations
- **Storage:** Use `UserDefaults` or a simple JSON file for `ChatHistoryManager` initial version, as per project patterns.
- **View Refactoring:** Update `LearningCardView` to use the new simplified feedback UI.
- **Tab Bar:** Update `ContentView.swift` to include the third tab.
- **Analytics Data:** Update `UserProfileManager` to provide the necessary aggregate data for the analytics view.
