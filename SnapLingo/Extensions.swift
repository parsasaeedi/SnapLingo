import Foundation
import SwiftUI

extension GameSession {
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    var foundItemsCount: Int {
        items.filter { $0.found }.count
    }
    
    var accuracy: Double {
        guard !items.isEmpty else { return 0 }
        return Double(foundItemsCount) / Double(items.count)
    }
    
    var averageTimeToFind: TimeInterval {
        let foundItems = items.filter { $0.found && $0.timeToFind != nil }
        guard !foundItems.isEmpty else { return 0 }
        
        let totalTime = foundItems.compactMap { $0.timeToFind }.reduce(0, +)
        return totalTime / Double(foundItems.count)
    }
}

extension UserProgress {
    var averageScore: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(totalScore) / Double(totalSessions)
    }
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return 0.75
    }
}

extension Color {
    static let liquidGlass = Color(.systemBackground).opacity(0.8)
    static let liquidGlassSecondary = Color(.secondarySystemBackground).opacity(0.8)
}

extension View {
    func liquidGlassBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
    
    func gradientText(_ colors: [Color]) -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
