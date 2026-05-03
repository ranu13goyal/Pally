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
                        .fontDesign(.default)
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
                    .fontDesign(.default)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let sourceURL = card.sourceURL, let url = URL(string: sourceURL) {
                    Link(card.sourceName.uppercased(), destination: url)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .fontDesign(.default)
                        .foregroundColor(.secondary)
                } else {
                    Text(card.sourceName.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .fontDesign(.default)
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
                    .fontDesign(.default)
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
                .fontDesign(.default)
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