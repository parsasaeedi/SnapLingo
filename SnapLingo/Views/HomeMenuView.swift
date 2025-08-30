import SwiftUI
import SwiftData

struct HomeMenuView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @StateObject private var gameManager = GameManager()
    @ObservedObject private var catalogStore = CatalogStore.shared
    @State private var presentedEnv: PresentedEnv?
    @State private var showSetupView = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Environments from catalog.json
    var allEnvironments: [EnvironmentItem] {
        let iconMap: [String: String] = [
            "home": "house.fill",
            "food": "fork.knife",
            "pet_store": "pawprint.fill",
            "street": "signpost.right.fill",
            "garage": "wrench.fill",
            "office": "desktopcomputer",
            "clothing": "tshirt.fill",
            "zoo": "tortoise.fill"
        ]
        let colorMap: [String: Color] = [
            "home": .blue,
            "food": .red,
            "pet_store": .orange,
            "street": .green,
            "garage": .gray,
            "office": .purple,
            "clothing": .pink,
            "zoo": .teal
        ]

        let envs = catalogStore.catalog.environments
        return envs.keys.sorted().map { key in
            let items = envs[key] ?? []
            return EnvironmentItem(
                key: key,
                name: key.replacingOccurrences(of: "_", with: " ").capitalized,
                icon: iconMap[key] ?? "square.grid.2x2",
                color: colorMap[key] ?? .blue,
                isComingSoon: false,
                itemCount: items.count
            )
        }
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
                                            let key = item.key
                                            var items = catalogStore.catalog.environments[key] ?? []
                                            if items.isEmpty {
                                                catalogStore.load()
                                                items = catalogStore.catalog.environments[key] ?? []
                                            }
                                            guard !items.isEmpty else {
                                                print("[HomeMenu] No items for environment: \(key)")
                                                return
                                            }
                                            presentedEnv = PresentedEnv(key: key, items: items)
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
        .fullScreenCover(item: $presentedEnv) { env in
            GameSessionView(environment: env.key, initialItems: env.items)
                .environmentObject(gameManager)
        }
        .fullScreenCover(isPresented: $showSetupView) {
            SetupView()
        }
    }
}

struct EnvironmentItem {
    let id = UUID()
    let key: String
    let name: String
    let icon: String
    let color: Color
    let isComingSoon: Bool
    let itemCount: Int
    
    init(key: String, name: String, icon: String, color: Color, isComingSoon: Bool, itemCount: Int) {
        self.key = key
        self.name = name
        self.icon = icon
        self.color = color
        self.isComingSoon = isComingSoon
        self.itemCount = itemCount
    }
}

struct PresentedEnv: Identifiable {
    let key: String
    let items: [Item]
    var id: String { key }
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
                    .frame(height: 40) // Fixed height for consistent sizing
                
                VStack(spacing: 4) {
                    Text(environmentItem.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(environmentItem.isComingSoon ? .secondary : .primary)
                    
                    Text(environmentItem.isComingSoon ? "Coming Soon" : "\(environmentItem.itemCount) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120) // Fixed minimum height for consistency
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
