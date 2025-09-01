import SwiftUI
import SwiftData
import AVFoundation
import Combine
import AVFoundation  // make sure this import exists at the top

struct GameSessionView: View {
    let environment: String
    let initialItems: [Item]?
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @AppStorage("langCode") private var langCode: String = "en"
    @StateObject private var cameraService = CameraService()
    private let imageClassifier = ImageClassificationService()
    private let verifier = ObjectVerificationService()
    @State private var cameraStarted = false
    @State private var showCameraLoading = true
    
    init(environment: String, initialItems: [Item]? = nil) {
        self.environment = environment
        self.initialItems = initialItems
    }
    
    var body: some View {
        ZStack {
            // Camera Background
            CameraBackgroundView(cameraService: cameraService)
            
            // Loading overlay while camera initializes
            if showCameraLoading && cameraService.isAuthorized {
                Color.black.opacity(0.7)
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Initializing camera...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    )
                    .ignoresSafeArea()
            }
            
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
            
            // Skip overlay
            if gameManager.showSkipOverlay {
                skipOverlay
            }
        }
        .onAppear {
            // Start session, using pre-fetched items if provided; fallback to catalog
            let key = environment.replacingOccurrences(of: " ", with: "_").lowercased()
            let items = (initialItems?.isEmpty == false) ? initialItems : CatalogStore.shared.items(in: key)
            gameManager.startSession(environment: environment, items: items, modelContext: modelContext)
            // Start camera session after a brief delay to prevent UI freezing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !cameraStarted {
                    cameraService.startSession()
                    cameraStarted = true
                }
            }
        }
        .onReceive(cameraService.$isConfigured) { isConfigured in
            if isConfigured {
                showCameraLoading = false
            }
        }
        .onDisappear {
            gameManager.resetGame()
            cameraService.stopSession()
            cameraStarted = false
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
//                        .fill(.ultraThinMaterial)
                )
                .glassEffect()
                
                Spacer()
                
                // Timer (centered with fixed width and center-aligned text)
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch")
                    Text("\(Int(gameManager.timeRemaining))s")
                        .fontWeight(.bold)
                        .frame(minWidth: 30, alignment: .center)
                }
                .foregroundColor(gameManager.timerColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
//                        .fill(.ultraThinMaterial)
                )
                .frame(width: 80) // Fixed width for consistent positioning
                .glassEffect()
                
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
//                        .fill(.ultraThinMaterial)
                )
                .glassEffect()
            }
            
            // Search Target (bigger prompt)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text(displayName(for: gameManager.currentItem?.name))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
//                    .fill(.ultraThinMaterial)
            )
            .glassEffect()
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
                // Exit Button (bottom left with more padding)
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .frame(width: 50, height: 50)
                .contentShape(Circle())
                .buttonStyle(.plain)
                .glassEffect(in: .circle)
                .padding(.leading, 40)
                
                Spacer()
                
                // Shutter Button (larger two circles design)
                Button(action: {
                    cameraService.capturePhoto { image in
                        guard let image = image else { return }
                        imageClassifier.classify(image: image, topK: 10) { results in
                            // Feature requirement: print classifier output
                            if !results.isEmpty {
                                let formatted = results.map { "\($0.identifier) (\(String(format: "%.2f", $0.confidence)))" }.joined(separator: ", ")
                                print("[Classifier] Results: \(formatted)")
                            }

                            // Verify against the prompted item's model_label using catalog.json
                            if let currentWord = gameManager.currentItem?.name {
                                let key = environment.replacingOccurrences(of: " ", with: "_").lowercased()
                                let catalogItems = CatalogStore.shared.items(in: key)
                                if let item = catalogItems.first(where: { $0.word == currentWord }) {
                                    let preds = results.asClassifications()
                                    let verification = verifier.verifyAndLog(
                                        modelLabels: item.model_label,
                                        predictions: preds,
                                        options: VerificationOptions(topK: 10, minConfidence: 0.4, enableFuzzy: true)
                                    )
                                    if verification.isMatch {
                                        gameManager.itemFound()
                                    } else {
                                        gameManager.itemNotFound()
                                    }
                                } else {
                                    print("[Verify] No catalog item found for word: \(currentWord)")
                                    gameManager.itemNotFound()
                                }
                            } else {
                                gameManager.itemNotFound()
                            }
                        }
                    }
                }) {
                    ZStack {
                        // Outer circle - white frosted glass
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 90, height: 90)
                        
                        // Inner circle - solid white
                        Circle()
                            .fill(.white)
                            .frame(width: 75, height: 75)

                    }
                }
                .glassEffect(in: .circle)
                
                Spacer()
                
                // Skip Button (bottom right with more padding)
                Button(action: {
                    gameManager.skipCurrentItem()
                }) {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .frame(width: 50, height: 50)
                .contentShape(Circle())
                .buttonStyle(.plain)
                .glassEffect(in: .circle)
                .padding(.trailing, 40)
            }
        }
        .padding(.bottom, 0) // Move buttons closer to bottom edge
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
                    
                    Text(displayName(for: currentItem.name))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Time's up!")
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
    
    private var skipOverlay: some View {
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
                    
                    Text(displayName(for: currentItem.name))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Skipped!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .ignoresSafeArea()
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
                
                Text("Try again or skip")
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

    // MARK: - Translations
    private func displayName(for english: String?) -> String {
        guard let english = english else { return "" }
        guard langCode != "en" else { return english }
        let key = environment.replacingOccurrences(of: " ", with: "_").lowercased()
        if let item = CatalogStore.shared.items(in: key).first(where: { $0.word == english }),
           let translated = item.translations[langCode], !translated.isEmpty {
            return translated
        }
        return english
    }
}

// removed attemptStartSession logic (caused first-load race)

struct CameraBackgroundView: View {
    let cameraService: CameraService
    
    var body: some View {
        ZStack {
            if cameraService.isAuthorized {
                // Real camera preview
                CameraPreviewView(cameraService: cameraService, isConfigured: cameraService.isConfigured)
                    .id(cameraService.isConfigured)
                    .background(Color.clear)
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

final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    let isConfigured: Bool

    class Coordinator {
        let previewLayer: AVCaptureVideoPreviewLayer
        init(session: AVCaptureSession) {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.previewLayer.videoGravity = .resizeAspectFill
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(session: cameraService.captureSession)
    }

    func makeUIView(context: Context) -> UIView {
        let view = PreviewContainerView()
        view.backgroundColor = .clear

        let pl = view.previewLayer
        pl.session = cameraService.captureSession
        pl.videoGravity = .resizeAspectFill

        if let c = pl.connection, c.isVideoRotationAngleSupported(90) {
            c.videoRotationAngle = 90  // portrait
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PreviewContainerView else { return }
        let pl = view.previewLayer
        if pl.session == nil { pl.session = cameraService.captureSession }
        pl.frame = view.bounds
        if let c = pl.connection, c.isVideoRotationAngleSupported(90) {
            c.videoRotationAngle = 90
        }
    }
}

#Preview {
    GameSessionView(environment: "Home")
        .environmentObject(GameManager())
        .modelContainer(for: [GameSession.self, GameItem.self, UserProgress.self], inMemory: true)
}
