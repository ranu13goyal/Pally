import Foundation

enum LearningMockData {
    static let cards: [SummaryCard] = [
        SummaryCard(
            id: "ai-agents-economics",
            topic: .techAI,
            title: "Why AI agents are becoming the next software interface",
            whyItMatters: "AI agents could change how work gets done by turning software from tools you click into systems you delegate to.",
            bulletSummary: [
                "AI agents aim to complete multi-step tasks, not just answer one question.",
                "The winning products will likely combine models, workflows, permissions, and memory.",
                "Most current agent products are still brittle in messy real-world environments.",
                "Businesses care less about novelty and more about reliability, auditability, and saved labor.",
                "The market may shift from chatbot wrappers to workflow-specific AI coworkers."
            ],
            keyConceptTitle: "Agent reliability",
            keyConceptExplanation: "An AI agent is only useful when it can finish a task repeatedly with clear boundaries, tools, and fail-safes.",
            sourceName: "The Economist",
            sourceURL: "https://www.economist.com/",
            estimatedReadingMinutes: 4,
            difficulty: .intermediate,
            publishedAt: Date().addingTimeInterval(-7200)
        ),
        SummaryCard(
            id: "fed-soft-landing",
            topic: .economics,
            title: "What a soft landing actually means in the economy",
            whyItMatters: "A soft landing affects jobs, markets, borrowing costs, and how painful inflation control feels for everyday people.",
            bulletSummary: [
                "A soft landing means inflation cools without causing a deep recession.",
                "Central banks try to slow demand carefully rather than crush it.",
                "Labor markets are the key signal because unemployment often rises late.",
                "Investors watch wages, services inflation, and credit conditions for clues.",
                "Soft landings are hard because policy works with a delay."
            ],
            keyConceptTitle: "Policy lag",
            keyConceptExplanation: "Interest-rate changes affect the economy gradually, so central banks often react before the full effect is visible.",
            sourceName: "Financial Times",
            sourceURL: "https://www.ft.com/",
            estimatedReadingMinutes: 3,
            difficulty: .beginner,
            publishedAt: Date().addingTimeInterval(-10800)
        ),
        SummaryCard(
            id: "middle-east-shipping",
            topic: .geopolitics,
            title: "Why shipping chokepoints can move global markets fast",
            whyItMatters: "A disruption in one narrow corridor can quickly change oil prices, insurance costs, trade routes, and inflation.",
            bulletSummary: [
                "Global trade depends heavily on a few critical maritime passages.",
                "Conflict or sabotage near a chokepoint can delay cargo and raise costs immediately.",
                "Energy markets react quickly because traders price future supply risk.",
                "Governments often weigh military, diplomatic, and economic responses together.",
                "The economic effect can spread far beyond the original region."
            ],
            keyConceptTitle: "Chokepoint risk",
            keyConceptExplanation: "A chokepoint is a narrow route where disruption can affect a much larger network around it.",
            sourceName: "Reuters",
            sourceURL: "https://www.reuters.com/",
            estimatedReadingMinutes: 5,
            difficulty: .beginner,
            publishedAt: Date().addingTimeInterval(-14400)
        ),
        SummaryCard(
            id: "roman-republic",
            topic: .history,
            title: "How the Roman Republic drifted into empire",
            whyItMatters: "It is a classic example of how institutions can weaken when military power, elite competition, and public trust pull in different directions.",
            bulletSummary: [
                "Rome expanded quickly and became harder to govern with older political norms.",
                "Military leaders gained personal loyalty from armies and used it politically.",
                "Economic inequality and elite rivalry made reform more unstable.",
                "Short-term emergency decisions slowly changed long-term power structures.",
                "Augustus kept many republican forms while centralizing real authority."
            ],
            keyConceptTitle: "Institutional drift",
            keyConceptExplanation: "Institutions can keep their old names and rituals even while real power shifts elsewhere.",
            sourceName: "History Today",
            sourceURL: "https://www.historytoday.com/",
            estimatedReadingMinutes: 4,
            difficulty: .intermediate,
            publishedAt: Date().addingTimeInterval(-21600)
        ),
        SummaryCard(
            id: "dopamine-habits",
            topic: .psychology,
            title: "What people get wrong about dopamine and motivation",
            whyItMatters: "Misunderstanding dopamine leads people to oversimplify habit change, addiction, focus, and reward-seeking behavior.",
            bulletSummary: [
                "Dopamine is more tied to motivation and learning than simple pleasure.",
                "Anticipation of reward often matters more than the reward itself.",
                "Habits strengthen when cues, routines, and rewards repeat together.",
                "Variable rewards can make behaviors especially sticky.",
                "Better systems beat raw willpower in long-term behavior change."
            ],
            keyConceptTitle: "Reward prediction",
            keyConceptExplanation: "Brains learn not just from rewards, but from whether outcomes are better or worse than expected.",
            sourceName: "NPR",
            sourceURL: "https://www.npr.org/",
            estimatedReadingMinutes: 3,
            difficulty: .beginner,
            publishedAt: Date().addingTimeInterval(-25200)
        ),
        SummaryCard(
            id: "protein-folding",
            topic: .science,
            title: "Why protein folding matters far beyond biology class",
            whyItMatters: "Better understanding proteins can speed up drug discovery, disease research, and how scientists model living systems.",
            bulletSummary: [
                "Proteins do different jobs based on their three-dimensional shape.",
                "Predicting shape from sequence used to be a major scientific bottleneck.",
                "AI models accelerated prediction and changed research workflows.",
                "Predictions still need validation because biology happens in complex environments.",
                "The biggest gains may come from combining computation with lab experiments."
            ],
            keyConceptTitle: "Structure-function link",
            keyConceptExplanation: "In biology, what something does often depends on the exact shape it takes.",
            sourceName: "Nature",
            sourceURL: "https://www.nature.com/",
            estimatedReadingMinutes: 4,
            difficulty: .intermediate,
            publishedAt: Date().addingTimeInterval(-28800)
        ),
        SummaryCard(
            id: "brand-culture-memes",
            topic: .culture,
            title: "Why brands talk like creators on the internet now",
            whyItMatters: "Culture now moves through feeds, and brands that sound too corporate often lose attention before they earn trust.",
            bulletSummary: [
                "Social platforms reward speed, personality, and recognizably human tone.",
                "Brands borrow creator language to feel native to the feed.",
                "The strategy works only when the voice matches the brand’s actual identity.",
                "Meme fluency can create attention but also increase backlash risk.",
                "The best brand voices are distinct, not just trend-chasing."
            ],
            keyConceptTitle: "Platform-native communication",
            keyConceptExplanation: "Messages perform better when they fit the style and rhythm of the place where they appear.",
            sourceName: "The Guardian",
            sourceURL: "https://www.theguardian.com/",
            estimatedReadingMinutes: 3,
            difficulty: .beginner,
            publishedAt: Date().addingTimeInterval(-32400)
        ),
        SummaryCard(
            id: "capital-allocation",
            topic: .business,
            title: "Why capital allocation is one of the most important CEO skills",
            whyItMatters: "Good capital allocation shapes growth, resilience, and long-term returns even more than flashy product narratives.",
            bulletSummary: [
                "Capital allocation decides where a company puts money, talent, and management attention.",
                "Choices include reinvestment, acquisitions, debt reduction, buybacks, and cash reserves.",
                "The best leaders compare expected returns across multiple uses of capital.",
                "Poor allocation can hide behind revenue growth for years before problems show up.",
                "Discipline matters most when markets are optimistic and money feels easy."
            ],
            keyConceptTitle: "Opportunity cost",
            keyConceptExplanation: "Every rupee or dollar spent one way cannot be spent on a potentially better option.",
            sourceName: "Bloomberg",
            sourceURL: "https://www.bloomberg.com/",
            estimatedReadingMinutes: 4,
            difficulty: .intermediate,
            publishedAt: Date().addingTimeInterval(-36000)
        )
    ]
    
