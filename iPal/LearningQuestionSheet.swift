import SwiftUI

struct LearningQuestionSheet: View {
    
    let card: SummaryCard
    @ObservedObject var questionManager: LearningQuestionManager
    let isGeneratingDeepDive: Bool
    let onGenerateDeepDive: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var draftQuestion = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    composerCard
                    savedQuestionsCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Questions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension LearningQuestionSheet {
    
    var cardQuestions: [LearningFollowUpQuestion] {
        questionManager.questions(for: card)
    }
    
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.title)
                .font(.headline)
            
            Text("Capture the questions this card sparked for you. When you're ready, turn all of them into a deeper story in the Stories tab.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    var composerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask a follow-up question")
                .font(.headline)
            
            TextEditor(text: $draftQuestion)
                .frame(minHeight: 110)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            HStack(spacing: 10) {
                Button("Add question") {
                    addDraftQuestion()
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .clipShape(Capsule())
                .disabled(draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
                
                Button {
                    if !draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        addDraftQuestion()
                    }
                    onGenerateDeepDive()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingDeepDive {
                            ProgressView()
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "sparkles.rectangle.stack")
                        }
                        Text(cardQuestions.isEmpty ? "Generate deep view" : "Generate deep view (\(cardQuestions.count))")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(cardQuestions.isEmpty && draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(.tertiarySystemFill) : Color.blue)
                    .foregroundColor(cardQuestions.isEmpty && draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(cardQuestions.isEmpty && draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    var savedQuestionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved questions")
                .font(.headline)
            
            if cardQuestions.isEmpty {
                Text("No questions saved yet. Add one above, then generate a deeper story when you're ready.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(cardQuestions) { question in
                    HStack(alignment: .top, spacing: 10) {
                        Text("• \(question.prompt)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            questionManager.removeQuestion(question)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    func addDraftQuestion() {
        let question = draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        questionManager.addQuestion(question, for: card)
        draftQuestion = ""
    }
}
