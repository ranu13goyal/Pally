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
                    Text(card.topic.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Text(card.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    onFeedback(.save)
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundColor(isSaved ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            insightBlock(title: "Why this matters", content: card.whyItMatters)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Key takeaways")
                    .font(.headline)
                
                ForEach(card.bulletSummary, id: \.self) { bullet in
                    Text("• \(bullet)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            insightBlock(
                title: card.keyConceptTitle,
                content: card.keyConceptExplanation
            )
            
            HStack {
                Text("\(card.estimatedReadingMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let sourceURL = card.sourceURL, let url = URL(string: sourceURL) {
                    Link(card.sourceName, destination: url)
                        .font(.caption)
                } else {
                    Text(card.sourceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            feedbackBar
            
            actionButtons
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private extension LearningCardView {
    
    func insightBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    var feedbackBar: some View {
        HStack(spacing: 10) {
            let currentFeedback = onGetFeedback()
            
            quickAction(
                "Like",
                icon: "hand.thumbsup",
                action: .like,
                isActive: currentFeedback == .like,
                activeColor: .blue
            )
            
            quickAction(
                "Dislike",
                icon: "hand.thumbsdown",
                action: .dislike,
                isActive: currentFeedback == .dislike,
                activeColor: .red
            )
        }
    }
    
    func quickAction(
        _ title: String,
        icon: String,
        action: CardFeedbackAction,
        isActive: Bool = false,
        activeColor: Color = .blue
    ) -> some View {
        Button {
            onFeedback(action)
        } label: {
            Label(title, systemImage: isActive ? "\(icon).fill" : icon)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? activeColor.opacity(0.15) : Color(.systemBackground))
                .foregroundColor(isActive ? activeColor : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
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
