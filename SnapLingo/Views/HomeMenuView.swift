import SwiftUI
import SwiftData

struct HomeMenuView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @StateObject private var gameManager = GameManager()
    @State private var showGameSession = false
    @State private var selectedEnvironment = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SnapLingo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    
                    Spacer()
                    
                    Button(action: {
                        // Show stats/profile
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Section
                        VStack(spacing: 12) {
                            Text("Choose an environment")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Find objects in different settings to learn new words")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Environment Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(GameEnvironment.environments, id: \.name) { environment in
                                EnvironmentCard(
                                    environment: environment,
                                    onTap: {
                                        selectedEnvironment = environment.name
                                        showGameSession = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Coming Soon Section
                        VStack(spacing: 16) {
                            Text("More environments coming soon!")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                ComingSoonCard(title: "Park", icon: "tree.fill", color: .green)
                                ComingSoonCard(title: "Downtown", icon: "building.2.fill", color: .orange)
                                ComingSoonCard(title: "Kitchen", icon: "fork.knife", color: .red)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showGameSession) {
            GameSessionView(environment: selectedEnvironment)
                .environmentObject(gameManager)
        }
    }
}

struct EnvironmentCard: View {
    let environment: GameEnvironment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: environment.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                VStack(spacing: 4) {
                    Text(environment.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(environment.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComingSoonCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color.opacity(0.6))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}

#Preview {
    HomeMenuView()
        .modelContainer(for: [GameSession.self, GameItem.self, UserProgress.self], inMemory: true)
}
