//
//  ContentView.swift
//  SnapLingo
//
//  Created by Parsa Saeedi on 2025-08-23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        SetupView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GameSession.self, GameItem.self, UserProgress.self], inMemory: true)
}
