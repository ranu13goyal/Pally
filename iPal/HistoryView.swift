import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = ChatHistoryManager.shared
    @State private var selectedChatCard: SummaryCard?
    
    // We'll need access to all known cards to map IDs back to objects
    // In a real app, this would be a local database.
    private var allKnownCards: [SummaryCard] {
        LearningMockData.cards // For now, only mock cards are supported in history
    }
    
    var body: some View {
        NavigationView {
            List {
                let historyKeys = Array(historyManager.history.keys).sorted()
                
                if historyKeys.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No conversation history yet")
                            .font(.headline)
                        Text("Deep dives from your Learn tab will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(historyKeys, id: \.self) { cardID in
                        if let card = allKnownCards.first(where: { $0.id == cardID }) {
                            Button {
                                selectedChatCard = card
                            } label: {
                                HistoryRow(card: card, lastMessage: historyManager.messages(for: cardID).last)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Stories")
            .sheet(item: $selectedChatCard) { card in
                ExploreMoreView(card: card)
            }
        }
    }
}

struct HistoryRow: View {
    let card: SummaryCard
    let lastMessage: ChatMessage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.topic.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                
                Spacer()
                
                if let timestamp = lastMessage?.timestamp {
                    Text(timestamp, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(card.title)
                .font(.headline)
                .lineLimit(1)
            
            if let lastText = lastMessage?.text {
                Text(lastText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text("Start exploring...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 8)
    }
}
