import SwiftUI
import SwiftData
import AVFoundation

struct GameSessionView: View {
    let environment: String
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    var body: some View {
        ZStack {
            // Camera Background (simulated)
            CameraBackgroundView()
            
            // Game UI Overlay
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                Spacer()
                
                // Center Content
                centerContent
                
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
        }
        .onAppear {
            gameManager.startSession(environment: environment, modelContext: modelContext)
        }
        .onDisappear {
            gameManager.resetGame()
        }
    }
    
    private var topBar: some View {
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
            
            // Search Target
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text(gameManager.currentItem?.name ?? "")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
            )
            
            Spacer()
            
            // Timer
            HStack(spacing: 4) {
                Image(systemName: "stopwatch")
                Text("\(Int(gameManager.timeRemaining))s")
                    .fontWeight(.bold)
            }
            .foregroundColor(gameManager.timerColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var centerContent: some View {
        VStack(spacing: 20) {
            // Progress Bar
            ProgressView(value: gameManager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal)
            
            // Current Item Display
            if let currentItem = gameManager.currentItem {
                VStack(spacing: 12) {
                    Text("Find this object:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(currentItem.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Streak Display
            if gameManager.currentStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Streak: \(gameManager.currentStreak)")
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
        }
    }
    
    private var bottomControls: some View {
        HStack {
            // Cancel Button
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
            
            // Shutter Button
            Button(action: {
                gameManager.capturePhoto()
            }) {
                Circle()
                    .fill(.white)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(.blue, lineWidth: 4)
                    )
            }
            
            Spacer()
            
            // Next Button (placeholder)
            Button(action: {
                // Could be used for hints or skip
            }) {
                Image(systemName: "chevron.right")
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
    var body: some View {
        ZStack {
            // Simulated camera view
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Simulated camera elements
            VStack {
                Spacer()
                
                HStack {
                    // Simulated furniture
                    Rectangle()
                        .fill(Color.brown.opacity(0.3))
                        .frame(width: 100, height: 200)
                        .overlay(
                            Text("Chair")
                                .font(.caption)
                                .foregroundColor(.brown)
                        )
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.brown.opacity(0.3))
                        .frame(width: 150, height: 80)
                        .overlay(
                            Text("Table")
                                .font(.caption)
                                .foregroundColor(.brown)
                        )
                }
                .padding(.horizontal, 50)
                
                Spacer()
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
