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

    private let store = AppGroupStore.shared
    private let monitoringService = MonitoringService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadData()
        observeChanges()
    }

    // MARK: - Data loading

    func loadData() {
        rules = store.loadRules()
        refreshShieldStates()
        RuleManager.shared.handlePendingUnlockRequest()
    }

    func refreshShieldStates() {
        shieldStates = Dictionary(
            uniqueKeysWithValues: rules.map { ($0.id, store.isShielded($0.id)) }
        )
    }

    // MARK: - Mutations

    func addRule(_ rule: AppRule) {
        rules.append(rule)
        store.saveRules(rules)
        try? monitoringService.startMonitoring(for: rule)
        refreshShieldStates()
    }

    func deleteRule(_ rule: AppRule) {
        monitoringService.stopMonitoring(for: rule)
        rules.removeAll { $0.id == rule.id }
        store.saveRules(rules)
        refreshShieldStates()
    }

    func updateRule(_ rule: AppRule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
        store.saveRules(rules)
        try? monitoringService.updateMonitoring(for: rule)
        refreshShieldStates()
    }

    func toggleRule(_ rule: AppRule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx].isEnabled.toggle()
        store.saveRules(rules)
        try? monitoringService.updateMonitoring(for: rules[idx])
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
        if !rule.isEnabled              { return .disabled }
        if shieldStates[rule.id] == true { return .locked  }
        if !rule.schedule.isActiveNow   { return .offToday }
        return .active
    }

    private func sectionPriority(_ days: Set<Int>) -> Int {
        if days == Set(1...7)            { return 0 }
        if days == Set([2, 3, 4, 5, 6]) { return 1 }
        if days == Set([1, 7])           { return 2 }
        return 3 + (days.map { ($0 - 2 + 7) % 7 }.min() ?? 6) // custom: Monday-first order
    }

    private func observeChanges() {
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.refreshShieldStates() }
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
        case .active:   return .green
        case .locked:   return .red
        case .disabled: return .secondary
        case .offToday: return .orange
        }
    }
}
