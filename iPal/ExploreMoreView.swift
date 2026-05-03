import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @State private var messages: [ChatMessage] = [] 
    @State private var isTyping = false
    @Environment(\.dismiss) var dismiss
    private let aiService = AIService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Card Context Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.title)
                        .font(.headline)
                    Text(card.keyConceptTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                
                // Chat Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange.opacity(0.8))
                                Text("Ask anything about \(card.title) to dive deeper.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
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
                                        .padding(.trailing, 4)
                                    Text("iPal is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Chat Input
                HStack(spacing: 12) {
                    TextField("Ask about \(card.title)...", text: $chatInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        if isTyping {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                }
                .padding()
            }
            .navigationTitle("Explore More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                messages = ChatHistoryManager.shared.messages(for: card.id)
            }
        }
    }
    
    private func sendMessage() {
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        // Save user message
        ChatHistoryManager.shared.saveMessage(trimmedInput, isUser: true, for: card.id)
        messages = ChatHistoryManager.shared.messages(for: card.id)
        
        chatInput = ""
        isTyping = true
        
        // Map current messages for AI service
        let aiMessages = messages.map { $0.isUser ? "You: \($0.text)" : "iPal: \($0.text)" }
        
        aiService.generateChatResponse(card: card, messages: aiMessages) { response, success in
            isTyping = false
            if success {
                ChatHistoryManager.shared.saveMessage(response, isUser: false, for: card.id)
                messages = ChatHistoryManager.shared.messages(for: card.id)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}
