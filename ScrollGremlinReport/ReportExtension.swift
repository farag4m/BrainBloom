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
