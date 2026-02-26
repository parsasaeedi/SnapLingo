import Foundation
import SwiftUI
import UIKit
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
    @Published var showSkipOverlay = false
    @Published var currentScore = 0
    @Published var currentStreak = 0
    
    private var timer: Timer?
    private var isProcessingDecision = false
    private var hasScheduledAdvance = false
    private var pendingAdvance: DispatchWorkItem?
    private let classifier = ImageClassificationService()
    private let verifier = ObjectVerificationService()
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
    
    func startSession(environment: String, items: [Item]? = nil, modelContext: ModelContext) {
        cancelPendingAdvance()
        let key = environment.replacingOccurrences(of: " ", with: "_").lowercased()
        let session = GameSession(environment: key)

        var itemsForEnv: [Item]
        if let items, !items.isEmpty {
            itemsForEnv = items
        } else {
            itemsForEnv = CatalogStore.shared.catalog.environments[key] ?? []
            if itemsForEnv.isEmpty {
                CatalogStore.shared.load()
                itemsForEnv = CatalogStore.shared.catalog.environments[key] ?? []
            }
        }

        let ordered = itemsForEnv.shuffled()
        for item in ordered {
            let gameItem = GameItem(name: item.word, emoji: item.emoji, sessionId: session.id)
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

    func handleShutter(image: UIImage, environmentKey: String) {
        let key = environmentKey.replacingOccurrences(of: " ", with: "_").lowercased()
        classifier.classify(image: image, topK: 10) { [weak self] results in
            guard let self = self else { return }
            if !results.isEmpty {
                let formatted = results.map { "\($0.identifier) (\(String(format: "%.2f", $0.confidence)))" }.joined(separator: ", ")
                print("[Classifier] Results: \(formatted)")
            }

            guard let currentWord = self.currentItem?.name else {
                self.itemNotFound()
                return
            }

            let catalogItems = CatalogStore.shared.items(in: key)
            if let item = catalogItems.first(where: { $0.word == currentWord }) {
                let preds = results.asClassifications()
                let verification = self.verifier.verifyAndLog(
                    modelLabels: item.model_label,
                    predictions: preds,
                    options: VerificationOptions(topK: 10, minConfidence: 0.4, enableFuzzy: true)
                )
                if verification.isMatch {
                    self.itemFound()
                } else {
                    self.itemNotFound()
                }
            } else {
                print("[Verify] No catalog item found for word: \(currentWord)")
                self.itemNotFound()
            }
        }
    }
    
    func startTimer(remaining: TimeInterval? = nil) {
        timeRemaining = remaining ?? maxTime
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                self?.updateTimer()
            }
        }
    }
    
    func updateTimer() {
        guard isGameActive else { return }
        guard !isProcessingDecision else { return }
        
        timeRemaining -= 1.0
        
        if timeRemaining == 3 || timeRemaining == 2 || timeRemaining == 1 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        if timeRemaining <= 0 {
            timeExpired()
        }
    }
    
    func itemFound() {
        guard !isProcessingDecision else { return }
        isProcessingDecision = true
        guard let currentItem = currentItem else { return }
        
        timer?.invalidate()
        
        let timeUsed = maxTime - timeRemaining
        var points = basePoints
        
        if timeUsed <= perfectBonusWindow {
            points += perfectBonusPoints
        }
        
        let timeBonus = Int((maxTime - timeUsed) / maxTime * 50)
        points += timeBonus
        
        currentScore += points
        currentStreak += 1
        currentItem.found = true
        currentItem.timeToFind = timeUsed
        
        showItemFound = true
        
        scheduleAdvance(after: 1.5)
    }
    
    func itemNotFound() {
        guard !isProcessingDecision else { return }
        isProcessingDecision = true
        let remaining = timeRemaining
        timer?.invalidate()
        showItemNotFound = true
        currentStreak = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showItemNotFound = false
            if self.isGameActive {
                self.isProcessingDecision = false
                self.startTimer(remaining: max(1.0, remaining))
            } else {
                self.isProcessingDecision = false
            }
        }
    }
    
    func timeExpired() {
        guard !isProcessingDecision else { return }
        isProcessingDecision = true
        guard let currentItem = currentItem else { return }
        
        timer?.invalidate()
        currentStreak = 0
        currentItem.found = false
        
        scheduleAdvance(after: 2.0)
    }
    
    func skipCurrentItem() {
        guard !isProcessingDecision else { return }
        isProcessingDecision = true
        guard let currentItem = currentItem else { return }
        
        timer?.invalidate()
        currentStreak = 0
        currentItem.found = false
        showSkipOverlay = true
        
        scheduleAdvance(after: 2.0)
    }
    
    func nextItem() {
        isProcessingDecision = false
        hasScheduledAdvance = false
        showItemFound = false
        showItemNotFound = false
        showSkipOverlay = false
        
        currentItemIndex += 1
        
        if currentItemIndex >= (currentSession?.items.count ?? 0) {
            endSession()
        } else {
            startTimer()
        }
    }

    private func scheduleAdvance(after delay: TimeInterval) {
        cancelPendingAdvance()
        hasScheduledAdvance = true
        let work = DispatchWorkItem { [weak self] in
            self?.nextItem()
        }
        pendingAdvance = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func cancelPendingAdvance() {
        pendingAdvance?.cancel()
        pendingAdvance = nil
        hasScheduledAdvance = false
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
        showSkipOverlay = false
        currentScore = 0
        currentStreak = 0
    }
}
