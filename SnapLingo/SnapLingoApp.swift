//
//  SnapLingoApp.swift
//  SnapLingo
//
//  Created by Parsa Saeedi on 2025-08-23.
//

import SwiftUI
import SwiftData

@main
struct SnapLingoApp: App {
    init() {
        // Force CatalogStore to initialize and load catalog.json at app launch
        _ = CatalogStore.shared
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameSession.self,
            GameItem.self,
            UserProgress.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SetupView()
        }
        .modelContainer(sharedModelContainer)
    }
}
