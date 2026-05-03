import Foundation

struct Topic: Identifiable, Codable {
    var id = UUID()   // ✅ make it var
    let name: String
}
