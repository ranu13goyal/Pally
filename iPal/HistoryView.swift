import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = ChatHistoryManager.shared
    @State private var selectedChatCard: SummaryCard?
    @State private var searchText: String = "" // NEW
    
    // We'll need access to all known cards to map IDs back to objects
    // In a real app, this would be a local database.
    private var allKnownCards: [SummaryCard] {
        CardStorageManager.shared.getAllCards() + LearningMockData.cards
    }
    
    private var filteredKeys: [String] {
        let historyKeys = Array(historyManager.history.keys).sorted()
        if searchText.isEmpty {
            return historyKeys
        } else {
            return historyKeys.filter { cardID in
                guard let card = allKnownCards.first(where: { $0.id == cardID }) else { return false }
                return card.title.localizedCaseInsensitiveContains(searchText) ||
                       card.topic.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if filteredKeys.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No stories found")
                            .font(.headline)
                        if searchText.isEmpty {
                            Text("Deep dives from your Learn tab will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredKeys, id: \.self) { cardID in
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
            .searchable(text: $searchText, prompt: "Search stories by topic or title...")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.topic.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .fontDesign(.sans)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let timestamp = lastMessage?.timestamp {
                    Text(timestamp, style: .date)
                        .font(.caption2)
                        .fontDesign(.sans)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(card.title)
                .font(.headline)
                .fontDesign(.serif)
                .lineLimit(2)
            
            if let lastText = lastMessage?.text {
                Text(lastText)
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(4)
            } else {
                Text("Start exploring...")
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 12)
    }
}
