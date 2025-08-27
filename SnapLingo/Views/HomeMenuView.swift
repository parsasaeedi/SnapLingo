import SwiftUI
import SwiftData

struct HomeMenuView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @StateObject private var gameManager = GameManager()
    @State private var showGameSession = false
    @State private var selectedEnvironment = ""
    @State private var showSetupView = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Combined environments including coming soon ones
    var allEnvironments: [EnvironmentItem] {
        let availableEnvironments = GameEnvironment.environments.map { env in
            EnvironmentItem(environment: env, isComingSoon: false)
        }
        
        let comingSoonEnvironments = [
            EnvironmentItem(name: "Park", icon: "tree.fill", color: .green, isComingSoon: true),
            EnvironmentItem(name: "Downtown", icon: "building.2.fill", color: .orange, isComingSoon: true),
            EnvironmentItem(name: "Kitchen", icon: "fork.knife", color: .red, isComingSoon: true)
        ]
        
        return availableEnvironments + comingSoonEnvironments
    }
    
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
                        showSetupView = true
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
                            ForEach(allEnvironments, id: \.id) { item in
                                EnvironmentCard(
                                    environmentItem: item,
                                    onTap: {
                                        if !item.isComingSoon {
                                            selectedEnvironment = item.name
                                            showGameSession = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showGameSession) {
            GameSessionView(environment: selectedEnvironment)
                .environmentObject(gameManager)
        }
        .fullScreenCover(isPresented: $showSetupView) {
            SetupView()
        }
    }
}

struct EnvironmentItem {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let isComingSoon: Bool
    let environment: GameEnvironment?
    
    init(environment: GameEnvironment, isComingSoon: Bool) {
        self.name = environment.name
        self.icon = environment.icon
        self.color = .blue
        self.isComingSoon = isComingSoon
        self.environment = environment
    }
    
    init(name: String, icon: String, color: Color, isComingSoon: Bool) {
        self.name = name
        self.icon = icon
        self.color = color
        self.isComingSoon = isComingSoon
        self.environment = nil
    }
}

struct EnvironmentCard: View {
    let environmentItem: EnvironmentItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: environmentItem.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        .linearGradient(
                            colors: environmentItem.isComingSoon
                                ? [environmentItem.color.opacity(0.6), environmentItem.color.opacity(0.6)]
                                : [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 4) {
                    Text(environmentItem.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(environmentItem.isComingSoon ? .secondary : .primary)
                    
                    if let environment = environmentItem.environment {
                        Text("\(environment.items.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
            .opacity(environmentItem.isComingSoon ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(environmentItem.isComingSoon)
    }
}

#Preview {
    HomeMenuView()
        .modelContainer(for: [GameSession.self, GameItem.self, UserProgress.self], inMemory: true)
}
