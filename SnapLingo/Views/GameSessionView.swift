import SwiftUI
import SwiftData
import AVFoundation

struct GameSessionView: View {
    let environment: String
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @StateObject private var cameraService = CameraService()
    
    var body: some View {
        ZStack {
            // Camera Background
            CameraBackgroundView(cameraService: cameraService)
            
            // Game UI Overlay
            VStack(spacing: 0) {
                // Top Bar with Progress
                topBar
                
                Spacer()
                
                // Bottom Controls
                bottomControls
            }
            .padding()
            
            // Overlays
            if gameManager.showItemNotFound {
                itemNotFoundOverlay
            }
            
            if gameManager.showItemFound {
                itemFoundOverlay
            }
            
            if gameManager.showGameComplete {
                gameCompleteOverlay
            }
            
            // Timer expired overlay
            if gameManager.timeRemaining <= 0 && gameManager.isGameActive {
                timerExpiredOverlay
            }
        }
        .onAppear {
            gameManager.startSession(environment: environment, modelContext: modelContext)
            cameraService.startSession()
        }
        .onDisappear {
            gameManager.resetGame()
            cameraService.stopSession()
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 16) {
            // Top Row: Score, Timer, Progress
            HStack {
                // Trophy and Score
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(gameManager.currentScore)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                
                Spacer()
                
                // Timer (centered with fixed width)
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch")
                    Text("\(Int(gameManager.timeRemaining))s")
                        .fontWeight(.bold)
                        .frame(minWidth: 30, alignment: .leading)
                }
                .foregroundColor(gameManager.timerColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .frame(width: 80) // Fixed width for consistent positioning
                
                Spacer()
                
                // Progress with Flag
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                    Text("\(gameManager.currentItemIndex + 1)/\(gameManager.currentSession?.items.count ?? 0)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Search Target (bigger prompt)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text(gameManager.currentItem?.name ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Streak Display (above shutter button)
            if gameManager.currentStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("streak: \(gameManager.currentStreak)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Control Buttons
            HStack {
                // Exit Button (bottom left)
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                
                Spacer()
                
                // Shutter Button (two circles design)
                Button(action: {
                    gameManager.capturePhoto()
                }) {
                    ZStack {
                        // Outer circle - white frosted glass
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                        
                        // Inner circle - solid white
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    }
                }
                
                Spacer()
                
                // Skip Button (bottom right)
                Button(action: {
                    gameManager.skipCurrentItem()
                }) {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
        }
        .padding(.bottom, 50)
    }
    
    private var timerExpiredOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                if let currentItem = gameManager.currentItem {
                    // Show emoji or SF symbol
                    if currentItem.emoji != "❓" {
                        Text(currentItem.emoji)
                            .font(.system(size: 80))
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    
                    Text("Time's up!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("The answer was: \(currentItem.name)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Auto-advance after showing the answer
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                gameManager.nextItem()
            }
        }
    }
    
    private var itemNotFoundOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Item not found!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Try again or wait for the timer to see the answer")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .ignoresSafeArea()
    }
    
    private var itemFoundOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Perfect!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let currentItem = gameManager.currentItem,
                   let timeUsed = currentItem.timeToFind {
                    let points = calculatePoints(timeUsed: timeUsed)
                    Text("+\(points) points")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var gameCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
            
            VStack(spacing: 30) {
                // Trophy Icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                // Results
                VStack(spacing: 16) {
                    Text("Session Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Final Score: \(gameManager.currentScore)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let session = gameManager.currentSession {
                        let foundCount = session.items.filter { $0.found }.count
                        Text("Found \(foundCount) out of \(session.items.count) items")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Recap (simulated)
                VStack(spacing: 12) {
                    Text("Session Recap")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Great job! You showed excellent speed in finding common household items. Keep practicing to improve your vocabulary!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                
                // Continue Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Continue")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.blue)
                        )
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .ignoresSafeArea()
    }
    
    private func calculatePoints(timeUsed: TimeInterval) -> Int {
        let basePoints = 50
        let perfectBonus = timeUsed <= 5 ? 50 : 0
        let timeBonus = Int((15 - timeUsed) / 15 * 50)
        return basePoints + perfectBonus + timeBonus
    }
}

struct CameraBackgroundView: View {
    let cameraService: CameraService
    
    var body: some View {
        ZStack {
            if cameraService.isAuthorized {
                // Real camera preview would go here
                // For now, using a gradient background
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                // Fallback background
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Camera access required")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GameSessionView(environment: "Home")
        .environmentObject(GameManager())
        .modelContainer(for: [GameSession.self, GameItem.self, UserProgress.self], inMemory: true)
}
