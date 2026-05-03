import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @ObservedObject var historyManager = ChatHistoryManager.shared
    @State private var isTyping = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    private let aiService = AIService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Card Context Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(card.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.serif)
                        .inkText()
                    
                    Text(card.keyConceptTitle)
                        .font(.subheadline)
                        .fontDesign(.serif)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Chat Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        let messages = historyManager.messages(for: card.id)
                        
                        if messages.isEmpty {
                            VStack(spacing: 16) {
                                Text("Ask anything about \(card.title) to dive deeper.")
                                    .font(.body)
                                    .fontDesign(.serif)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                            }
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }
                            
                            if isTyping {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .fontDesign(.serif)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .fontDesign(.serif)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
                
                Divider()
                
                // Chat Input
                HStack(spacing: 12) {
                    TextField("Ask a question...", text: $chatInput)
                        .fontDesign(.serif)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: sendMessage) {
                        if isTyping {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 44, height: 44)
                                .background(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.3) : Color.primary)
                                .foregroundColor(Color(.systemBackground))
                                .clipShape(Circle())
                        }
                    }
                    .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                }
                .padding(16)
            }
            .paperBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontDesign(.sans)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        errorMessage = nil
        historyManager.saveMessage(trimmedInput, isUser: true, for: card.id)
        
        chatInput = ""
        isTyping = true
        
        let messagesToSend = historyManager.messages(for: card.id)
        let aiMessages = messagesToSend.map { $0.isUser ? "You: \($0.text)" : "iPal: \($0.text)" }
        
        aiService.generateChatResponse(card: card, messages: aiMessages) { response, success in
            isTyping = false
            if success {
                historyManager.saveMessage(response, isUser: false, for: card.id)
            } else {
                errorMessage = response
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.body)
                    .fontDesign(.serif)
                    .lineSpacing(6)
                    .padding(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
            } else {
                Text(message.text)
                    .font(.body)
                    .fontDesign(.serif)
                    .lineSpacing(8)
                    .inkText()
                    .padding(.horizontal, 24)
                Spacer(minLength: 40)
            }
        }
    }
}