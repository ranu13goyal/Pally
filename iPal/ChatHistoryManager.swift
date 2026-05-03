// iPal/ChatHistoryManager.swift
import Foundation

struct ChatMessage: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

@MainActor
final class ChatHistoryManager: ObservableObject {
    @Published private(set) var history: [String: [ChatMessage]] = [:]
    private let storageKey = "ipal_chat_history"
    
    static let shared = ChatHistoryManager()
    
    private init() {
        loadHistory()
    }
    
    func messages(for cardID: String) -> [ChatMessage] {
        history[cardID] ?? []
    }
    
    func saveMessage(_ text: String, isUser: Bool, for cardID: String) {
        let message = ChatMessage(text: text, isUser: isUser)
        var current = history[cardID] ?? []
        current.append(message)
        history[cardID] = current
        persist()
    }
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: [ChatMessage]].self, from: data) {
            history = decoded
        }
    }
}
