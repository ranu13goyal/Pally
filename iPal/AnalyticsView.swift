import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var profileManager: UserProfileManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Stats
                    HStack(spacing: 20) {
                        StatBox(title: "Read", value: "\(profileManager.profile.readCardIDs.count)", icon: "book.fill", color: .blue)
                        StatBox(title: "Streak", value: "\(profileManager.profile.currentStreak)d", icon: "flame.fill", color: .orange)
                        StatBox(title: "Saved", value: "\(profileManager.profile.savedCardIDs.count)", icon: "bookmark.fill", color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Topic Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Topic Engagement")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(LearningTopic.allCases) { topic in
                                let score = profileManager.preferenceScore(for: topic)
                                TopicRow(topic: topic.rawValue, score: score)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            let totalQuizzes = profileManager.quizResults.count
                            let avgScore = totalQuizzes > 0 ? Double(profileManager.quizResults.map(\.correctCount).reduce(0, +)) / Double(profileManager.quizResults.map(\.totalCount).reduce(0, +)) : 0
                            
                            HStack {
                                Text("Quizzes Taken")
                                Spacer()
                                Text("\(totalQuizzes)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Average Accuracy")
                                Spacer()
                                Text("\(Int(avgScore * 100))%")
                                    .fontWeight(.bold)
                                    .foregroundColor(avgScore >= 0.7 ? .green : .orange)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Learning")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct TopicRow: View {
    let topic: String
    let score: Double
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(topic)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1fx", score))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(score >= 1.0 ? Color.blue : Color.orange)
                        .frame(width: geo.size.width * CGFloat(score / 3.0), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
