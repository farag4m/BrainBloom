import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var sessions: [UnlockSession] = []
    @Published var rules: [AppRule] = []
    @Published var settings: UserSettings = .default
    @Published var usageSummaries: [UsageDaySummary] = []

    private let store = AppGroupStore.shared

    init() {
        loadData()
    }

    func loadData() {
        sessions = store.loadUnlockSessions()
            .sorted { $0.startedAt > $1.startedAt }
        rules = store.loadRules()
        settings = store.loadSettings()
        usageSummaries = store.loadUsageSummaries()
    }

    var sessionsGroupedByDate: [(Date, [UnlockSession])] {
        let calendar = Calendar.current
        var grouped: [Date: [UnlockSession]] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            grouped[day, default: []].append(session)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var totalUnlocksThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { $0.startedAt > weekAgo }.count
    }

    var currentStreak: Int {
        UsageInsights.lowScreenTimeStreak(from: usageSummaries)
    }

    var streakDescription: String {
        UsageInsights.lowScreenTimeStreakDescription
    }

    func ruleName(for session: UnlockSession) -> String {
        rules.first(where: { $0.id == session.ruleID })?.name ?? "Unknown Rule"
    }
}
