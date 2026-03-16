import SwiftUI

struct ScreenTimeDebugView: View {
    @State private var averageMinutes: Double = 120
    @State private var ageDays: Int = 0
    @State private var variance: Double = 18
    @State private var didWrite = false

    var body: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Screen Time Simulator")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)

                        Text("Writes fake weekly averages so you can preview the Focus Bloom response in Simulator.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider().opacity(0.4)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Average Minutes / Day")
                                Spacer()
                                Text("\(Int(averageMinutes)) min")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Slider(value: $averageMinutes, in: 0...360, step: 5)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Data Age")
                                Spacer()
                                Text(ageDays == 0 ? "Today" : "\(ageDays) days ago")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Stepper(value: $ageDays, in: 0...21) {
                                Text("Shift data back in time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Daily Variance")
                                Spacer()
                                Text("±\(Int(variance)) min")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Slider(value: $variance, in: 0...60, step: 2)
                        }

                        HStack(spacing: 12) {
                            Button("Write Fake Data") {
                                writeFakeData()
                                didWrite = true
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            Button("Clear") {
                                AppGroupStore.shared.saveUsageSummaries([])
                                NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
                                didWrite = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        if didWrite {
                            Text("Fake usage data saved to App Group.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .background(GlassCard(cornerRadius: 24))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Screen Time Debug")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func writeFakeData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: -ageDays, to: today) ?? today
        let base = averageMinutes * 60
        let dayOffsets = (0..<7).reversed()

        let summaries: [UsageDaySummary] = dayOffsets.compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: endDate) else { return nil }
            let wave = sin(Double(offset) * 1.2) * variance * 60
            let total = max(0, base + wave)
            return UsageDaySummary(
                date: AppGroupStore.dayString(for: date),
                totalScreenTimeSeconds: total
            )
        }

        AppGroupStore.shared.saveUsageSummaries(summaries)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
    }
}
