import SwiftUI

struct ExploreMoreView: View {
    let card: SummaryCard
    @State private var chatInput: String = ""
    @State private var messages: [String] = [] 
    @Environment(\.dismiss) var dismiss
    
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
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        
        // Mock response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append("iPal: Let's explore \(card.title) further. (LLM integration pending)")
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
