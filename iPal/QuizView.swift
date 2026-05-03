import SwiftUI

struct QuizView: View {
    
    let session: QuizSession
    let onComplete: ([Int]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswers: [Int?]
    @State private var hasSubmitted = false
    
    init(session: QuizSession, onComplete: @escaping ([Int]) -> Void) {
        self.session = session
        self.onComplete = onComplete
        _selectedAnswers = State(initialValue: Array(repeating: nil, count: session.quiz.questions.count))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(session.card.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(session.quiz.questions.enumerated()), id: \.element.id) { index, question in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(index + 1). \(question.prompt)")
                                .font(.headline)
                            
                            Text(question.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                                Button {
                                    selectedAnswers[index] = optionIndex
                                } label: {
                                    HStack {
                                        Image(systemName: selectedAnswers[index] == optionIndex ? "largecircle.fill.circle" : "circle")
                                        Text(option)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if hasSubmitted {
                                Text(question.explanation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Quiz")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(hasSubmitted ? "Done" : "Submit") {
                        let answers = selectedAnswers.map { $0 ?? 0 }
                        hasSubmitted = true
                        onComplete(answers)
                        dismiss()
                    }
                    .disabled(selectedAnswers.contains(where: { $0 == nil }))
                }
            }
        }
    }
}
