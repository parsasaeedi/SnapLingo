import SwiftUI
import SwiftData

struct HomeMenuView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @StateObject private var gameManager = GameManager()
    @ObservedObject private var catalogStore = CatalogStore.shared
    @State private var presentedEnv: PresentedEnv?
    @State private var showSetupView = false
    
    private let gridSpacing: CGFloat = 16

    var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: gridSpacing),
            GridItem(.flexible(), spacing: gridSpacing)
        ]
    }
    
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
        let backgroundColorMap: [String: Color] = [
            "home": Color(red: 0.2, green: 0.7, blue: 0.9),       // Bright cyan
            "food": Color(red: 0.9, green: 0.3, blue: 0.4),       // Coral red
            "pet_store": Color(red: 0.6, green: 0.2, blue: 0.8),  // Vibrant purple
            "street": Color(red: 0.1, green: 0.8, blue: 0.3),     // Bright green
            "garage": Color(red: 0.8, green: 0.5, blue: 0.2),     // Orange
            "office": Color(red: 0.8, green: 0.2, blue: 0.6),     // Hot pink
            "clothing": Color(red: 0.3, green: 0.6, blue: 0.8),   // Sky blue
            "zoo": Color(red: 0.9, green: 0.7, blue: 0.2)         // Golden yellow
        ]
        
        let foregroundColorMap: [String: Color] = [
            "home": Color.white,                                   // White on cyan
            "food": Color.white,                                   // White on coral red
            "pet_store": Color.white,                               // White on purple
            "street": Color.white,                                 // White on bright green
            "garage": Color.white,                                 // White on orange
            "office": Color.white,                                 // White on hot pink
            "clothing": Color.white,                                // White on sky blue
            "zoo": Color.white                                     // white on golden yellow
        ]

        let envs = catalogStore.catalog.environments
        return envs.keys.sorted().map { key in
            let items = envs[key] ?? []
            return EnvironmentItem(
                key: key,
                name: key.replacingOccurrences(of: "_", with: " ").capitalized,
                icon: iconMap[key] ?? "square.grid.2x2",
                backgroundColor: backgroundColorMap[key] ?? Color(red: 0.95, green: 0.95, blue: 0.95),
                foregroundColor: foregroundColorMap[key] ?? Color(red: 0.4, green: 0.4, blue: 0.4),
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
                        LazyVGrid(columns: columns, spacing: 12) {
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
                                            guard !items.isEmpty else { return }
                                            presentedEnv = PresentedEnv(key: key, items: items)
                                        }
                                    }
                                )
                                .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        .padding(.horizontal, gridSpacing)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .background(Color(red: 0.078, green: 0.122, blue: 0.141))
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
    let backgroundColor: Color
    let foregroundColor: Color
    let isComingSoon: Bool
    let itemCount: Int
    
    init(key: String, name: String, icon: String, backgroundColor: Color, foregroundColor: Color, isComingSoon: Bool, itemCount: Int) {
        self.key = key
        self.name = name
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
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
    @ScaledMetric(relativeTo: .title2) private var cardIconSize: CGFloat = 32
    
    var nameLines: [String] {
        let words = environmentItem.name.components(separatedBy: " ")
        return words.count > 1 ? words : [environmentItem.name]
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(environmentItem.backgroundColor)
                    .shadow(color: environmentItem.backgroundColor.opacity(0.5), radius: 2, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(red: 0.078, green: 0.122, blue: 0.141).opacity(0.5), lineWidth: 4)
                            .blur(radius: 8)
                    )
                
                VStack {
                    HStack {
                        Image(systemName: environmentItem.icon)
                            .font(.system(size: cardIconSize, weight: .medium))
                            .foregroundColor(environmentItem.foregroundColor)
                            .shadow(color: Color(red: 0.078, green: 0.122, blue: 0.141).opacity(0.3), radius: 6, x: 0, y: 0)
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.leading, 24)
                    
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(nameLines, id: \.self) { line in
                                Text(line)
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(environmentItem.foregroundColor)
                                    .shadow(color: Color(red: 0.078, green: 0.122, blue: 0.141).opacity(0.3), radius: 6, x: 0, y: 0)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                    .padding(.leading, 24)
                }
            }
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
