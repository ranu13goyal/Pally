import Foundation

final class AIService {
    
    private let groqEndpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let groqModel = "llama-3.3-70b-versatile"
    
    private var openRouterKey: String {
        fetchKey(named: "OpenRouterKey")
    }
    
    private var groqKey: String {
        fetchKey(named: "GroqKey")
    }
    
    private func fetchKey(named name: String) -> String {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String],
              let key = dict[name] else {
            return "REDACTED"
        }
        return key
    }
    
    // MARK: - Public
    
    func generateFreeSummary(input: String, completion: @escaping ([String], String, Bool) -> Void) {
        if isLimitedExtractionInput(input) {
            completion(limitedExtractionBullets(), "Limited article text", false)
            return
        }
        
        callOpenRouterFree(input: input, completion: completion)
    }
    
    func generatePremiumSummary(input: String, completion: @escaping ([String], String, Bool) -> Void) {
        if isLimitedExtractionInput(input) {
            completion(limitedExtractionBullets(), "Limited article text", false)
            return
        }
        
        callGroq(input: input, completion: completion)
    }
    
    func researchStory(
        topic: String,
        userPrompt: String,
        researchInput: String,
        sourceReferences: [StorySourceReference] = [],
        existingStory: Story? = nil,
        extraGuidance: String? = nil,
        completion: @escaping (StoryResearchPayload, String, Bool) -> Void
    ) {
        callStoryResearch(
            topic: topic,
            userPrompt: userPrompt,
            researchInput: researchInput,
            sourceReferences: sourceReferences,
            existingStory: existingStory,
            extraGuidance: extraGuidance,
            completion: completion
        )
    }
    
    func generateStoryTheme(from userPrompt: String, completion: @escaping (String, String, Bool) -> Void) {
        callStoryThemeGeneration(userPrompt: userPrompt, completion: completion)
    }
    
    func generateChatResponse(
        card: SummaryCard,
        messages: [String],
        completion: @escaping (String, Bool) -> Void
    ) {
        let trimmedKey = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            completion("I'm sorry, I can't chat right now as the Groq API key is missing.", false)
            return
        }
        
        var request = URLRequest(url: groqEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are iPal, an AI tutor. You are helping the user explore a specific topic based on a learning card.
        
        Card Topic: \(card.topic.rawValue)
        Card Title: \(card.title)
        Card Why It Matters: \(card.whyItMatters)
        Card Key Concept: \(card.keyConceptTitle)
        Card Key Concept Explanation: \(card.keyConceptExplanation)
        Card Summary:
        \(card.bulletSummary.joined(separator: "\n"))
        
        Be concise, helpful, and encouraging. Stay focused on the topic of the card but feel free to expand on related concepts if asked.
        """
        
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        for message in messages {
            if message.hasPrefix("You: ") {
                let content = message.replacingOccurrences(of: "You: ", with: "")
                apiMessages.append(["role": "user", "content": content])
            } else if message.hasPrefix("iPal: ") {
                let content = message.replacingOccurrences(of: "iPal: ", with: "")
                apiMessages.append(["role": "assistant", "content": content])
            }
        }
        
        let body: [String: Any] = [
            "model": groqModel,
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("I encountered an error preparing your chat request.", false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Chat request network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion("Connection error. Please check your internet.", false) }
                return
            }
            
            guard let data = data else {
                print("Chat request error: No data received")
                DispatchQueue.main.async { completion("No response from server.", false) }
                return
            }
            
            do {
                if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                    print("Chat API Error: \(apiError.error.message)")
                    DispatchQueue.main.async { completion("iPal error: \(apiError.error.message)", false) }
                    return
                }
                
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let response = decoded.choices.first?.message.content ?? ""
                
                DispatchQueue.main.async {
                    completion(response, true)
                }
            } catch {
                print("Chat decode error: \(error)")
                DispatchQueue.main.async {
                    completion("I received an unexpected response structure. Please try again.", false)
                }
            }
        }.resume()
    }
    
    func generateLearningCard(
        query: String,
        completion: @escaping (SummaryCard?, Bool) -> Void
    ) {
        let trimmedKey = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            completion(nil, false)
            return
        }
        
        var request = URLRequest(url: groqEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Generate a learning card for the topic: \(query).
        
        Return valid JSON only with this exact schema:
        {
          "topic": "Business" | "Tech/AI" | "Geopolitics" | "History" | "Psychology" | "Science" | "Economics" | "Culture",
          "title": "A catchy title",
          "whyItMatters": "One sentence on why this topic is important today",
          "bulletSummary": ["Point 1", "Point 2", "Point 3", "Point 4", "Point 5"],
          "keyConceptTitle": "The name of a single key concept",
          "keyConceptExplanation": "A 1-2 sentence explanation of that concept",
          "sourceName": "iPal AI Research",
          "estimatedReadingMinutes": 3,
          "difficulty": "beginner" | "intermediate" | "advanced"
        }
        
        Be factual, concise, and educational.
        """
        
        let body: [String: Any] = [
            "model": groqModel,
            "messages": [
                ["role": "system", "content": "You are a research assistant that generates structured learning content. You MUST return valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.5,
            "max_tokens": 800
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil, false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Generate card network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil, false) }
                return
            }
            
            guard let data = data else {
                print("Generate card error: No data received")
                DispatchQueue.main.async { completion(nil, false) }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let rawContent = decoded.choices.first?.message.content ?? ""
                
                if let contentData = rawContent.data(using: .utf8) {
                    let cardStub = try JSONDecoder().decode(SummaryCardStub.self, from: contentData)
                    let fullCard = SummaryCard(
                        id: UUID().uuidString,
                        topic: LearningTopic(rawValue: cardStub.topic) ?? .techAI,
                        title: cardStub.title,
                        whyItMatters: cardStub.whyItMatters,
                        bulletSummary: cardStub.bulletSummary,
                        keyConceptTitle: cardStub.keyConceptTitle,
                        keyConceptExplanation: cardStub.keyConceptExplanation,
                        sourceName: cardStub.sourceName,
                        sourceURL: nil,
                        estimatedReadingMinutes: cardStub.estimatedReadingMinutes,
                        difficulty: CardDifficulty(rawValue: cardStub.difficulty) ?? .intermediate,
                        publishedAt: Date()
                    )
                    DispatchQueue.main.async { completion(fullCard, true) }
                } else {
                    print("Generate card error: Could not convert content to data")
                    DispatchQueue.main.async { completion(nil, false) }
                }
            } catch {
                print("Generate card decode error: \(error)")
                DispatchQueue.main.async { completion(nil, false) }
            }
        }.resume()
    }
    
    private struct SummaryCardStub: Decodable {
        let topic: String
        let title: String
        let whyItMatters: String
        let bulletSummary: [String]
        let keyConceptTitle: String
        let keyConceptExplanation: String
        let sourceName: String
        let estimatedReadingMinutes: Int
        let difficulty: String
    }
    
    // MARK: - Free Summary
    
    private func callOpenRouterFree(input: String, completion: @escaping ([String], String, Bool) -> Void) {
        guard !openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            completion(fallbackBullets(from: input), "Fallback", false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer \(openRouterKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Summarize the article below into exactly 3 crisp bullet points.

        Focus on:
        - What happened
        - Key facts
        - Why it matters

        Rules:
        - Do not repeat the headline verbatim
        - Keep each bullet under 20 words
        - Return only bullet points

        Article:
        \(input)
        """
        
        let body: [String: Any] = [
            "model": "openrouter/free",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 220
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(fallbackBullets(from: input), "Fallback", false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("OpenRouter request error:", error.localizedDescription)
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(self.fallbackBullets(from: input), "Fallback", false)
                }
                return
            }
            
            do {
                if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                    DispatchQueue.main.async {
                        completion(self.fallbackBullets(from: input), "Fallback: \(apiError.error.message)", false)
                    }
                    return
                }
                
                let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
                let raw = decoded.choices.first?.message.content ?? ""
                let bullets = self.extractBullets(from: raw)
                
                DispatchQueue.main.async {
                    completion(
                        bullets.isEmpty ? self.fallbackBullets(from: input) : bullets,
                        decoded.model ?? "OpenRouter Free",
                        !bullets.isEmpty
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    completion(self.fallbackBullets(from: input), "Fallback: decode failed", false)
                }
            }
        }.resume()
    }
    
    // MARK: - Groq (replacing Premium Summary/OpenAI)
    
    private func callGroq(input: String, completion: @escaping ([String], String, Bool) -> Void) {
        let trimmedKey = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            completion(fallbackBullets(from: input), "Fallback: missing Groq key", false)
            return
        }
        
        var request = URLRequest(url: groqEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        You are an expert analyst.

        Read the article content below and write a serious, high-quality summary.

        Return EXACTLY 4 bullet points covering:
        1. What happened
        2. Key facts, numbers, actors, or claims
        3. Why this matters or likely impact
        4. What to watch next

        Rules:
        - Use only the supplied content
        - Do not invent facts
        - Do not repeat the headline
        - Keep each bullet under 30 words
        - Return only bullet points

        Article:
        \(input)
        """
        
        let body: [String: Any] = [
            "model": groqModel,
            "messages": [
                ["role": "system", "content": "You summarize articles into sharp factual bullets."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 320
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(fallbackBullets(from: input), "Fallback: request build failed", false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Groq request error:", error.localizedDescription)
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(self.fallbackBullets(from: input), "Fallback: no response data", false)
                }
                return
            }
            
            do {
                if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                    DispatchQueue.main.async {
                        completion(self.fallbackBullets(from: input), "Fallback: \(apiError.error.message)", false)
                    }
                    return
                }
                
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let raw = decoded.choices.first?.message.content ?? ""
                let bullets = self.extractBullets(from: raw)
                
                DispatchQueue.main.async {
                    completion(
                        bullets.isEmpty ? self.fallbackBullets(from: input) : bullets,
                        bullets.isEmpty ? "Fallback: empty model output" : "Groq Llama-3.3",
                        !bullets.isEmpty
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    completion(self.fallbackBullets(from: input), "Fallback: decode failed", false)
                }
            }
        }.resume()
    }
    
    // MARK: - Helpers
    
    private func callStoryResearch(
        topic: String,
        userPrompt: String,
        researchInput: String,
        sourceReferences: [StorySourceReference],
        existingStory: Story?,
        extraGuidance: String?,
        completion: @escaping (StoryResearchPayload, String, Bool) -> Void
    ) {
        let trimmedKey = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            completion(fallbackStoryPayload(topic: topic, userPrompt: userPrompt, from: researchInput, sourceReferences: sourceReferences, existingStory: existingStory), "Fallback", false)
            return
        }
        
        var request = URLRequest(url: groqEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 40
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let existingStoryContext = existingStory.map { story in
            """
            Existing story card:
            Title: \(story.title)
            Overview: \(story.overview)
            Key facts: \(story.keyFacts.joined(separator: " | "))
            Why it matters: \(story.whyItMatters.joined(separator: " | "))
            Watch for: \(story.watchFor.joined(separator: " | "))
            Added context: \(story.addedContext.joined(separator: " | "))
            """
        } ?? "No prior story card exists for this topic."
        
        let citedSources = sourceReferences.prefix(6).map {
            "\($0.sourceName): \($0.title) (\($0.url))"
        }.joined(separator: "\n")
        
        let guidance = extraGuidance?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? extraGuidance!
            : "Make the story card useful, factual, and concise."
        
        let prompt = """
        You are preparing a living story explainer for a mobile news app.
        
        Return valid JSON only with this exact schema:
        {
          "title": "string",
          "overview": "string",
          "simpleExplanation": ["string"],
          "keyTerms": ["string"],
          "timeline": ["string"],
          "keyFacts": ["string"],
          "stakeholderGoals": ["string"],
          "globalImpact": ["string"],
          "indiaImpact": ["string"],
          "whyItMatters": ["string"],
          "watchFor": ["string"],
          "scenarios": ["string"],
          "verificationNotes": ["string"]
        }
        
        Rules:
        - Use only the topic and current coverage below.
        - Keep the overview under 110 words and write it in simple human language.
        - Write "simpleExplanation" like a plain-English explainer for a smart general reader.
        - Write "keyTerms" as short "Term: explanation" entries.
        - Write "timeline" as short "Date or phase: development" entries. If precise dates are not verified, use broader labels like "Recent weeks" or "Current phase".
        - Write "stakeholderGoals" as short "Actor: goal" entries.
        - Keep each array to 2-5 crisp items unless there is clearly not enough evidence.
        - If an existing story card is present, preserve continuity while refreshing facts.
        - If additional guidance is present, incorporate it into the updated story.
        - If the topic is globally relevant, fill "globalImpact". If it meaningfully affects India, fill "indiaImpact"; otherwise leave it empty.
        - Use "verificationNotes" to flag uncertainty, disputed claims, or important sourcing caveats.
        - Use the cited sources to anchor specific claims.
        - Separate background context from new developments.
        - Do not invent events, dates, leaders, ceasefires, deaths, or attack details that are not supported by the supplied coverage.
        - Do not include markdown fences.
        
        Topic:
        \(topic)
        
        Original user prompt:
        \(userPrompt)
        
        Additional guidance:
        \(guidance)
        
        Source list:
        \(citedSources.isEmpty ? "No source references available." : citedSources)
        
        \(existingStoryContext)
        
        Current coverage:
        \(researchInput)
        """
        
        let body: [String: Any] = [
            "model": groqModel,
            "messages": [
                ["role": "system", "content": "You return valid JSON for verified story explainers."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.2,
            "max_tokens": 1400
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(fallbackStoryPayload(topic: topic, userPrompt: userPrompt, from: researchInput, sourceReferences: sourceReferences, existingStory: existingStory), "Fallback", false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Story research request error: \(error.localizedDescription)")
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(self.fallbackStoryPayload(topic: topic, userPrompt: userPrompt, from: researchInput, sourceReferences: sourceReferences, existingStory: existingStory), "Fallback", false)
                }
                return
            }
            
            do {
                if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                    DispatchQueue.main.async {
                        completion(
                            self.fallbackStoryPayload(topic: topic, userPrompt: userPrompt, from: researchInput, sourceReferences: sourceReferences, existingStory: existingStory),
                            "Fallback: \(apiError.error.message)",
                            false
                        )
                    }
                    return
                }
                
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let raw = decoded.choices.first?.message.content ?? ""
                let payload = self.parseStoryPayload(
                    from: raw,
                    fallbackTopic: topic,
                    userPrompt: userPrompt,
                    researchInput: researchInput,
                    sourceReferences: sourceReferences,
                    existingStory: existingStory
                )
                
                DispatchQueue.main.async {
                    completion(payload, "Groq Llama-3.3", true)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(
                        self.fallbackStoryPayload(topic: topic, userPrompt: userPrompt, from: researchInput, sourceReferences: sourceReferences, existingStory: existingStory),
                        "Fallback: decode failed",
                        false
                    )
                }
            }
        }.resume()
    }
    
    private func callStoryThemeGeneration(
        userPrompt: String,
        completion: @escaping (String, String, Bool) -> Void
    ) {
        let trimmedKey = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            completion(fallbackStoryTheme(from: userPrompt), "Fallback", false)
            return
        }
        
        var request = URLRequest(url: groqEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Convert the user's request into a concise 2 to 5 word story theme.
        
        Rules:
        - Return only the theme
        - Use title case unless an acronym should stay uppercase
        - Remove framing words like "Explain", "Layman", "Beginner", "Tell me about", and "What is"
        - Prefer themes like "US-Iran Conflict", "OpenAI Revenue Push", or "India Startup Funding"
        
        User request:
        \(userPrompt)
        """
        
        let body: [String: Any] = [
            "model": groqModel,
            "messages": [
                ["role": "system", "content": "You turn long prompts into concise story themes."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1,
            "max_tokens": 40
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(fallbackStoryTheme(from: userPrompt), "Fallback", false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data else {
                DispatchQueue.main.async {
                    completion(self.fallbackStoryTheme(from: userPrompt), "Fallback", false)
                }
                return
            }
            
            do {
                if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                    DispatchQueue.main.async {
                        completion(self.fallbackStoryTheme(from: userPrompt), "Fallback: \(apiError.error.message)", false)
                    }
                    return
                }
                
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let rawTheme = decoded.choices.first?.message.content ?? ""
                let cleanedTheme = self.cleanTheme(rawTheme, fallbackPrompt: userPrompt)
                
                DispatchQueue.main.async {
                    completion(cleanedTheme, "Groq Llama-3.3", true)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(self.fallbackStoryTheme(from: userPrompt), "Fallback: decode failed", false)
                }
            }
        }.resume()
    }
    
    private func extractBullets(from text: String) -> [String] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let cleaned = lines.map { line in
            line
                .replacingOccurrences(of: "• ", with: "")
                .replacingOccurrences(of: "- ", with: "")
                .replacingOccurrences(of: "* ", with: "")
                .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty && $0.count > 8 }
        
        return Array(cleaned.prefix(4))
    }
    
    private func fallbackBullets(from input: String) -> [String] {
        if isLimitedExtractionInput(input) {
            return limitedExtractionBullets()
        }
        
        let headline = section(named: "Headline", in: input)
        let subtitle = section(named: "Subheadline", in: input)
        let snippet = section(named: "Snippet", in: input)
        var body = section(named: "Article Body", in: input)
        
        if body.isEmpty {
            body = input
                .replacingOccurrences(of: "Extraction status: full article body", with: "")
                .replacingOccurrences(of: "URL:", with: "")
                .replacingOccurrences(of: "Headline:", with: "")
                .replacingOccurrences(of: "Subheadline:", with: "")
                .replacingOccurrences(of: "Snippet:", with: "")
                .replacingOccurrences(of: "Article Body:", with: "")
        }
        
        let repeatedFragments = [headline, subtitle, snippet]
            .map(normalizeComparisonText)
            .filter { !$0.isEmpty }
        
        let cleaned = body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                let normalizedLine = normalizeComparisonText(line)
                return line.count > 30 && !repeatedFragments.contains(normalizedLine)
            }
            .joined(separator: " ")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let sentences = cleaned
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 35 }
        
        var seen = Set<String>()
        let bullets = sentences.filter { sentence in
            let normalized = normalizeComparisonText(sentence)
            guard !normalized.isEmpty, !seen.contains(normalized) else {
                return false
            }
            seen.insert(normalized)
            return true
        }
        
        let trimmedBullets = Array(bullets.prefix(3))
        return trimmedBullets.isEmpty ? limitedExtractionBullets() : trimmedBullets
    }
    
    private func isLimitedExtractionInput(_ input: String) -> Bool {
        input.localizedCaseInsensitiveContains("Extraction status: limited article text")
    }
    
    private func limitedExtractionBullets() -> [String] {
        [
            "Detailed summary unavailable because the article body could not be extracted reliably.",
            "Open the full article for context."
        ]
    }
    
    private func section(named name: String, in input: String) -> String {
        let markers = [
            "Extraction status:",
            "URL:",
            "Headline:",
            "Subheadline:",
            "Snippet:",
            "Article Body:"
        ]
        
        guard let startRange = input.range(of: "\(name):") else {
            return ""
        }
        
        let sectionStart = startRange.upperBound
        let remainder = String(input[sectionStart...])
        let nextMarker = markers
            .filter { $0 != "\(name):" }
            .compactMap { marker -> Range<String.Index>? in
                remainder.range(of: marker)
            }
            .min(by: { $0.lowerBound < $1.lowerBound })
        
        let rawValue: String
        if let nextMarker {
            rawValue = String(remainder[..<nextMarker.lowerBound])
        } else {
            rawValue = remainder
        }
        
        return rawValue
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func normalizeComparisonText(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseStoryPayload(
        from raw: String,
        fallbackTopic: String,
        userPrompt: String,
        researchInput: String,
        sourceReferences: [StorySourceReference],
        existingStory: Story?
    ) -> StoryResearchPayload {
        let candidate = extractJSONObject(from: raw) ?? raw
        
        if let data = candidate.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(StoryResearchPayload.self, from: data) {
            return decoded.sanitized(fallbackTopic: fallbackTopic)
        }
        
        return fallbackStoryPayload(topic: fallbackTopic, userPrompt: userPrompt, from: researchInput, sourceReferences: sourceReferences, existingStory: existingStory)
    }
    
    private func extractJSONObject(from text: String) -> String? {
        if let fencedRange = text.range(of: "```json") {
            let trailing = text[fencedRange.upperBound...]
            if let endRange = trailing.range(of: "```") {
                return String(trailing[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        guard let startIndex = text.firstIndex(of: "{"),
              let endIndex = text.lastIndex(of: "}") else {
            return nil
        }
        
        return String(text[startIndex...endIndex])
    }
    
    private func fallbackStoryPayload(
        topic: String,
        userPrompt: String,
        from researchInput: String,
        sourceReferences: [StorySourceReference],
        existingStory: Story?
    ) -> StoryResearchPayload {
        let bestSnippet = extractBestSnippet(from: researchInput)
            ?? existingStory?.overview
            ?? "Reliable reporting has been gathered, but a full explainer is still being assembled."
        let citedPublishers = Array(NSOrderedSet(array: sourceReferences.map(\.sourceName)).array as? [String] ?? [])
        let sourceTitles = sourceReferences.prefix(3).map(\.title)
        let citationNote = citedPublishers.isEmpty ? "reputable coverage" : citedPublishers.joined(separator: ", ")
        let timelineFallback = sourceTitles.map { "Recent coverage: \($0)" }
        
        return StoryResearchPayload(
            title: existingStory?.title ?? topic,
            overview: bestSnippet,
            simpleExplanation: existingStory?.simpleExplanation ?? [
                "\(topic) is an active story being tracked across \(citationNote).",
                "This card turns the latest reliable coverage into a simpler plain-English explainer."
            ],
            keyTerms: existingStory?.keyTerms ?? [],
            timeline: existingStory?.timeline ?? timelineFallback,
            keyFacts: sourceTitles.isEmpty ? (existingStory?.keyFacts ?? []) : sourceTitles,
            stakeholderGoals: existingStory?.stakeholderGoals ?? [],
            globalImpact: existingStory?.globalImpact ?? [],
            indiaImpact: existingStory?.indiaImpact ?? [],
            whyItMatters: existingStory?.whyItMatters ?? [
                "\(topic) matters because it can affect security, diplomacy, markets, and public understanding."
            ],
            watchFor: existingStory?.watchFor ?? [
                "Watch for fresh reporting, official comments, or new numbers tied to \(topic)."
            ],
            scenarios: existingStory?.scenarios ?? [],
            verificationNotes: [
                "This story is using a fallback explainer because the richer AI response was unavailable.",
                citedPublishers.isEmpty ? "Open cited articles before relying on specific claims." : "Current cited publishers: \(citationNote)."
            ]
        ).sanitized(fallbackTopic: topic)
    }
    
    private func cleanTheme(_ rawTheme: String, fallbackPrompt: String) -> String {
        let stripped = rawTheme
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "(?i)\\b(layman|beginner|explain|explained|tell me about|what is|about)\\b", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if stripped.isEmpty {
            return fallbackStoryTheme(from: fallbackPrompt)
        }
        
        let normalized = normalizeThemeCandidate(stripped)
        return String(normalized.prefix(60))
    }
    
    private func fallbackStoryTheme(from userPrompt: String) -> String {
        let stopWords: Set<String> = [
            "what", "why", "how", "tell", "me", "about", "latest", "on", "the",
            "a", "an", "for", "of", "to", "is", "are", "should", "could", "would",
            "explain", "research", "understand", "news", "layman", "beginner", "simple"
        ]
        
        let tokens = userPrompt
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty && !stopWords.contains($0) }
        
        let selected = Array(tokens.prefix(4))
        guard !selected.isEmpty else {
            return "Story Brief"
        }
        
        let uppercaseTerms: Set<String> = ["ai", "us", "uk", "ipo", "api", "llm", "eu", "uae"]
        let baseTheme = selected.map { token in
            uppercaseTerms.contains(token) ? token.uppercased() : token.capitalized
        }.joined(separator: " ")
        
        return normalizeThemeCandidate(baseTheme)
    }
    
    private func normalizeThemeCandidate(_ candidate: String) -> String {
        let cleaned = candidate
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let lowered = cleaned.lowercased()
        if lowered.contains("iran") && lowered.contains("us") {
            return "US-Iran Conflict"
        }
        if lowered.contains("iran") && lowered.contains("israel") {
            return "Iran-Israel Conflict"
        }
        
        return cleaned
    }
    
    private func extractBestSnippet(from researchInput: String) -> String? {
        let pattern = #"Search snippet:\s*(.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(researchInput.startIndex..., in: researchInput)
        let matches = regex.matches(in: researchInput, options: [], range: range)
        
        for match in matches {
            guard match.numberOfRanges > 1,
                  let snippetRange = Range(match.range(at: 1), in: researchInput) else {
                continue
            }
            
            let snippet = String(researchInput[snippetRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if snippet.count > 40 && !snippet.lowercased().contains("google news") {
                return snippet
            }
        }
        
        return nil
    }
}
