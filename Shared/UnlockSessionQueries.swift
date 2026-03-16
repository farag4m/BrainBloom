import Foundation

enum UnlockSessionQueries {
    static func activeSession(for ruleID: UUID, in sessions: [UnlockSession], now: Date = Date()) -> UnlockSession? {
        let calendar = Calendar.current
        return sessions
            .filter { session in
                session.ruleID == ruleID &&
                calendar.isDate(session.startedAt, inSameDayAs: now) &&
                session.actualEndedAt == nil
            }
            .sorted { $0.startedAt > $1.startedAt }
            .first
    }

    static func todaySessions(for ruleID: UUID, in sessions: [UnlockSession], now: Date = Date()) -> [UnlockSession] {
        let calendar = Calendar.current
        return sessions
            .filter { session in
                session.ruleID == ruleID &&
                calendar.isDate(session.startedAt, inSameDayAs: now)
            }
            .sorted { $0.startedAt > $1.startedAt }
    }
}
