import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @State private var messages: [String] = [] 
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
                            ForEach(messages, id: \.self) { message in
                                MessageBubble(text: message)
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
        }
    }
    
    private func sendMessage() {
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        messages.append("You: \(trimmedInput)")
        chatInput = ""
        isTyping = true
        
        aiService.generateChatResponse(card: card, messages: messages) { response, success in
            isTyping = false
            messages.append("iPal: \(response)")
        }
    }
}

struct MessageBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            if text.hasPrefix("You:") {
                Spacer()
            }
            
            Text(text.replacingOccurrences(of: "You: ", with: "").replacingOccurrences(of: "iPal: ", with: ""))
                .padding(12)
                .background(text.hasPrefix("You:") ? Color.blue : Color(.systemGray5))
                .foregroundColor(text.hasPrefix("You:") ? .white : .primary)
                .cornerRadius(16)
            
            if text.hasPrefix("iPal:") {
                Spacer()
            }
        }
    }
}
