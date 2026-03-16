import SwiftUI
import DeviceActivity

// MARK: - TodayView
//
// GradientBackground sits OUTSIDE NavigationStack in a ZStack so it bleeds
// behind the nav bar, under the tab bar, and through every card's ultraThinMaterial.

struct TodayView: View {
    @ObservedObject var viewModel: DashboardViewModel

    private static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardGridBackground().ignoresSafeArea()

                ScrollView {
                    let items = viewModel.todayItems
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        UsageReportBridge()
                            .frame(width: 0, height: 0)
                            .opacity(0.01)

                        BloomStatusCard(
                            progress: viewModel.bloomProgress,
                            weeklyAverageMinutes: viewModel.weeklyAverageMinutes,
                            hasUsageData: viewModel.hasUsageData,
                            ruleCount: viewModel.activeRuleCount
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 12)

                        if viewModel.rules.isEmpty {
                            EmptyRulesState(onAddRule: { viewModel.showAddRule = true })
                                .padding(.top, 12)
                        } else if items.isEmpty {
                            NoRulesTodayView()
                                .padding(.top, 12)
                        } else {
                            Section {
                                ForEach(items) { item in
                                    RuleCardView(
                                        item: item,
                                        onToggle: { viewModel.toggleRule(item.rule) },
                                        onUpdate: { viewModel.updateRule($0) },
                                        onDelete: { viewModel.deleteRule(item.rule) }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                            } header: {
                                SectionHeader(title: todayTitle)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(.clear)
                .refreshable { viewModel.loadData() }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddRuleButton(action: { viewModel.showAddRule = true })
                }
            }
            .background(.clear)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var todayTitle: String {
        Self.todayFormatter.string(from: Date())
    }
}

private struct BloomStatusCard: View {
    let progress: Double
    let weeklyAverageMinutes: Double
    let hasUsageData: Bool
    let ruleCount: Int
    @State private var isBreathing = false
    @Environment(\.colorScheme) private var scheme

    private var statusLabel: String {
        guard hasUsageData else { return "Collecting screen time data…" }
        if progress >= 0.75 { return "Blooming" }
        if progress >= 0.45 { return "Steady" }
        return "Withering"
    }

    private var primaryText: Color {
        scheme == .dark ? .white : Color(red: 0.14, green: 0.18, blue: 0.32)
    }

    private var secondaryText: Color {
        scheme == .dark ? .white.opacity(0.75) : Color(red: 0.20, green: 0.28, blue: 0.45)
    }

    private var tertiaryText: Color {
        scheme == .dark ? .white.opacity(0.70) : Color(red: 0.28, green: 0.36, blue: 0.52)
    }

    private var averageLabel: String {
        guard hasUsageData else { return "—" }
        let hours = Int(weeklyAverageMinutes) / 60
        let minutes = Int(weeklyAverageMinutes) % 60
        return hours > 0 ? "\(hours)h \(minutes)m / day avg" : "\(minutes)m / day avg"
    }

    var body: some View {
        HStack(spacing: 16) {
            BloomFlower(progress: progress)
                .frame(width: 120, height: 120)
                .scaleEffect(isBreathing ? 1.02 : 0.98)
                .shadow(color: Color.sgTeal.opacity(0.25), radius: 18, y: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Focus Bloom")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)

                Text(averageLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(secondaryText)

                Text(ruleMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tertiaryText)

                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tertiaryText)
                }
            }

            Spacer()
        }
        .padding(18)
        .background(
            ZStack {
                GlassCard(cornerRadius: 22)
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: scheme == .dark ? [
                                Color(red: 0.08, green: 0.10, blue: 0.22).opacity(0.65),
                                Color(red: 0.10, green: 0.08, blue: 0.26).opacity(0.45),
                                Color(red: 0.20, green: 0.14, blue: 0.40).opacity(0.30),
                            ] : [
                                Color(red: 0.62, green: 0.78, blue: 0.98).opacity(0.35),
                                Color(red: 0.72, green: 0.66, blue: 0.96).opacity(0.30),
                                Color(red: 0.90, green: 0.78, blue: 0.92).opacity(0.22),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(scheme == .dark ? 0.08 : 0.35), lineWidth: 0.8)
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    private var statusColor: Color {
        if !hasUsageData { return .white.opacity(0.4) }
        if progress >= 0.75 { return Color.sgTeal }
        if progress >= 0.45 { return Color.sgYellow }
        return Color.red.opacity(0.85)
    }

    private var ruleMessage: String {
        if ruleCount == 0 { return "No active rules yet — you can add one anytime." }
        if ruleCount == 1 { return "1 rule is protecting your focus right now." }
        return "\(ruleCount) rules are protecting your focus right now."
    }
}

private struct BloomFlower: View {
    let progress: Double

    private var petalCount: Int {
        max(4, Int(6 + progress * 8))
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.sgTeal.opacity(0.20),
                            Color.sgTealDark.opacity(0.12),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 70
                    )
                )

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.9), Color.mint.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 52)
                .offset(y: 28)

            ForEach(0..<petalCount, id: \.self) { index in
                let angle = Double(index) / Double(petalCount) * 360
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.sgTeal.opacity(0.95),
                                Color(red: 0.55, green: 0.65, blue: 1.0).opacity(0.80),
                                Color(red: 0.88, green: 0.55, blue: 0.95).opacity(0.80),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 46)
                    .offset(y: -20)
                    .rotationEffect(.degrees(angle))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.sgTeal.opacity(0.85),
                            Color.sgTealDark.opacity(0.70),
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 22
                    )
                )
                .frame(width: 34, height: 34)
                .shadow(color: Color.sgTeal.opacity(0.35), radius: 10, y: 2)
        }
    }
}

private struct UsageReportBridge: View {
    private let filter: DeviceActivityFilter = {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) ??
            DateInterval(start: calendar.startOfDay(for: Date()), end: Date())
        return DeviceActivityFilter(
            segment: .daily(during: interval)
        )
    }()

    var body: some View {
        DeviceActivityReport(.appUsageSummary, filter: filter)
            .frame(width: 0, height: 0)
            .hidden()
    }
}

// MARK: - No Rules Today

private struct NoRulesTodayView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("Gremlin")
                .resizable().scaledToFit()
                .frame(width: 72, height: 72).opacity(0.65)
            Text("Nothing scheduled today")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Dashboard View (removed)
