import DeviceActivity
import SwiftUI
import Foundation

@main
struct ReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        AppUsageSummaryScene()
    }
}

struct AppUsageSummaryScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .appUsageSummary

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Bool {
        await UsageSummaryWriter.write(from: data)
        return true
    }

    let content: (Bool) -> AppUsageSummaryView = { _ in AppUsageSummaryView() }
}

struct AppUsageSummaryView: View {
    // This view renders inside main app UI but runs as a sandboxed extension.
    // Usage data cannot be exported — it renders here in the extension context.

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.9))
            Text("Usage data")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

extension DeviceActivityReport.Context {
    static let appUsageSummary = Self("AppUsageSummary")
}

// MARK: - Usage Summary Writer

private enum UsageSummaryWriter {
    private static let appGroupID = "group.com.yourco.scrollgremlin"

    private struct UsageDaySummary: Codable {
        let date: String
        let totalScreenTimeSeconds: Double
    }

    static func write(from data: DeviceActivityResults<DeviceActivityData>) async {
        var totalsByDay: [String: TimeInterval] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                let day = calendar.startOfDay(for: segment.dateInterval.start)
                guard day >= cutoff else { continue }
                let key = dayString(for: day)
                totalsByDay[key, default: 0] += segment.totalActivityDuration
            }
        }

        let summaries = totalsByDay.map { UsageDaySummary(date: $0.key, totalScreenTimeSeconds: $0.value) }
            .sorted { $0.date < $1.date }

        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(try? JSONEncoder().encode(summaries), forKey: "usage_summary_v1")
    }

    private static func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
