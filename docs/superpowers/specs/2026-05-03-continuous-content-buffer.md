# Continuous Content Buffer Engine Design

## Overview
This design outlines the architecture for a "Continuous Content Buffer" to ensure the Learn tab feed is never empty. Instead of relying solely on static mock data or generating massive batches of content at once, the app will maintain a local queue of unread learning cards, continuously topping it up in the background using the Groq LLM.

## Core Components

### 1. CardStorageManager (Local Persistence)
- **Responsibility:** Manage the local database of generated learning cards.
- **Storage Mechanism:** Store an array of `SummaryCard` objects in a local JSON file (e.g., `saved_cards.json` in the Documents directory) or via `UserDefaults` (if size permits).
- **Interface:**
  - `func getAllCards() -> [SummaryCard]`
  - `func saveCards(_ cards: [SummaryCard])`
  - `func getUnreadCards(excluding readIDs: Set<String>) -> [SummaryCard]`

### 2. ContentGenerationService (Background Worker)
- **Responsibility:** Monitor the buffer size and interface with `AIService` to generate new cards when the buffer runs low.
- **Logic:**
  - Define a `targetBufferSize` (e.g., 20) and a `replenishThreshold` (e.g., 10).
  - When asked to evaluate the buffer, it checks `CardStorageManager.getUnreadCards().count`.
  - If count < `replenishThreshold`, it fires off a request to `AIService` to generate a new card.
  - To ensure diversity, the service will dynamically formulate the prompt based on the user's `UserProfile` (preferred topics, weak areas).
  - The prompt will instruct the LLM to randomly select between "timely/news-based" topics and "evergreen/foundational" concepts.

### 3. LearningHomeViewModel Updates
- **Feeding the UI:** `loadDailyCards()` will no longer rely on `LearningMockData`. Instead, it will fetch the top N unread cards from `CardStorageManager`.
- **Triggering Generation:** Whenever the app becomes active, or when a user marks a card as read, the ViewModel will notify the `ContentGenerationService` to check its buffer levels.

## Data Flow
1. **App Launch:** `LearningHomeViewModel` fetches cards from `CardStorageManager`.
2. **Buffer Check:** ViewModel tells `ContentGenerationService` to check buffer health.
3. **Generation:** If buffer is low, Service calls Groq LLM via `AIService`.
4. **Persistence:** New card arrives -> appended to `CardStorageManager`.
5. **Consumption:** User marks card as read -> added to `readCardIDs` -> Card is filtered out on next UI refresh -> Buffer count drops -> Loop continues.

## Refactoring Considerations
- `LearningContentService.swift` currently handles ranking and selecting mock cards. This logic will be adapted to rank and select from the `CardStorageManager` pool instead.
- We must ensure background generation fails gracefully (e.g., if API quota is reached or network is down) without crashing the main thread.
- If the buffer is completely empty (e.g., on first install), the UI must show a loading state while the initial cards are generated.