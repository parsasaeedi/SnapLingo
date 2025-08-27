import SwiftUI

struct SetupView: View {
    @State private var selectedLanguage = "English"
    @State private var showHomeMenu = false

    private let languages = [
        "English",
        "Spanish",
        "French",
        "German",
        "Italian",
        "Portuguese",
        "Japanese",
        "Korean",
        "Chinese",
        "Arabic"
    ]

    // Extract gradients so type inference is trivial
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
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(brandGradientDiagonal)

            Text("SnapLingo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(brandGradientHorizontal)

            Text("Learn languages through photo scavenger hunts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var languageSection: some View {
        VStack(spacing: 20) {
            Text("Choose your language")
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(languages, id: \.self) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedLanguage == language
                        ) {
                            selectedLanguage = language
                        }

                        if language != languages.last {
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
        Button(action: { showHomeMenu = true }) {
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

// MARK: - Subviews

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
