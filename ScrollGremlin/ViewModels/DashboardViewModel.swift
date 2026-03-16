import SwiftUI
import Combine

// MARK: - RuleDisplayItem

/// A rule paired with its derived badge, computed atomically from the same state snapshot.
/// Passing this type to views guarantees rule state and badge state are always in sync —
/// there is no way for the badge to reflect a different version of the rule than what the
/// card is rendering.
struct RuleDisplayItem: Identifiable {
    let rule: AppRule
    let badge: RuleStatusBadge
    var id: UUID { rule.id }
}

// MARK: - DayGroup

/// A group of rules sharing the same active-days schedule pattern,
/// used as sections in the All Rules tab.
struct DayGroup: Identifiable {
    let activeDays: Set<Int>
    let items: [RuleDisplayItem]    // sorted by rule.createdAt ascending (added-first)

    var id: String { activeDays.sorted().map(String.init).joined(separator: "-") }

    var title: String { DayGroup.title(for: activeDays) }

    static func title(for days: Set<Int>) -> String {
        if days == Set(1...7)        { return "Every Day" }
        if days == Set([2, 3, 4, 5, 6]) { return "Weekdays" }
        if days == Set([1, 7])       { return "Weekends" }
        let names: [Int: String] = [1:"Sun", 2:"Mon", 3:"Tue", 4:"Wed", 5:"Thu", 6:"Fri", 7:"Sat"]
        // Sort Monday-first: Mon(2)→0, Tue(3)→1, ..., Sun(1)→6
        return days.sorted { ($0 - 2 + 7) % 7 < ($1 - 2 + 7) % 7 }
            .compactMap { names[$0] }.joined(separator: " · ")
    }
}

// MARK: - DashboardViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var rules: [AppRule] = []
    @Published var shieldStates: [UUID: Bool] = [:]
    @Published var showAddRule = false
    @Published var weeklyAverageMinutes: Double = 0
    @Published var hasUsageData = false

    private let store = AppGroupStore.shared
    private let ruleManager = RuleManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadData()
        observeChanges()
    }

    // MARK: - Data loading

    func loadData() {
        ruleManager.reloadRules()
        rules = ruleManager.rules
        refreshShieldStates()
        ruleManager.handlePendingUnlockRequest()
        refreshUsageSummary()
    }

    func refreshShieldStates() {
        shieldStates = Dictionary(
            uniqueKeysWithValues: rules.map { ($0.id, store.isShielded($0.id)) }
        )
    }

    // MARK: - Mutations

    func addRule(_ rule: AppRule) {
        try? ruleManager.addRule(rule)
        rules = ruleManager.rules
        refreshShieldStates()
    }

    func deleteRule(_ rule: AppRule) {
        ruleManager.deleteRule(id: rule.id)
        rules = ruleManager.rules
        refreshShieldStates()
    }

    func updateRule(_ rule: AppRule) {
        try? ruleManager.updateRule(rule)
        rules = ruleManager.rules
        refreshShieldStates()
    }

    func toggleRule(_ rule: AppRule) {
        try? ruleManager.toggleRule(id: rule.id)
        rules = ruleManager.rules
        refreshShieldStates()
    }

    // MARK: - Today tab

    /// All rules scheduled for today (by weekday), regardless of enabled/disabled state.
    /// Sorted added-first. Disabled rules appear here with a Disabled badge so the user
    /// can re-enable them without hunting through a separate screen.
    var todayItems: [RuleDisplayItem] {
        let today = Calendar.current.component(.weekday, from: Date())
        return rules
            .filter { $0.schedule.activeDays.contains(today) }
            .sorted { $0.createdAt < $1.createdAt }
            .map { makeDisplayItem($0) }
    }

    var activeRuleCount: Int {
        rules.filter { $0.isEnabled }.count
    }

    var bloomProgress: Double {
        guard hasUsageData else { return 0.5 }
        let target = 120.0
        let maxMinutes = 360.0
        if weeklyAverageMinutes <= target { return 1.0 }
        if weeklyAverageMinutes >= maxMinutes { return 0.0 }
        return 1.0 - (weeklyAverageMinutes - target) / (maxMinutes - target)
    }

    // MARK: - All Rules tab

    /// Every rule grouped by its active-days pattern.
    /// Section order: Every Day → Weekdays → Weekends → custom patterns (by earliest active day).
    /// Within each group: sorted added-first.
    /// Toggling/disabling a rule never changes which group it belongs to.
    var allRulesDayGroups: [DayGroup] {
        var dict: [Set<Int>: [AppRule]] = [:]
        for rule in rules {
            dict[rule.schedule.activeDays, default: []].append(rule)
        }
        return dict
            .map { days, groupRules in
                DayGroup(
                    activeDays: days,
                    items: groupRules
                        .sorted { $0.createdAt < $1.createdAt }
                        .map { makeDisplayItem($0) }
                )
            }
            .sorted { sectionPriority($0.activeDays) < sectionPriority($1.activeDays) }
    }

    // MARK: - Private helpers

    /// Derives badge atomically with the rule snapshot — call site gets one consistent object.
    private func makeDisplayItem(_ rule: AppRule) -> RuleDisplayItem {
        RuleDisplayItem(rule: rule, badge: computeBadge(for: rule))
    }

    private func computeBadge(for rule: AppRule) -> RuleStatusBadge {
        RuleStatusBadge.make(for: rule, isShielded: shieldStates[rule.id] == true)
    }

    private func sectionPriority(_ days: Set<Int>) -> Int {
        if days == Set(1...7)            { return 0 }
        if days == Set([2, 3, 4, 5, 6]) { return 1 }
        if days == Set([1, 7])           { return 2 }
        return 3 + (days.map { ($0 - 2 + 7) % 7 }.min() ?? 6) // custom: Monday-first order
    }

    private func refreshUsageSummary() {
        let summaries = store.loadUsageSummaries()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let last7 = (0..<7).compactMap { dayOffset -> String? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            return AppGroupStore.dayString(for: date)
        }

        let byDate = Dictionary(uniqueKeysWithValues: summaries.map { ($0.date, $0.totalScreenTimeSeconds) })
        let values = last7.compactMap { byDate[$0] }

        hasUsageData = !values.isEmpty
        weeklyAverageMinutes = values.isEmpty ? 0 : (values.reduce(0, +) / Double(values.count)) / 60.0
    }

    private func observeChanges() {
        ruleManager.$rules
            .receive(on: RunLoop.main)
            .sink { [weak self] rules in
                self?.rules = rules
                self?.refreshShieldStates()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshShieldStates()
                self?.refreshUsageSummary()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.loadData() }
            .store(in: &cancellables)
    }
}

// MARK: - RuleStatusBadge

enum RuleStatusBadge {
    case active, locked, disabled, offToday

    static func make(for rule: AppRule, isShielded: Bool) -> RuleStatusBadge {
        if !rule.isEnabled { return .disabled }
        if isShielded { return .locked }
        if !rule.schedule.isActiveNow { return .offToday }
        return .active
    }

    var label: String {
        switch self {
        case .active:   return "Active"
        case .locked:   return "Locked"
        case .disabled: return "Disabled"
        case .offToday: return "Off today"
        }
    }

    var color: Color {
        switch self {
        case .active:   return Color(red: 0.55, green: 0.62, blue: 0.98)  // soft periwinkle
        case .locked:   return Color(red: 0.85, green: 0.45, blue: 0.55)  // muted rose
        case .disabled: return .secondary
        case .offToday: return Color(red: 0.90, green: 0.68, blue: 0.42)  // warm amber
        }
    }
}
