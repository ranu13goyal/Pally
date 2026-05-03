# Learn Tab & Mind Map Feature Design

## Overview
This design outlines the replacement of the existing "Story" tab with a new "Learn" tab, while preserving the "Feed" tab. The Learn tab will serve as an interactive learning environment where users can consume topic-based cards, explore subjects deeply through a chat interface, and visualize their growing knowledge via a dynamic Mind Map.

## Core Components

### 1. The Learn Tab (Navigation & Layout)
- **Position:** Replaces the "Story" tab as the second item in the main `TabView`.
- **Structure:** Features a top toggle or segmented control allowing the user to switch between two main views:
  - **Feed View:** The primary card consumption interface.
  - **Mind Map View:** The visual knowledge graph.
- **Topic Management:** Users can add specific topics of interest directly from the Learn tab. When refreshed, the feed populates with relevant information cards based on these topics.

### 2. The Learning Feed
- **Layout:** An infinite scroll feed where cards for all subscribed topics are mixed together in a continuous stream.
- **Card Actions:** 
  - **Mark as Read:** Acknowledges consumption and potentially triggers knowledge extraction for the Mind Map.
  - **Explore More:** Initiates a deep dive into the card's subject matter.

### 3. "Explore More" Experience (Repurposed Story Concept)
- **Trigger:** Tapping "Explore More" on a learning card.
- **Interface:** Opens a "Story-like" view. This acts as a hybrid interface containing detailed information about the topic and an interactive chat session.
- **Functionality:** Users can converse with an LLM about the specific card's context, ask questions, and clarify concepts (e.g., asking for an explanation, common uses, and significance of the "Monte Carlo Theorem").

### 4. Mind Map / Knowledge Graph
- **Location:** Accessed via the dedicated toggle/sub-tab on the Learn tab.
- **Visualization:** A full-screen interactive word cloud or node-based mind map representing the user's acquired knowledge.
- **Data Architecture (LLM Entity Extraction):**
  - As users read cards and engage with the "Explore More" chat, the content is processed by an LLM in the cloud.
  - The LLM extracts key "Entities" (topics, concepts) and "Relationships" (how they connect).
  - This structured data builds a rich, intelligent knowledge graph that updates dynamically as the user learns.

## Data Flow
1. **Input:** User adds a topic -> Feed refreshes with relevant topic cards.
2. **Consumption:** User reads a card -> "Mark as Read" triggers LLM extraction of entities/relationships in the background.
3. **Exploration:** User clicks "Explore More" -> Enters chat interface -> Conversation context is additionally processed by the LLM for deeper entity extraction.
4. **Visualization:** Extracted entities and relationships update the local knowledge graph state, which renders in the Mind Map view.

## Refactoring Considerations
- `ContentView.swift`: Update `TabView` to replace `StoriesView` with the new hybrid `LearningHomeView`.
- Repurpose existing `Story.swift` and `StoryManager.swift` assets to serve the new "Explore More" chat interface if applicable, or deprecate them cleanly.
- Enhance `LearningModels.swift` to support dynamic topic addition and Mind Map node/edge structures.

## Phased Implementation
Based on user feedback, development will be split into phases:
- **Phase 1 (Current Focus):** Build the core Learn tab feed, dynamic topic management, the "Explore More" hybrid chat interface (repurposing the Story concept), and the "Mark as Read" functionality.
- **Phase 2 (Future Work):** Implement the LLM Entity Extraction architecture and the Mind Map visualization view.