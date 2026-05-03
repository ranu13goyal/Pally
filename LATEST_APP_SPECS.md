# Pally - Latest App Specifications & Architecture

## Overview
Pally is an AI-native learning companion for iOS. It transforms news and topics of interest into structured "Learning Cards," provides an immersive reading environment for deep dives, and tracks user progress through a personalized analytics dashboard.

## Core Features

### 1. The Learn Feed (Newspaper Aesthetic)
*   **Visual Design**: A high-contrast, content-first layout inspired by classic print media.
*   **Typography**: Serif fonts for headlines and summaries to enhance readability; Sans-Serif metadata (topics, read time) for clear interface contrast.
*   **Infinite Buffer**: Powered by a background "Continuous Content Buffer" that maintains ~25 unread cards at all times.
*   **Feedback System**: Simplified "Thumbs Up / Thumbs Down" interaction to train the recommendation algorithm.
*   **Immediate Knowledge Search**: Users can search for any specific topic (e.g., "Game Theory") to immediately generate a new learning card via the LLM.

### 2. Explore More (Kindle Aesthetic)
*   **Reading Experience**: A warm, paper-toned background (`#FDFBF7`) with deep charcoal text designed for long-form reading without eye strain.
*   **AI Chat**: Real-time conversational interface with "iPal" (AI Tutor). iPal understands the specific context of the card being explored.
*   **Persistent Threads**: Every chat is automatically saved. Users can leave a conversation and resume it later from exactly where they left off.

### 3. Stories Tab (History & Archive)
*   **Conversational Threads**: A dedicated tab listing all past "Explore More" sessions.
*   **Searchable History**: A native search bar allows users to filter their previous deep dives by card title or topic category.
*   **Resume Capability**: Tapping any story instantly re-opens the "Kindle" chat interface with full history loaded.

### 4. Learning Analytics
*   **Dashboard**: Accessed via a chart icon in the Learn tab header.
*   **Metrics**: Tracks total cards read, current learning streak, and saved content.
*   **Learning Trend**: A 7-day bar chart visualizing cards consumed per day to encourage habit-building.
*   **Topic Engagement**: A breakdown of the user's engagement scores across different knowledge categories.

## Technical Architecture

### AI & Networking
*   **Primary LLM**: Groq Cloud (`llama-3.3-70b-versatile`).
*   **Robustness**: `AIService` includes a generic request performer with exponential backoff retries (3 attempts) for transient network failures.
*   **Security**: API keys are managed locally via `Keys.plist` (git-ignored) and loaded at runtime.
*   **Deduplication**: Generation logic uses recent card titles as negative constraints in prompts to ensure unique content.

### Data Management
*   **Persistence**:
    *   `CardStorageManager`: Handles local JSON storage for generated learning cards.
    *   `ChatHistoryManager`: Manages persistent storage of chat messages linked to card IDs.
    *   `UserProfileManager`: Tracks topic weights, read IDs, and learning statistics using `UserDefaults`.
*   **Reactive UI**: ViewModels (`LearningHomeViewModel`) observe manager state changes via Combine publishers to ensure instant UI updates.

## Build Requirements
*   **Environment**: Xcode 15+ / iOS 17.0+
*   **Configuration**: Requires a valid `GroqKey` in `iPal/Keys.plist`.
*   **Language Mode**: Swift 6 (Strict Concurrency compliant).
