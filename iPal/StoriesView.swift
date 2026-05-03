import SwiftUI

struct StoriesView: View {
    
    @StateObject private var storyManager = StoryManager()
    @State private var activePrompt: StoryPrompt?
    @State private var hasRefreshedOnAppear = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    
                    if storyManager.stories.isEmpty && !storyManager.isCreatingStory {
                        emptyState
                    } else {
                        VStack(spacing: 16) {
                            if storyManager.isCreatingStory {
                                storyLoadingCard
                            }
                            
                            ForEach(storyManager.stories) { story in
                                StoryCard(
                                    story: story,
                                    isRefreshing: storyManager.loadingStoryIDs.contains(story.id),
                                    onEnhance: {
                                        activePrompt = .enhance(story)
                                    },
                                    onFollowToggle: {
                                        storyManager.toggleFollow(for: story.id)
                                    },
                                    onRefresh: {
                                        storyManager.refreshStory(id: story.id, notifyOnChange: story.isFollowed)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        storyManager.refreshFollowedStories()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(item: $activePrompt) { prompt in
            StoryPromptSheet(prompt: prompt) { promptText, context in
                switch prompt {
                case .ask:
                    storyManager.createStory(prompt: promptText)
                case .enhance(let story):
                    storyManager.enhanceStory(id: story.id, additionalContext: context)
                }
            }
        }
        .alert("Stories", isPresented: errorAlertIsPresented) {
            Button("OK") {
                storyManager.clearError()
            }
        } message: {
            Text(storyManager.errorMessage ?? "Something went wrong.")
        }
        .onAppear {
            if !hasRefreshedOnAppear {
                storyManager.refreshFollowedStories()
                hasRefreshedOnAppear = true
            }
        }
    }
}

private extension StoriesView {
    
    var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { storyManager.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    storyManager.clearError()
                }
            }
        )
    }
    
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ask AI to build a living story")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Research any topic, keep enriching the brief, and follow it so fresh developments can trigger an update.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                activePrompt = .ask
            } label: {
                Label("Ask AI", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No stories yet")
                .font(.headline)
            
            Text("Tap Ask AI to create a deep-dive card for a topic you want to understand or track.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    var storyLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Researching and drafting your story card...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct StoryCard: View {
    
    let story: Story
    let isRefreshing: Bool
    let onEnhance: () -> Void
    let onFollowToggle: () -> Void
    let onRefresh: () -> Void
    
    @State private var isPromptExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.topic)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Text(story.title)
                        .font(.headline)
                }
                
                Spacer()
                
                if story.isFollowed {
                    Label("Following", systemImage: "bell.badge.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text(story.overview)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            storySection("Simple explanation", items: story.simpleExplanation)
            storySection("Key terms", items: story.keyTerms)
            storySection("Timeline", items: story.timeline)
            if !story.userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Your prompt")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(isPromptExpanded ? "Show less" : "Show more") {
                            isPromptExpanded.toggle()
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                    }
                    
                    Text(displayPromptText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            storySection("Key facts", items: story.keyFacts)
            storySection("Who wants what", items: story.stakeholderGoals)
            storySection("Global impact", items: story.globalImpact)
            storySection("What it means for India", items: story.indiaImpact)
            storySection("Why it matters", items: story.whyItMatters)
            storySection("What to watch", items: story.watchFor)
            storySection("What happens next", items: story.scenarios)
            storySection("Verification notes", items: story.verificationNotes)
            sourcesSection
            
            if !story.addedContext.isEmpty {
                storySection("Added context", items: story.addedContext)
            }
            
            HStack(spacing: 10) {
                actionButton(
                    title: "Enhance story",
                    systemImage: "text.badge.plus",
                    fill: Color.blue,
                    foreground: .white,
                    action: onEnhance
                )
                
                actionButton(
                    title: story.isFollowed ? "Following" : "Follow story",
                    systemImage: story.isFollowed ? "bell.fill" : "bell.badge",
                    fill: story.isFollowed ? Color.orange : Color(.secondarySystemBackground),
                    foreground: story.isFollowed ? .white : .primary,
                    action: onFollowToggle
                )
            }
            
            HStack {
                Text("Updated \(story.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onRefresh) {
                    HStack(spacing: 6) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Text(isRefreshing ? "Checking..." : "Check updates")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
            }
            
            if story.sourceArticleCount > 0 {
                Text(sourceFootnote)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    @ViewBuilder
    func storySection(_ title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    var sourcesSection: some View {
        if !story.sourceReferences.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sources")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(Array(story.sourceReferences.prefix(5))) { reference in
                    if let url = URL(string: reference.url) {
                        Link(destination: url) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reference.sourceName)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(reference.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    func actionButton(
        title: String,
        systemImage: String,
        fill: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(fill)
                .foregroundColor(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    var displayPromptText: String {
        let trimmed = story.userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard !isPromptExpanded, trimmed.count > 140 else { return trimmed }
        return String(trimmed.prefix(140)) + "..."
    }
    
    var sourceFootnote: String {
        guard !story.sourceNames.isEmpty else {
            return "Built from \(story.sourceArticleCount) researched sources"
        }
        
        let joinedNames = story.sourceNames.prefix(4).joined(separator: ", ")
        let suffix = story.sourceNames.count > 4 ? ", and more" : ""
        return "Verified coverage pulled from \(joinedNames)\(suffix)"
    }
}

private struct StoryPromptSheet: View {
    
    let prompt: StoryPrompt
    let onSubmit: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var topic: String = ""
    @State private var context: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                if prompt == .ask {
                    Section("Prompt") {
                        TextField(
                            "Ask a question or describe the story you want researched",
                            text: $topic,
                            axis: .vertical
                        )
                        .lineLimit(4...8)
                    }
                } else {
                    Section("Story") {
                        TextField("Enter a topic", text: $topic)
                            .disabled(true)
                    }
                    
                    Section("More context") {
                        TextField(
                            "What more do you want to know?",
                            text: $context,
                            axis: .vertical
                        )
                        .lineLimit(4...8)
                    }
                }
            }
            .navigationTitle(prompt.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(prompt.submitTitle) {
                        onSubmit(topic, context)
                        dismiss()
                    }
                    .disabled(topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            switch prompt {
            case .ask:
                topic = ""
                context = ""
            case .enhance(let story):
                topic = story.topic
                context = ""
            }
        }
    }
}

private enum StoryPrompt: Identifiable, Equatable {
    case ask
    case enhance(Story)
    
    var id: String {
        switch self {
        case .ask:
            return "ask"
        case .enhance(let story):
            return "enhance-\(story.id.uuidString)"
        }
    }
    
    var title: String {
        switch self {
        case .ask:
            return "Ask AI"
        case .enhance:
            return "Enhance Story"
        }
    }
    
    var submitTitle: String {
        switch self {
        case .ask:
            return "Research"
        case .enhance:
            return "Enhance"
        }
    }
    
    var isEnhance: Bool {
        switch self {
        case .ask:
            return false
        case .enhance:
            return true
        }
    }
}
