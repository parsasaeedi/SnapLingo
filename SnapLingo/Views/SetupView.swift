import SwiftUI
import AVFoundation

struct SetupView: View {
    @State private var selectedLanguage = "English"
    @State private var showHomeMenu = false
    @AppStorage("langCode") private var langCode: String = "en"
    @ScaledMetric(relativeTo: .largeTitle) private var headerIconSize: CGFloat = 80

    private let languageMap: [String: String] = [
        "English": "en",
        "Spanish": "es",
        "French": "fr",
        "German": "de",
        "Italian": "it",
        "Portuguese": "pt",
        "Korean": "ko",
        "Chinese": "zh",
        "Arabic": "ar",
        "Farsi": "fa",
        "Japanese": "ja",
        "Turkish": "tr",
        "Polish": "pl"
    ]
    private var languageLabels: [String] { languageMap.keys.sorted() }

    private var brandGradientDiagonal: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var brandGradientHorizontal: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Spacer().frame(height: 10)

                headerSection

                Spacer()

                languageSection

                Spacer()

                continueButton
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showHomeMenu) {
            HomeMenuView()
        }
        .onAppear {
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { _ in }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: headerIconSize))
                .foregroundStyle(brandGradientDiagonal)

            Text("SnapLingo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(brandGradientHorizontal)

            Text("Snap photos. Learn words. Have fun.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var languageSection: some View {
        VStack(spacing: 20) {
            Text("I want to learn...")
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(languageLabels, id: \.self) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedLanguage == language
                        ) {
                            selectedLanguage = language
                        }

                        if language != languageLabels.last {
                            Divider().padding(.horizontal)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)
            }
            .frame(maxHeight: 350)
            .overlay(
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, Color(UIColor.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
                .allowsHitTesting(false)
            )
        }
    }

    private var continueButton: some View {
        Button(action: {
            let code = languageMap[selectedLanguage] ?? "en"
            langCode = code
            showHomeMenu = true
        }) {
            Text("Continue")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(brandGradientHorizontal)
                )
        }
    }
}

private struct LanguageRow: View {
    let language: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(language)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SetupView()
}
