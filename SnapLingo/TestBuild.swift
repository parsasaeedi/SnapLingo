import Foundation
import SwiftUI
import SwiftData
import Combine

// Test file to verify our fixes work
struct TestBuild {
    static func testCompilation() {
        // Test that our models can be instantiated
        let session = GameSession(environment: "Home")
        let item = GameItem(name: "Test", emoji: "🧪", sessionId: session.id)
        let progress = UserProgress()
        
        // Test that our environment works
        let homeEnv = GameEnvironment.home
        let randomItems = homeEnv.randomItems
        let emoji = homeEnv.emoji(for: "Spoon")
        
        // Test that GameManager can be created
        let gameManager = GameManager()
        
        // Test that CameraService can be created
        let cameraService = CameraService()
        
        print("✅ All components compile successfully!")
        print("Session: \(session.environment)")
        print("Item: \(item.name)")
        print("Home environment has \(homeEnv.items.count) items")
        print("Random items: \(randomItems.count)")
        print("Spoon emoji: \(emoji)")
    }
}

// Remove the top-level expression that was causing the error
// The test can be called from elsewhere if needed
