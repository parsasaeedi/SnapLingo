import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class GameManager: ObservableObject {
    @Published var currentSession: GameSession?
    @Published var currentItemIndex = 0
    @Published var timeRemaining: TimeInterval = 15.0
    @Published var isGameActive = false
    @Published var showItemNotFound = false
    @Published var showItemFound = false
    @Published var showGameComplete = false
    @Published var currentScore = 0
    @Published var currentStreak = 0
    
    private var timer: Timer?
    private let maxTime: TimeInterval = 15.0
    private let perfectBonusWindow: TimeInterval = 5.0
    private let perfectBonusPoints = 50
    private let basePoints = 50
    
    var currentItem: GameItem? {
        guard let session = currentSession,
              currentItemIndex < session.items.count else { return nil }
        return session.items[currentItemIndex]
    }
    
    var progress: Double {
        guard let session = currentSession else { return 0.0 }
        return Double(currentItemIndex) / Double(session.items.count)
    }
    
    var timerColor: Color {
        if timeRemaining > 10 {
            return .primary
        } else if timeRemaining > 5 {
            return .orange
        } else {
            return .red
        }
    }
    
    func startSession(environment: String, modelContext: ModelContext) {
        let session = GameSession(environment: environment)
        let env = GameEnvironment.environments.first { $0.name == environment } ?? GameEnvironment.home
        
        // Select 12 random items for the session
        let shuffledItems = env.items.shuffled()
        let selectedItems = Array(shuffledItems.prefix(12))
        
        for itemName in selectedItems {
            let emoji = env.emojis[itemName] ?? "❓"
            let gameItem = GameItem(name: itemName, emoji: emoji, sessionId: session.id)
            session.items.append(gameItem)
        }
        
        currentSession = session
        currentItemIndex = 0
        currentScore = 0
        currentStreak = 0
        isGameActive = true
        startTimer()
        
        modelContext.insert(session)
    }
    
    func startTimer() {
        timeRemaining = maxTime
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    func updateTimer() {
        guard isGameActive else { return }
        
        timeRemaining -= 1.0
        
        // Haptic feedback at specific times
        if timeRemaining == 5 || timeRemaining == 3 || timeRemaining == 1 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        if timeRemaining <= 0 {
            timeExpired()
        }
    }
    
    func capturePhoto() {
        guard let currentItem = currentItem else { return }
        
        // Simulate object detection (in a real app, this would use Vision and Core ML)
        let detected = simulateObjectDetection(for: currentItem.name)
        
        if detected {
            itemFound()
        } else {
            itemNotFound()
        }
    }
    
    private func simulateObjectDetection(for itemName: String) -> Bool {
        // Simulate 70% success rate for demo purposes
        // In a real app, this would use Vision and Core ML for actual object detection
        return Double.random(in: 0...1) < 0.7
    }
    
    func itemFound() {
        guard let currentItem = currentItem else { return }
        
        timer?.invalidate()
        
        let timeUsed = maxTime - timeRemaining
        var points = basePoints
        
        // Perfect bonus for finding within first 5 seconds
        if timeUsed <= perfectBonusWindow {
            points += perfectBonusPoints
        }
        
        // Time bonus (faster = more points)
        let timeBonus = Int((maxTime - timeUsed) / maxTime * 50)
        points += timeBonus
        
        currentScore += points
        currentStreak += 1
        currentItem.found = true
        currentItem.timeToFind = timeUsed
        
        showItemFound = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.nextItem()
        }
    }
    
    func itemNotFound() {
        showItemNotFound = true
        currentStreak = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showItemNotFound = false
        }
    }
    
    func timeExpired() {
        guard let currentItem = currentItem else { return }
        
        timer?.invalidate()
        currentStreak = 0
        currentItem.found = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.nextItem()
        }
    }
    
    func nextItem() {
        showItemFound = false
        showItemNotFound = false
        
        currentItemIndex += 1
        
        if currentItemIndex >= (currentSession?.items.count ?? 0) {
            endSession()
        } else {
            startTimer()
        }
    }
    
    func endSession() {
        timer?.invalidate()
        isGameActive = false
        showGameComplete = true
        
        if let session = currentSession {
            session.endTime = Date()
            session.score = currentScore
            session.streak = currentStreak
        }
    }
    
    func resetGame() {
        timer?.invalidate()
        currentSession = nil
        currentItemIndex = 0
        timeRemaining = maxTime
        isGameActive = false
        showItemNotFound = false
        showItemFound = false
        showGameComplete = false
        currentScore = 0
        currentStreak = 0
    }
    
    func skipCurrentItem() {
        guard let currentItem = currentItem else { return }
        
        timer?.invalidate()
        currentStreak = 0
        currentItem.found = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.nextItem()
        }
    }
}
