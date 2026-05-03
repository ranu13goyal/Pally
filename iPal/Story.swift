import Foundation

struct StorySourceReference: Identifiable, Codable, Equatable, Hashable {
    var id: String { url }
    let sourceName: String
    let title: String
    let url: String
}

struct Story: Identifiable, Codable, Equatable {
    let id: UUID
    var topic: String
    var userPrompt: String
    var title: String
    var overview: String
    var simpleExplanation: [String]
    var keyTerms: [String]
    var timeline: [String]
    var keyFacts: [String]
    var stakeholderGoals: [String]
    var globalImpact: [String]
    var indiaImpact: [String]
    var whyItMatters: [String]
    var watchFor: [String]
    var scenarios: [String]
    var verificationNotes: [String]
    var addedContext: [String]
    var sourceArticleCount: Int
    var sourceNames: [String]
    var sourceReferences: [StorySourceReference]
    var summaryProvider: String
    var isFollowed: Bool
    var lastUpdated: Date
    var lastCheckedAt: Date?
    var contentSignature: String
    
    init(
        id: UUID = UUID(),
        topic: String,
        userPrompt: String = "",
        title: String,
        overview: String,
        simpleExplanation: [String] = [],
        keyTerms: [String] = [],
        timeline: [String] = [],
        keyFacts: [String],
        stakeholderGoals: [String] = [],
        globalImpact: [String] = [],
        indiaImpact: [String] = [],
        whyItMatters: [String],
        watchFor: [String],
        scenarios: [String] = [],
        verificationNotes: [String] = [],
        addedContext: [String] = [],
        sourceArticleCount: Int,
        sourceNames: [String] = [],
        sourceReferences: [StorySourceReference] = [],
        summaryProvider: String,
        isFollowed: Bool = false,
        lastUpdated: Date = Date(),
        lastCheckedAt: Date? = nil,
        contentSignature: String
    ) {
        self.id = id
        self.topic = topic
        self.userPrompt = userPrompt
        self.title = title
        self.overview = overview
        self.simpleExplanation = simpleExplanation
        self.keyTerms = keyTerms
        self.timeline = timeline
        self.keyFacts = keyFacts
        self.stakeholderGoals = stakeholderGoals
        self.globalImpact = globalImpact
        self.indiaImpact = indiaImpact
        self.whyItMatters = whyItMatters
        self.watchFor = watchFor
        self.scenarios = scenarios
        self.verificationNotes = verificationNotes
        self.addedContext = addedContext
        self.sourceArticleCount = sourceArticleCount
        self.sourceNames = sourceNames
        self.sourceReferences = sourceReferences
        self.summaryProvider = summaryProvider
        self.isFollowed = isFollowed
        self.lastUpdated = lastUpdated
        self.lastCheckedAt = lastCheckedAt
        self.contentSignature = contentSignature
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case topic
        case userPrompt
        case title
        case overview
        case simpleExplanation
        case keyTerms
        case timeline
        case keyFacts
        case stakeholderGoals
        case globalImpact
        case indiaImpact
        case whyItMatters
        case watchFor
        case scenarios
        case verificationNotes
        case addedContext
        case sourceArticleCount
        case sourceNames
        case sourceReferences
        case summaryProvider
        case isFollowed
        case lastUpdated
        case lastCheckedAt
        case contentSignature
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        topic = try container.decode(String.self, forKey: .topic)
        userPrompt = try container.decodeIfPresent(String.self, forKey: .userPrompt) ?? topic
        title = try container.decode(String.self, forKey: .title)
        overview = try container.decode(String.self, forKey: .overview)
        simpleExplanation = try container.decodeIfPresent([String].self, forKey: .simpleExplanation) ?? []
        keyTerms = try container.decodeIfPresent([String].self, forKey: .keyTerms) ?? []
        timeline = try container.decodeIfPresent([String].self, forKey: .timeline) ?? []
        keyFacts = try container.decode([String].self, forKey: .keyFacts)
        stakeholderGoals = try container.decodeIfPresent([String].self, forKey: .stakeholderGoals) ?? []
        globalImpact = try container.decodeIfPresent([String].self, forKey: .globalImpact) ?? []
        indiaImpact = try container.decodeIfPresent([String].self, forKey: .indiaImpact) ?? []
        whyItMatters = try container.decode([String].self, forKey: .whyItMatters)
        watchFor = try container.decode([String].self, forKey: .watchFor)
        scenarios = try container.decodeIfPresent([String].self, forKey: .scenarios) ?? []
        verificationNotes = try container.decodeIfPresent([String].self, forKey: .verificationNotes) ?? []
        addedContext = try container.decodeIfPresent([String].self, forKey: .addedContext) ?? []
        sourceArticleCount = try container.decodeIfPresent(Int.self, forKey: .sourceArticleCount) ?? 0
        sourceNames = try container.decodeIfPresent([String].self, forKey: .sourceNames) ?? []
        sourceReferences = try container.decodeIfPresent([StorySourceReference].self, forKey: .sourceReferences) ?? []
        summaryProvider = try container.decodeIfPresent(String.self, forKey: .summaryProvider) ?? "Unknown"
        isFollowed = try container.decodeIfPresent(Bool.self, forKey: .isFollowed) ?? false
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
        lastCheckedAt = try container.decodeIfPresent(Date.self, forKey: .lastCheckedAt)
        contentSignature = try container.decodeIfPresent(String.self, forKey: .contentSignature) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(topic, forKey: .topic)
        try container.encode(userPrompt, forKey: .userPrompt)
        try container.encode(title, forKey: .title)
        try container.encode(overview, forKey: .overview)
        try container.encode(simpleExplanation, forKey: .simpleExplanation)
        try container.encode(keyTerms, forKey: .keyTerms)
        try container.encode(timeline, forKey: .timeline)
        try container.encode(keyFacts, forKey: .keyFacts)
        try container.encode(stakeholderGoals, forKey: .stakeholderGoals)
        try container.encode(globalImpact, forKey: .globalImpact)
        try container.encode(indiaImpact, forKey: .indiaImpact)
        try container.encode(whyItMatters, forKey: .whyItMatters)
        try container.encode(watchFor, forKey: .watchFor)
        try container.encode(scenarios, forKey: .scenarios)
        try container.encode(verificationNotes, forKey: .verificationNotes)
        try container.encode(addedContext, forKey: .addedContext)
        try container.encode(sourceArticleCount, forKey: .sourceArticleCount)
        try container.encode(sourceNames, forKey: .sourceNames)
        try container.encode(sourceReferences, forKey: .sourceReferences)
        try container.encode(summaryProvider, forKey: .summaryProvider)
        try container.encode(isFollowed, forKey: .isFollowed)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encodeIfPresent(lastCheckedAt, forKey: .lastCheckedAt)
        try container.encode(contentSignature, forKey: .contentSignature)
    }
}

