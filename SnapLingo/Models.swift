import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID
    var environment: String
    var startTime: Date
    var endTime: Date?
    var score: Int
    var items: [GameItem]
    var streak: Int
    
    init(environment: String) {
        self.id = UUID()
        self.environment = environment
        self.startTime = Date()
        self.score = 0
        self.items = []
        self.streak = 0
    }
}

@Model
final class GameItem {
    var id: UUID
    var name: String
    var emoji: String
    var found: Bool
    var timeToFind: TimeInterval?
    var sessionId: UUID
    
    init(name: String, emoji: String, sessionId: UUID) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.found = false
        self.sessionId = sessionId
    }
}

@Model
final class UserProgress {
    var id: UUID
    var totalScore: Int
    var totalSessions: Int
    var currentStreak: Int
    var longestStreak: Int
    var missedItems: [String]
    var lastPlayedDate: Date?
    
    init() {
        self.id = UUID()
        self.totalScore = 0
        self.totalSessions = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.missedItems = []
    }
}

struct Catalog: Codable {
    let environments: [String: [Item]]
}

struct Item: Codable, Identifiable {
    var id: String { word + "_" + (emoji) }
    let word: String
    let emoji: String
    let model_label: [String]
    let translations: [String: String]
}
