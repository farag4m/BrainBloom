import SwiftUI
import Combine

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
    private var unlockSessions: [UnlockSession] = []

    init() {
        loadData()
        observeChanges()
    }

    // MARK: - Data loading

    func loadData() {
        ruleManager.reloadRules()
        rules = ruleManager.rules
        refreshShieldStates()
        refreshUnlockSessions()
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
        performRuleMutation("add rule \(rule.id)") {
            try ruleManager.addRule(rule)
        }
    }

    func deleteRule(_ rule: AppRule) {
        ruleManager.deleteRule(id: rule.id)
        rules = ruleManager.rules
        refreshShieldStates()
    }

    func updateRule(_ rule: AppRule) {
        performRuleMutation("update rule \(rule.id)") {
            try ruleManager.updateRule(rule)
        }
    }

    func toggleRule(_ rule: AppRule) {
        performRuleMutation("toggle rule \(rule.id)") {
            try ruleManager.toggleRule(id: rule.id)
        }
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

    /// Derives badge atomically with the rule snapshot - call site gets one consistent object.
    private func makeDisplayItem(_ rule: AppRule) -> RuleDisplayItem {
        RuleDisplayItem(
            rule: rule,
            badge: computeBadge(for: rule),
            activeSession: UnlockSessionQueries.activeSession(for: rule.id, in: unlockSessions)
        )
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
        weeklyAverageMinutes = UsageInsights.weeklyAverageMinutes(from: summaries)
        hasUsageData = UsageInsights.hasWeeklyUsageData(summaries)
    }

    private func refreshUnlockSessions() {
        unlockSessions = store.loadUnlockSessions()
    }

    private func observeChanges() {
        ruleManager.$rules
            .receive(on: RunLoop.main)
            .sink { [weak self] rules in
                self?.rules = rules
                self?.refreshShieldStates()
                self?.refreshUnlockSessions()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshShieldStates()
                self?.refreshUnlockSessions()
                self?.refreshUsageSummary()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.loadData() }
            .store(in: &cancellables)
    }

    private func performRuleMutation(_ context: String, mutation: () throws -> Void) {
        do {
            try mutation()
            rules = ruleManager.rules
            refreshShieldStates()
            refreshUnlockSessions()
        } catch {
            AppLogger.log(error: error, context: "Failed to \(context)", category: "Dashboard")
        }
    }
}