struct StoryResearchPayload: Codable, Equatable {
    var title: String
    var overview: String
    var simpleExplanation: [String]
    var keyTerms: [String]
    var timeline: [String]
    var keyFacts: [String]
    var stakeholderGoals: [String]
    var globalImpact: [String]
    var indiaImpact: [String]
    var whyItMatters: [String]
    var watchFor: [String]
    var scenarios: [String]
    var verificationNotes: [String]
    
    func sanitized(fallbackTopic: String) -> StoryResearchPayload {
        StoryResearchPayload(
            title: title.nonEmpty ?? fallbackTopic,
            overview: overview.nonEmpty ?? "A concise research brief is being assembled for \(fallbackTopic).",
            simpleExplanation: sanitizedList(simpleExplanation, fallback: [
                "\(fallbackTopic) is an evolving story. This card simplifies the latest reliable reporting.",
                "The situation can shift quickly, so this summary should be read as a current snapshot."
            ]),
            keyTerms: sanitizedList(keyTerms, fallback: []),
            timeline: sanitizedList(timeline, fallback: []),
            keyFacts: sanitizedList(keyFacts, fallback: [
                "Current coverage on \(fallbackTopic) is still limited, so this story will improve as more reporting is pulled in."
            ]),
            stakeholderGoals: sanitizedList(stakeholderGoals, fallback: []),
            globalImpact: sanitizedList(globalImpact, fallback: []),
            indiaImpact: sanitizedList(indiaImpact, fallback: []),
            whyItMatters: sanitizedList(whyItMatters, fallback: [
                "\(fallbackTopic) could become more important as the story evolves."
            ]),
            watchFor: sanitizedList(watchFor, fallback: [
                "Watch for fresh reporting, new numbers, or official statements tied to \(fallbackTopic)."
            ]),
            scenarios: sanitizedList(scenarios, fallback: []),
            verificationNotes: sanitizedList(verificationNotes, fallback: [
                "Use this story as a guide to reputable coverage, not as a substitute for primary reporting."
            ])
        )
    }
    
    private func sanitizedList(_ input: [String], fallback: [String]) -> [String] {
        let cleaned = input
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return cleaned.isEmpty ? fallback : cleaned
    }
}

extension Story {
    
    static func contentSignature(for topic: String, payload: StoryResearchPayload) -> String {
        var parts: [String] = []
        parts.append(topic)
        parts.append(payload.title)
        parts.append(payload.overview)
        parts.append(payload.simpleExplanation.joined(separator: " "))
        parts.append(payload.keyTerms.joined(separator: " "))
        parts.append(payload.timeline.joined(separator: " "))
        parts.append(payload.keyFacts.joined(separator: " "))
        parts.append(payload.stakeholderGoals.joined(separator: " "))
        parts.append(payload.globalImpact.joined(separator: " "))
        parts.append(payload.indiaImpact.joined(separator: " "))
        parts.append(payload.whyItMatters.joined(separator: " "))
        parts.append(payload.watchFor.joined(separator: " "))
        parts.append(payload.scenarios.joined(separator: " "))
        parts.append(payload.verificationNotes.joined(separator: " "))
        
        let joined = parts.joined(separator: " ").lowercased()
        let withoutPunctuation = joined.replacingOccurrences(
            of: "[^a-z0-9\\s]",
            with: " ",
            options: NSString.CompareOptions.regularExpression
        )
        
        let compactedWhitespace = withoutPunctuation.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: NSString.CompareOptions.regularExpression
        )
        
        return compactedWhitespace.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

private extension String {
    
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
