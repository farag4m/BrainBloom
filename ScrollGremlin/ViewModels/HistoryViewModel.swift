import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var sessions: [UnlockSession] = []
    @Published var rules: [AppRule] = []
    @Published var settings: UserSettings = .default

    private let store = AppGroupStore.shared

    init() {
        loadData()
    }

    func loadData() {
        sessions = store.loadUnlockSessions()
            .sorted { $0.startedAt > $1.startedAt }
        rules = store.loadRules()
        settings = store.loadSettings()
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
        let calendar = Calendar.current
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        while true {
            let dayHasUnlock = sessions.contains {
                calendar.isDate($0.startedAt, inSameDayAs: date)
            }
            if dayHasUnlock { break }
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDay
            if streak > 365 { break }
        }
        return streak
    }

    func ruleName(for session: UnlockSession) -> String {
        rules.first(where: { $0.id == session.ruleID })?.name ?? "Unknown Rule"
    }
}
