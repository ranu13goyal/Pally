# iPal - App Documentation & Architecture

## Overview
iPal is a personal-use iOS app built in Xcode/SwiftUI. It serves as an AI-native learning and news companion, designed to limit cognitive load while providing high-quality, deduplicated, and deeply researched information.

## Core Architecture
The application is built around three primary surfaces:

### 1. Feed (`HomeView`)
A real-time aggregator that pulls articles based on user-defined topics.
*   **Sources**: Google News RSS (`NewsService`) and Hacker News top stories API (`HackerNewsService`).
*   **Advanced Deduplication**: Uses Apple's `NLEmbedding` to compute sentence embeddings, Jaccard similarity indices, and token intersection. It successfully suppresses duplicate stories across sources and timelines.
*   **Summarization**: Automatically extracts body text and hits OpenRouter (Free) and OpenAI (Premium) to generate crisp 3-4 bullet summaries (`AIService`).
*   **Fallback Logic**: Explicitly filters out exact repeated fragments (headline, snippet) to ensure failed extraction still yields usable sentences without repetition.

### 2. Stories (`StoriesView`)
A living research repository that allows users to deep-dive into specific topics.
*   **State-Driven Flow**: Users provide a prompt. `WebResearchService` builds a research bundle. `StoryManager` orchestrates the UI state.
*   **AI Synthesis**: `AIService` generates a highly structured JSON response (via `gpt-4o-mini`) including a timeline, key facts, stakeholder goals, and impact assessments.
*   **Active Tracking**: Users can "Follow" stories. `StoryManager` uses `UNUserNotificationCenter` to schedule local push notifications when a story's content signature changes upon background/manual refresh.

### 3. Learn (`LearningHomeView`)
A spaced-repetition and daily-curation engine designed for a 15-minute daily learning habit.
*   **Current State**: UI and logic are fully built. Content is currently mocked via `LearningMockData`.
*   **Features**: Serves daily `SummaryCard` items, tracks user engagement, and generates dynamic quizzes based on the content (Recall, Concept, Application).
*   **Live Integration Stubs**: `LearningContentService` already contains prompt logic (`buildDeepDiveStoryPrompt`, `buildQuizPrompt`) ready to be hooked into the live `AIService` pipeline.

## State Management & Design Patterns
*   **UI Framework**: SwiftUI with MVVM patterns.
*   **Data Flow**: Heavy reliance on `@StateObject` and `@Published` properties (`TopicManager`, `StoryManager`) to reactively update the UI upon asynchronous AI payload returns.
*   **Topic Normalization**: Centralized topic deduplication that lowercases, strips special characters, and collapses whitespace via regex (`normalizedTopicKey`).

## Known Technical Debt & Next Implementation Priorities

1.  **Wire the Learn Tab to Live Content**
    *   Replace `LearningMockData` with live network fetches.
    *   Connect `LearningContentService` AI generation paths to the live `AIService`.

2.  **Repair Stories Quality & Sourcing**
    *   Tweak system prompts in `AIService.swift` to force better source grounding.
    *   Ensure the AI uses actual source citations and avoids generic filler when extracting the JSON payload.

3.  **Extraction Fallbacks**
    *   Improve the HTML parsing/regex in `ContentFetcher` to grab reliable body text from a wider variety of publisher structures.

4.  **Security**
    *   Move hardcoded `openRouterKey` and `openAIKey` out of `AIService.swift` and into a secure environment or build configuration.

## Build Instructions
The project compiles cleanly from the command line:

```bash
xcodebuild -project iPal.xcodeproj -scheme iPal -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/iPalDerivedData build
```