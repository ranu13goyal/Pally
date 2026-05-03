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
                    
                    // Daily Trend
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Learning Trend")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DailyTrendChart(readHistory: profileManager.profile.readCardHistory)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                    
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

struct DailyTrendChart: View {
    let readHistory: [String: Date]
    
    private var dailyStats: [(String, Int)] {
        let calendar = Calendar.current
        let now = Date()
        var counts: [Date: Int] = [:]
        
        // Count for last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let startOfDay = calendar.startOfDay(for: date)
                counts[startOfDay] = 0
            }
        }
        
        for date in readHistory.values {
            let startOfDay = calendar.startOfDay(for: date)
            if counts[startOfDay] != nil {
                counts[startOfDay]! += 1
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        
        return counts.keys.sorted().map { date in
            (formatter.string(from: date), counts[date] ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                let maxCount = dailyStats.map(\.1).max() ?? 1
                let effectiveMax = max(maxCount, 5)
                
                ForEach(dailyStats, id: \.0) { day, count in
                    VStack {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.gradient)
                            .frame(height: CGFloat(count) / CGFloat(effectiveMax) * 100)
                        
                        Text(day)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
            
            Text("Cards read over the last 7 days")
                .font(.caption)
                .foregroundColor(.secondary)
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
