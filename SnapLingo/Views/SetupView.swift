import SwiftUI

struct SetupView: View {
    @State private var selectedLanguage = "English"
    @State private var showHomeMenu = false
    
    let languages = [
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // Add top padding for dynamic island
                Spacer()
                    .frame(height: 10)
                
                // App Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("SnapLingo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    
                    Text("Learn languages through photo scavenger hunts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Language Selection
                VStack(spacing: 20) {
                    Text("Choose your language")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Make languages list scrollable with limited height
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(languages, id: \.self) { language in
                                Button(action: {
                                    selectedLanguage = language
                                }) {
                                    HStack {
                                        Text(language)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedLanguage == language {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedLanguage == language ? Color.blue : Color.clear, lineWidth: 0)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if language != languages.last {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 350) // Limit height and make scrollable
                    .overlay(
                        // Gradient fade at bottom
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [Color.clear, Color(.systemBackground)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                        }
                        .allowsHitTesting(false)
                    )
                }
                
                Spacer()
                
                // Continue Button with bottom padding
                Button(action: {
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
                                .fill(.linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 10) // Add more bottom padding
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showHomeMenu) {
            HomeMenuView()
        }
    }
}

#Preview {
    SetupView()
}
