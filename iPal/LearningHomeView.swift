import SwiftUI

struct LearningHomeView: View {
    
    @StateObject private var viewModel = LearningHomeViewModel()
    @State private var exploringCard: SummaryCard?
    @State private var searchQuery: String = ""
    @State private var showingAnalytics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Search for immediate knowledge (e.g. Monte Carlo)", text: $searchQuery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Learn") {
                                if !searchQuery.isEmpty {
                                    viewModel.searchImmediateKnowledge(query: searchQuery) { card in
                                        viewModel.searchedCard = card
                                    }
                                    searchQuery = ""
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if let card = viewModel.searchedCard {
                            VStack(alignment: .leading) {
                                Text("Search Result")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                LearningCardView(
                                    card: card,
                                    isSaved: viewModel.profileManager.isSaved(card),
                                    isRead: viewModel.profileManager.profile.readCardIDs.contains(card.id),
                                    questionCount: viewModel.questionManager.questionCount(for: card),
                                    onFeedback: { action in
                                        viewModel.handle(action, for: card)
                                    },
                                    onGetFeedback: {
                                        viewModel.profileManager.profile.feedbackHistory[card.id]
                                    },
                                    onMarkAsRead: {
                                        viewModel.markAsRead(card: card)
                                    },
                                    onExploreMore: {
                                        exploringCard = card
                                    }
                                )
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView("Curating your daily learning feed...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if viewModel.cards.isEmpty && viewModel.searchedCard == nil {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("All caught up!")
                                .font(.headline)
                            Text("You've read everything in your current feed. Try searching for a new topic above to keep learning.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(viewModel.cards) { card in
                            LearningCardView(
                                card: card,
                                isSaved: viewModel.profileManager.isSaved(card),
                                isRead: viewModel.profileManager.profile.readCardIDs.contains(card.id),
                                questionCount: viewModel.questionManager.questionCount(for: card),
                                onFeedback: { action in
                                    viewModel.handle(action, for: card)
                                },
                                onGetFeedback: {
                                    viewModel.profileManager.profile.feedbackHistory[card.id]
                                },
                                onMarkAsRead: {
                                    viewModel.markAsRead(card: card)
                                },
                                onExploreMore: {
                                    exploringCard = card
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAnalytics = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadDailyCards()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(item: $viewModel.activeQuizSession) { session in
            QuizView(session: session) { answers in
                viewModel.completeQuiz(session: session, selectedAnswers: answers)
            }
        }
        .sheet(item: $exploringCard) { card in
            ExploreMoreView(card: card)
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView(profileManager: viewModel.profileManager)
        }
        .alert("Learn", isPresented: deepDiveAlertIsPresented) {
            Button("OK") {
                viewModel.clearDeepDiveStatus()
            }
        } message: {
            Text(viewModel.deepDiveStatusMessage ?? "")
        }
    }
}

private extension LearningHomeView {
    
    var deepDiveAlertIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.deepDiveStatusMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearDeepDiveStatus()
                }
            }
        )
    }
}
