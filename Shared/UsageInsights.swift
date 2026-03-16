import Foundation

enum UsageInsights {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    nonisolated static let lowScreenTimeThresholdSeconds: Double = 3 * 60 * 60

    nonisolated static func weeklyAverageMinutes(from summaries: [UsageDaySummary], endingOn endDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate)
        let recentDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: endOfDay).map(dayKey(for:))
        }
        let totalsByDate = Dictionary(uniqueKeysWithValues: summaries.map { ($0.date, $0.totalScreenTimeSeconds) })
        let values = recentDays.compactMap { totalsByDate[$0] }
        guard !values.isEmpty else { return 0 }
        return (values.reduce(0, +) / Double(values.count)) / 60.0
    }

    nonisolated static func hasWeeklyUsageData(_ summaries: [UsageDaySummary], endingOn endDate: Date = Date()) -> Bool {
        weeklyAverageMinutes(from: summaries, endingOn: endDate) > 0
    }

    nonisolated static func lowScreenTimeStreak(from summaries: [UsageDaySummary], endingOn endDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let totalsByDate = Dictionary(uniqueKeysWithValues: summaries.map { ($0.date, $0.totalScreenTimeSeconds) })
        var streak = 0
        var currentDate = calendar.startOfDay(for: endDate)

        while true {
            let key = dayKey(for: currentDate)
            guard let totalSeconds = totalsByDate[key], totalSeconds <= lowScreenTimeThresholdSeconds else {
                return streak
            }

            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return streak
            }
            currentDate = previousDate
        }
    }

    nonisolated static var lowScreenTimeStreakDescription: String {
        "Streak counts consecutive days with 3 hours or less of screen time."
    }

    private nonisolated static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
