import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct GameSessionView: View {
    let environment: String
    let initialItems: [Item]?
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @AppStorage("langCode") private var langCode: String = "en"
    @StateObject private var cameraService = CameraService()
    private let volumeService = VolumeButtonShutterService()
    @State private var cameraStarted = false
    @State private var showCameraLoading = true
    @State private var isShutterPressed = false
    @ScaledMetric(relativeTo: .largeTitle) private var largeIconSize: CGFloat = 80
    @ScaledMetric(relativeTo: .title) private var mediumIconSize: CGFloat = 60
    
    init(environment: String, initialItems: [Item]? = nil) {
        self.environment = environment
        self.initialItems = initialItems
    }
    
    var body: some View {
        ZStack {
            CameraBackgroundView(cameraService: cameraService)
            VolumeButtonListener(service: volumeService)
                .frame(width: 0, height: 0)
            
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

            VStack(spacing: 0) {
                topBar
                
                Spacer()
                
                bottomControls
            }
            .padding()
            
            if gameManager.showItemNotFound {
                itemNotFoundOverlay
            }

            if gameManager.showItemFound {
                itemFoundOverlay
            }
            
            if gameManager.showGameComplete {
                gameCompleteOverlay
            }
            
            if gameManager.timeRemaining <= 0 && gameManager.isGameActive {
                timerExpiredOverlay
            }
            
            if gameManager.showSkipOverlay {
                skipOverlay
            }
        }
        .onAppear {
            let key = environment.replacingOccurrences(of: " ", with: "_").lowercased()
            let items = (initialItems?.isEmpty == false) ? initialItems : CatalogStore.shared.items(in: key)
            gameManager.startSession(environment: environment, items: items, modelContext: modelContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !cameraStarted {
                    cameraService.startSession()
                    cameraStarted = true
                }
            }
            volumeService.onTrigger = { triggerShutter() }
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
            volumeService.stop()
        }
    }

private struct VolumeButtonListener: UIViewRepresentable {
    let service: VolumeButtonShutterService
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        service.start(in: v)
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {}
}
    
    private var topBar: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch")
                    Text("\(Int(gameManager.timeRemaining))s")
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .foregroundColor(gameManager.timerColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                )
                .fixedSize()
                .glassEffect()

                HStack {
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
                    )
                    .glassEffect()

                    Spacer()

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
                    )
                    .glassEffect()
                }
            }
            
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
            )
            .glassEffect()
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
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
            
            HStack {
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
                
                Button(action: { triggerShutter() }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 90, height: 90)

                        Circle()
                            .fill(isShutterPressed ? Color.white.opacity(0.6) : Color.white)
                            .frame(width: 75, height: 75)

                    }
                }
                .glassEffect(in: .circle)
                
                Spacer()
                
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
        .padding(.bottom, 0)
            }
    private var timerExpiredOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                if let currentItem = gameManager.currentItem {
                    if currentItem.emoji != "❓" {
                        Text(currentItem.emoji)
                            .font(.system(size: largeIconSize))
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: largeIconSize))
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
                    if currentItem.emoji != "❓" {
                        Text(currentItem.emoji)
                            .font(.system(size: largeIconSize))
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: largeIconSize))
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
                    .font(.system(size: mediumIconSize))
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
                    .font(.system(size: mediumIconSize))
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
                Image(systemName: "trophy.fill")
                    .font(.system(size: largeIconSize))
                    .foregroundColor(.yellow)
                
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

    private func triggerShutter() {
        withAnimation(.easeOut(duration: 0.12)) { isShutterPressed = true }
        cameraService.captureCurrentFrame { image in
            if let image = image {
                gameManager.handleShutter(image: image, environmentKey: environment)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.12)) { isShutterPressed = false }
            }
        }
    }

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

struct CameraBackgroundView: View {
    let cameraService: CameraService
    @ScaledMetric(relativeTo: .title) private var cameraIconSize: CGFloat = 60
    
    var body: some View {
        ZStack {
            if cameraService.isAuthorized {
                CameraPreviewView(cameraService: cameraService, isConfigured: cameraService.isConfigured)
                    .id(cameraService.isConfigured)
                    .background(Color.clear)
            } else {
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
                        .font(.system(size: cameraIconSize))
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
            c.videoRotationAngle = 90
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
