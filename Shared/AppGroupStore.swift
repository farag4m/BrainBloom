import Foundation

public final class AppGroupStore {
    public static var appGroupID: String { AppConfig.appGroupID }
    public static let shared = AppGroupStore()
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        if let defaults = UserDefaults(suiteName: AppConfig.appGroupID) {
            self.defaults = defaults
        } else {
            AppLogger.log("App Group not configured: \(AppConfig.appGroupID). Falling back to standard UserDefaults.", category: "Storage")
            self.defaults = .standard
        }
    }

    // MARK: - Rules

    public func saveRules(_ rules: [AppRule]) {
        saveValue(rules, forKey: Keys.rules, context: "Saving rules")
    }

    public func loadRules() -> [AppRule] {
        loadValue([AppRule].self, forKey: Keys.rules, defaultValue: [])
    }

    // MARK: - Settings

    public func saveSettings(_ settings: UserSettings) {
        saveValue(settings, forKey: Keys.settings, context: "Saving settings")
    }

    public func loadSettings() -> UserSettings {
        loadValue(UserSettings.self, forKey: Keys.settings, defaultValue: .default)
    }

    // MARK: - Daily State

    public func saveDailyState(_ state: DailyState) {
        var all = loadAllDailyStates()
        all[state.storageKey] = state
        saveValue(all, forKey: Keys.dailyState, context: "Saving daily state")
    }

    public func loadDailyState(ruleID: UUID, date: String = AppGroupStore.todayString) -> DailyState? {
        loadAllDailyStates()["\(ruleID)-\(date)"]
    }

    private func loadAllDailyStates() -> [String: DailyState] {
        loadValue([String: DailyState].self, forKey: Keys.dailyState, defaultValue: [:])
    }

    // MARK: - Pending Unlock Request

    public func setPendingUnlockRequest(_ request: UnlockRequest) {
        saveValue(request, forKey: Keys.pendingUnlock, context: "Saving pending unlock request")
    }

    public func loadPendingUnlockRequest() -> UnlockRequest? {
        guard let request: UnlockRequest = loadOptionalValue(UnlockRequest.self, forKey: Keys.pendingUnlock) else {
            return nil
        }
        guard Date().timeIntervalSince(request.requestedAt) < 300 else {
            clearPendingUnlockRequest()
            return nil
        }
        return request
    }

    public func clearPendingUnlockRequest() {
        defaults.removeObject(forKey: Keys.pendingUnlock)
    }

    // MARK: - Unlock Sessions

    public func appendUnlockSession(_ session: UnlockSession) {
        var sessions = loadUnlockSessions()
        sessions.append(session)
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        sessions = sessions.filter { $0.startedAt > cutoff }
        saveValue(sessions, forKey: Keys.unlockSessions, context: "Saving unlock sessions")
    }

    public func loadUnlockSessions() -> [UnlockSession] {
        loadValue([UnlockSession].self, forKey: Keys.unlockSessions, defaultValue: [])
    }

    public func clearUnlockSessions() {
        defaults.removeObject(forKey: Keys.unlockSessions)
    }

    // MARK: - Shield State

    public func setShielded(_ ruleID: UUID, isShielded: Bool) {
        var state = loadShieldState()
        state[ruleID.uuidString] = isShielded
        defaults.set(state, forKey: Keys.shieldState)
    }

    public func isShielded(_ ruleID: UUID) -> Bool {
        loadShieldState()[ruleID.uuidString] ?? false
    }

    public func allShieldStates() -> [String: Bool] {
        loadShieldState()
    }

    private func loadShieldState() -> [String: Bool] {
        defaults.dictionary(forKey: Keys.shieldState) as? [String: Bool] ?? [:]
    }

    // MARK: - Monitor Policies

    public func saveMonitorPolicies(_ policies: [MonitorPolicy]) {
        saveValue(policies, forKey: Keys.monitorPolicies, context: "Saving monitor policies")
    }

    public func loadMonitorPolicies() -> [MonitorPolicy] {
        loadValue([MonitorPolicy].self, forKey: Keys.monitorPolicies, defaultValue: [])
    }

    // MARK: - Usage Summary

    public func saveUsageSummaries(_ summaries: [UsageDaySummary]) {
        saveValue(summaries, forKey: Keys.usageSummary, context: "Saving usage summaries")
    }

    public func loadUsageSummaries() -> [UsageDaySummary] {
        loadValue([UsageDaySummary].self, forKey: Keys.usageSummary, defaultValue: [])
    }

    // MARK: - Helpers

    public static var todayString: String {
        dayFormatter.string(from: Date())
    }

    public static func dayString(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private enum Keys {
        static let rules = "rules_v2"           // bumped: AppRule.policy replaced dailyLimitMinutes
        static let settings = "settings_v1"
        static let dailyState = "daily_state_v1"
        static let pendingUnlock = "pending_unlock_v1"
        static let unlockSessions = "unlock_sessions_v1"
        static let shieldState = "shield_state_v1"
        static let monitorPolicies = "monitor_policies_v2"  // bumped: MonitorPolicy.policy added
        static let usageSummary = "usage_summary_v1"
    }

    private func saveValue<Value: Encodable>(_ value: Value, forKey key: String, context: String) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            AppLogger.log(error: error, context: context, category: "Storage")
        }
    }

    private func loadValue<Value: Decodable>(_ type: Value.Type, forKey key: String, defaultValue: Value) -> Value {
        guard let data = defaults.data(forKey: key) else {
            return defaultValue
        }

        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            AppLogger.log(error: error, context: "Loading \(key)", category: "Storage")
            return defaultValue
        }
    }

    private func loadOptionalValue<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            AppLogger.log(error: error, context: "Loading \(key)", category: "Storage")
            return nil
        }
    }
}
