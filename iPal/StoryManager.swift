import Foundation
import Combine
import UserNotifications

@MainActor
final class StoryManager: ObservableObject {
    
    @Published private(set) var stories: [Story] = []
    @Published var isCreatingStory = false
    @Published var loadingStoryIDs = Set<UUID>()
    @Published var errorMessage: String?
    
    private let storageKey = "saved_stories"
    private let aiService = AIService()
    private let webResearchService = WebResearchService()
    
    init() {
        loadStories()
    }
    
    func createStory(prompt: String, completion: ((Story?) -> Void)? = nil) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "Enter a topic to research."
            completion?(nil)
            return
        }

        isCreatingStory = true
        resolveTopic(from: trimmedPrompt, fallback: trimmedPrompt) { [weak self] canonicalTopic in
            guard let self else { return }
            let existingStory = self.stories.first(where: {
                self.normalizedTopicKey(for: $0.topic) == self.normalizedTopicKey(for: canonicalTopic)
            })

            self.webResearchService.buildResearchBundle(userPrompt: trimmedPrompt, theme: canonicalTopic) { bundle in
                self.aiService.researchStory(
                    topic: canonicalTopic,
                    userPrompt: trimmedPrompt,
                    researchInput: bundle.researchInput,
                    sourceReferences: bundle.sourceReferences,
                    existingStory: existingStory
                ) { payload, provider, _ in
                    let story = self.buildStory(
                        from: existingStory,
                        topic: canonicalTopic,
                        userPrompt: trimmedPrompt,
                        payload: payload,
                        provider: provider,
                        sourceArticleCount: bundle.sourceCount,
                        sourceNames: bundle.sourceNames,
                        sourceReferences: bundle.sourceReferences,
                        addedContext: nil
                    )
                    
                    self.upsert(story)
                    self.isCreatingStory = false
                    completion?(story)
                }
            }
        }
    }
    
    func enhanceStory(id: UUID, additionalContext: String) {
        guard let existingStory = stories.first(where: { $0.id == id }) else { return }
        
        let context = additionalContext.nonEmpty ?? "Add more useful context, nuance, and implications."
        loadingStoryIDs.insert(id)
        
        let researchPrompt = existingStory.userPrompt.nonEmpty ?? existingStory.topic
        
        resolveTopic(from: researchPrompt, fallback: existingStory.topic) { [weak self] resolvedTopic in
            guard let self else { return }

            self.webResearchService.buildResearchBundle(userPrompt: researchPrompt, theme: resolvedTopic) { bundle in
                self.aiService.researchStory(
                    topic: resolvedTopic,
                    userPrompt: researchPrompt,
                    researchInput: bundle.researchInput,
                    sourceReferences: bundle.sourceReferences,
                    existingStory: existingStory,
                    extraGuidance: context
                ) { payload, provider, _ in
                    let updatedStory = self.buildStory(
                        from: existingStory,
                        topic: resolvedTopic,
                        userPrompt: researchPrompt,
                        payload: payload,
                        provider: provider,
                        sourceArticleCount: bundle.sourceCount,
                        sourceNames: bundle.sourceNames,
                        sourceReferences: bundle.sourceReferences,
                        addedContext: context
                    )
                    
                    self.upsert(updatedStory)
                    self.loadingStoryIDs.remove(id)
                }
            }
        }
    }
    
    func refreshFollowedStories() {
        let followedStories = stories.filter(\.isFollowed)
        
        for story in followedStories {
            refreshStory(id: story.id, notifyOnChange: true)
        }
    }
    
    func refreshStory(id: UUID, notifyOnChange: Bool = false) {
        guard let existingStory = stories.first(where: { $0.id == id }) else { return }
        loadingStoryIDs.insert(id)
        
        let researchPrompt = existingStory.userPrompt.nonEmpty ?? existingStory.topic
        
        resolveTopic(from: researchPrompt, fallback: existingStory.topic) { [weak self] resolvedTopic in
            guard let self else { return }

            self.webResearchService.buildResearchBundle(userPrompt: researchPrompt, theme: resolvedTopic) { bundle in
                self.aiService.researchStory(
                    topic: resolvedTopic,
                    userPrompt: researchPrompt,
                    researchInput: bundle.researchInput,
                    sourceReferences: bundle.sourceReferences,
                    existingStory: existingStory,
                    extraGuidance: "Refresh this story with any meaningful new developments while keeping continuity with the current card."
                ) { payload, provider, _ in
                    let refreshedStory = self.buildStory(
                        from: existingStory,
                        topic: resolvedTopic,
                        userPrompt: researchPrompt,
                        payload: payload,
                        provider: provider,
                        sourceArticleCount: bundle.sourceCount,
                        sourceNames: bundle.sourceNames,
                        sourceReferences: bundle.sourceReferences,
                        addedContext: nil
                    )
                    
                    self.upsert(refreshedStory)
                    
                    if notifyOnChange,
                       existingStory.isFollowed,
                       existingStory.contentSignature != refreshedStory.contentSignature {
                        self.scheduleUpdateNotification(for: refreshedStory)
                    }
                    
                    self.loadingStoryIDs.remove(id)
                }
            }
        }
    }
    
    func toggleFollow(for id: UUID) {
        guard let index = stories.firstIndex(where: { $0.id == id }) else { return }
        stories[index].isFollowed.toggle()
        
        if stories[index].isFollowed {
            requestNotificationAuthorization()
        }
        
        saveStories()
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification authorization error:", error.localizedDescription)
            }
            
            if !granted {
                print("Notification permission not granted.")
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

private extension StoryManager {
    
    func loadStories() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Story].self, from: data) else {
            stories = []
            return
        }
        
        stories = decoded.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func saveStories() {
        guard let data = try? JSONEncoder().encode(stories) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    func upsert(_ story: Story) {
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = story
        } else {
            stories.insert(story, at: 0)
        }
        
        stories.sort { $0.lastUpdated > $1.lastUpdated }
        saveStories()
    }
    
    func buildStory(
        from existingStory: Story?,
        topic: String,
        userPrompt: String,
        payload: StoryResearchPayload,
        provider: String,
        sourceArticleCount: Int,
        sourceNames: [String],
        sourceReferences: [StorySourceReference],
        addedContext: String?
    ) -> Story {
        let sanitizedPayload = payload.sanitized(fallbackTopic: topic)
        let newSignature = Story.contentSignature(for: topic, payload: sanitizedPayload)
        let now = Date()
        let didChange = existingStory?.contentSignature != newSignature
        let resolvedSourceNames = sourceNames.isEmpty ? (existingStory?.sourceNames ?? []) : sourceNames
        let resolvedSourceCount = sourceArticleCount == 0 ? (existingStory?.sourceArticleCount ?? 0) : sourceArticleCount
        let resolvedSourceReferences = sourceReferences.isEmpty ? (existingStory?.sourceReferences ?? []) : sourceReferences
        
        var contextHistory = existingStory?.addedContext ?? []
        if let addedContext, !contextHistory.contains(addedContext) {
            contextHistory.append(addedContext)
        }
        
        return Story(
            id: existingStory?.id ?? UUID(),
            topic: topic,
            userPrompt: userPrompt,
            title: sanitizedPayload.title,
            overview: sanitizedPayload.overview,
            simpleExplanation: sanitizedPayload.simpleExplanation,
            keyTerms: sanitizedPayload.keyTerms,
            timeline: sanitizedPayload.timeline,
            keyFacts: sanitizedPayload.keyFacts,
            stakeholderGoals: sanitizedPayload.stakeholderGoals,
            globalImpact: sanitizedPayload.globalImpact,
            indiaImpact: sanitizedPayload.indiaImpact,
            whyItMatters: sanitizedPayload.whyItMatters,
            watchFor: sanitizedPayload.watchFor,
            scenarios: sanitizedPayload.scenarios,
            verificationNotes: sanitizedPayload.verificationNotes,
            addedContext: contextHistory,
            sourceArticleCount: resolvedSourceCount,
            sourceNames: resolvedSourceNames,
            sourceReferences: resolvedSourceReferences,
            summaryProvider: provider,
            isFollowed: existingStory?.isFollowed ?? false,
            lastUpdated: didChange ? now : (existingStory?.lastUpdated ?? now),
            lastCheckedAt: now,
            contentSignature: newSignature
        )
    }
    
    func normalizedTopicKey(for topic: String) -> String {
        topic
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func resolveTopic(
        from prompt: String,
        fallback: String,
        completion: @escaping (String) -> Void
    ) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            completion(fallback)
            return
        }
        
        aiService.generateStoryTheme(from: trimmedPrompt) { theme, _, _ in
            let canonicalTopic = TopicManager.canonicalTopic(from: theme) ?? theme
            completion(canonicalTopic)
        }
    }
    
    func scheduleUpdateNotification(for story: Story) {
        let content = UNMutableNotificationContent()
        content.title = "Story updated: \(story.title)"
        content.body = story.watchFor.first ?? story.overview
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "story-update-\(story.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Story notification scheduling error:", error.localizedDescription)
            }
        }
    }
}

private extension String {
    
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
