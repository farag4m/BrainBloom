import DeviceActivity
import Foundation

public enum UsageSummaryWriter {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func write(from data: DeviceActivityResults<DeviceActivityData>) async {
        var totalsByDay: [String: TimeInterval] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                let day = calendar.startOfDay(for: segment.dateInterval.start)
                guard day >= cutoff else { continue }
                let key = dayFormatter.string(from: day)
                totalsByDay[key, default: 0] += segment.totalActivityDuration
            }
        }

        let summaries = totalsByDay
            .map { UsageDaySummary(date: $0.key, totalScreenTimeSeconds: $0.value) }
            .sorted { $0.date < $1.date }

        guard let defaults = UserDefaults(suiteName: AppConfig.appGroupID) else { return }
        defaults.set(try? JSONEncoder().encode(summaries), forKey: AppConfig.usageSummaryKey)
    }
}
