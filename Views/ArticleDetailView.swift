import SwiftUI

struct ArticleDetailView: View {
    
    @Binding var article: Article
    
    @State private var isUpgradingSummary = false
    @State private var premiumError: String?
    
    private let aiService = AIService()
    private let contentFetcher = ContentFetcher()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(spacing: 8) {
                    Text(article.topic)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    
                    Text(article.source)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }
                
                Text(article.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                    
                    ForEach(article.bullets, id: \.self) { bullet in
                        Text("• \(bullet)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                if article.isSummarizing || isUpgradingSummary {
                    ProgressView("Generating better summary...")
                        .font(.caption)
                }
                
                HStack(spacing: 10) {
                    if article.isPremiumSummary {
                        Label("Premium Summary", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Button(action: {
                            upgradeSummary()
                        }) {
                            Label("Upgrade Summary", systemImage: "sparkles")
                                .font(.subheadline)
                        }
                        .disabled(isUpgradingSummary)
                    }
                    
                    if article.summaryProvider != "None" {
                        Text(article.summaryProvider)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if let premiumError, !premiumError.isEmpty {
                    Text(premiumError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text(article.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if article.engagementScore > 0 {
                        Text("Score \(article.engagementScore)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if let url = URL(string: article.link) {
                    NavigationLink("Read Full Article →") {
                        SafariView(url: url)
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension ArticleDetailView {
    
    func upgradeSummary() {
        if article.isPremiumSummary || isUpgradingSummary {
            return
        }
        
        premiumError = nil
        isUpgradingSummary = true
        article.isSummarizing = true
        
        contentFetcher.fetchSummaryInput(
            from: article.link,
            title: article.title,
            snippet: article.snippet,
            maxLength: 9000
        ) { result in
            aiService.generatePremiumSummary(input: result.input) { bullets, provider, success in
                DispatchQueue.main.async {
                    article.bullets = bullets
                    article.isSummarizing = false
                    article.summaryProvider = result.usedFallback ? "Limited article text" : provider
                    article.isPremiumSummary = success
                    isUpgradingSummary = false
                    
                    if !success {
                        premiumError = result.usedFallback ? "Detailed article text could not be extracted." : provider
                    }
                }
            }
        }
    }
}