    static let quizzes: [String: Quiz] = [
        "ai-agents-economics": Quiz(
            id: "quiz-ai-agents-economics",
            cardID: "ai-agents-economics",
            topic: .techAI,
            questions: [
                QuizQuestion(
                    type: .recall,
                    prompt: "What makes an AI agent different from a one-shot chatbot?",
                    options: [
                        "It only works offline",
                        "It completes multi-step tasks",
                        "It always uses voice",
                        "It is only for coding"
                    ],
                    correctAnswerIndex: 1,
                    explanation: "The card highlights that agents try to complete multi-step tasks instead of just answering once."
                ),
                QuizQuestion(
                    type: .concept,
                    prompt: "Why is reliability central to agent products?",
                    options: [
                        "Because the best model is always the cheapest",
                        "Because businesses need repeatable outcomes with safeguards",
                        "Because agents replace every employee immediately",
                        "Because users prefer long answers"
                    ],
                    correctAnswerIndex: 1,
                    explanation: "Reliable boundaries, tools, and fail-safes are what make delegation practical."
                ),
                QuizQuestion(
                    type: .application,
                    prompt: "If an operations team wants an AI agent, what should they prioritize first?",
                    options: [
                        "A fun avatar",
                        "More temperature and creativity",
                        "Auditability and workflow control",
                        "Publishing the product on social media"
                    ],
                    correctAnswerIndex: 2,
                    explanation: "The card says the market values reliable workflow execution over novelty."
                )
            ],
            generatedAt: Date()
        ),
        "middle-east-shipping": Quiz(
            id: "quiz-middle-east-shipping",
            cardID: "middle-east-shipping",
            topic: .geopolitics,
            questions: [
                QuizQuestion(
                    type: .recall,
                    prompt: "What is a chokepoint in global trade?",
                    options: [
                        "A new tax on imports",
                        "A narrow route where disruption has outsized impact",
                        "A port with low traffic",
                        "A country that bans shipping"
                    ],
                    correctAnswerIndex: 1,
                    explanation: "The card defines chokepoint risk as disruption in a narrow route affecting a larger network."
                ),
                QuizQuestion(
                    type: .concept,
                    prompt: "Why do oil markets react quickly to chokepoint tension?",
                    options: [
                        "Because traders price future supply risk",
                        "Because shipping is unrelated to energy",
                        "Because governments stop reporting prices",
                        "Because oil can only be sold locally"
                    ],
                    correctAnswerIndex: 0,
                    explanation: "The market moves quickly because it is pricing the risk of future shortages."
                ),
                QuizQuestion(
                    type: .application,
                    prompt: "If insurance costs surge near a key sea route, what is a likely next effect?",
                    options: [
                        "Lower inflation immediately",
                        "Cheaper freight everywhere",
                        "Higher trade costs spreading beyond the region",
                        "No impact outside the conflict zone"
                    ],
                    correctAnswerIndex: 2,
                    explanation: "The card notes the economic effect can spread far beyond the original region."
                )
            ],
            generatedAt: Date()
        )
    ]
}
