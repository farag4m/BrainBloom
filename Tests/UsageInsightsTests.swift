import Foundation
import XCTest
@testable import BrainBloom

final class UsageInsightsTests: XCTestCase {
    func testWeeklyAverageUsesOnlyRecentDays() {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let recentKey = UsageInsights.weeklyAverageMinutes(from: [])
        XCTAssertEqual(recentKey, 0)

        let summaries = (0..<7).compactMap { offset -> UsageDaySummary? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: endDate) else { return nil }
            let key = dateFormatter.string(from: date)
            return UsageDaySummary(date: key, totalScreenTimeSeconds: 60 * 60)
        }
        let avg = UsageInsights.weeklyAverageMinutes(from: summaries, endingOn: endDate)
        XCTAssertEqual(avg, 60)
    }

    func testLowScreenTimeStreakStopsOnHighUsage() {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let dates = (0..<3).compactMap { offset -> String? in
            calendar.date(byAdding: .day, value: -offset, to: endDate).map(dateFormatter.string(from:))
        }
        let summaries = [
            UsageDaySummary(date: dates[0], totalScreenTimeSeconds: 60 * 60),
            UsageDaySummary(date: dates[1], totalScreenTimeSeconds: 60 * 60),
            UsageDaySummary(date: dates[2], totalScreenTimeSeconds: 5 * 60 * 60)
        ]
        let streak = UsageInsights.lowScreenTimeStreak(from: summaries, endingOn: endDate)
        XCTAssertEqual(streak, 2)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
