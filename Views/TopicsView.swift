import SwiftUI

struct TopicsView: View {
    
    @ObservedObject var topicManager: TopicManager
    @State private var newTopic: String = ""
    
    var body: some View {
        VStack {
            
            // Add Topic
            HStack {
                TextField("Add topic (e.g. AI, IPO)", text: $newTopic)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    topicManager.addTopic(newTopic)
                    newTopic = ""
                }
            }
            .padding()
            
            // Topic List
            List {
                ForEach(topicManager.topics, id: \.self) { topic in
                    Text(topic)
                }
                .onDelete(perform: topicManager.removeTopic)
            }
        }
        .navigationTitle("Your Topics")
    }
}
