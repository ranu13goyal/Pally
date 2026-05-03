import Foundation

final class CardStorageManager {
    static let shared = CardStorageManager()
    private let fileName = "buffered_cards.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    private init() {}
    
    func getAllCards() -> [SummaryCard] {
        guard let data = try? Data(contentsOf: fileURL),
              let cards = try? JSONDecoder().decode([SummaryCard].self, from: data) else {
            return []
        }
        return cards
    }
    
    func saveCards(_ cards: [SummaryCard]) {
        if let data = try? JSONEncoder().encode(cards) {
            try? data.write(to: fileURL)
        }
    }
    
    func appendCard(_ card: SummaryCard) {
        var current = getAllCards()
        guard !current.contains(where: { $0.title.lowercased() == card.title.lowercased() }) else { return }
        current.append(card)
        saveCards(current)
    }
}
