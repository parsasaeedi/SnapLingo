import Foundation
import SwiftData

// Simple test to verify our models work correctly
#if DEBUG
struct ModelTests {
    static func testModels() {
        // Test GameSession creation
        let session = GameSession(environment: "home")
        assert(session.environment == "home")
        assert(session.score == 0)
        assert(session.items.isEmpty)
        
        // Test GameItem creation
        let item = GameItem(name: "Spoon", emoji: "🥄", sessionId: session.id)
        assert(item.name == "Spoon")
        assert(item.emoji == "🥄")
        assert(!item.found)
        
        // Test UserProgress creation
        let progress = UserProgress()
        assert(progress.totalScore == 0)
        assert(progress.totalSessions == 0)
        assert(progress.currentStreak == 0)
        
        // Test CatalogStore
        let homeItems = CatalogStore.shared.catalog.environments["home"] ?? []
        assert(!homeItems.isEmpty)
        
        print("✅ All model tests passed!")
    }
}
#endif
