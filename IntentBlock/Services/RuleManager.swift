import Foundation
import Combine

@MainActor
public final class RuleManager: ObservableObject {
    public static let shared = RuleManager()

    @Published public var rules: [AppRule] = []
    @Published public var showUnlockFlow = false
    @Published public var unlockRuleID: UUID?

    private let store = AppGroupStore.shared
    private let monitoringService = MonitoringService.shared

    private init() {
        rules = store.loadRules()
    }

    public func addRule(_ rule: AppRule) throws {
        rules.append(rule)
        store.saveRules(rules)
        try monitoringService.startMonitoring(for: rule)
    }

    public func updateRule(_ rule: AppRule) throws {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
        store.saveRules(rules)
        try monitoringService.updateMonitoring(for: rule)
    }

    public func deleteRule(id: UUID) {
        guard let rule = rules.first(where: { $0.id == id }) else { return }
        monitoringService.stopMonitoring(for: rule)
        rules.removeAll { $0.id == id }
        store.saveRules(rules)
    }

    public func handlePendingUnlockRequest() {
        guard let request = store.loadPendingUnlockRequest() else { return }
        unlockRuleID = request.ruleID
        showUnlockFlow = true
    }

    public func reloadRules() {
        rules = store.loadRules()
    }
}
