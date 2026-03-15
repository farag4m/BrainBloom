import Foundation

public final class AppGroupStore {
    public static let appGroupID = "group.com.yourco.scrollgremlin"
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
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            fatalError("App Group not configured: \(Self.appGroupID)")
        }
        self.defaults = defaults
    }

    // MARK: - Rules

    public func saveRules(_ rules: [AppRule]) {
        defaults.set(try? encoder.encode(rules), forKey: Keys.rules)
    }

    public func loadRules() -> [AppRule] {
        guard let data = defaults.data(forKey: Keys.rules),
              let rules = try? decoder.decode([AppRule].self, from: data) else {
            return []
        }
        return rules
    }

    // MARK: - Settings

    public func saveSettings(_ settings: UserSettings) {
        defaults.set(try? encoder.encode(settings), forKey: Keys.settings)
    }

    public func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? decoder.decode(UserSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    // MARK: - Daily State

    public func saveDailyState(_ state: DailyState) {
        var all = loadAllDailyStates()
        all[state.storageKey] = state
        defaults.set(try? encoder.encode(all), forKey: Keys.dailyState)
    }

    public func loadDailyState(ruleID: UUID, date: String = AppGroupStore.todayString) -> DailyState? {
        loadAllDailyStates()["\(ruleID)-\(date)"]
    }

    private func loadAllDailyStates() -> [String: DailyState] {
        guard let data = defaults.data(forKey: Keys.dailyState),
              let all = try? decoder.decode([String: DailyState].self, from: data) else {
            return [:]
        }
        return all
    }

    // MARK: - Pending Unlock Request

    public func setPendingUnlockRequest(_ request: UnlockRequest) {
        defaults.set(try? encoder.encode(request), forKey: Keys.pendingUnlock)
    }

    public func loadPendingUnlockRequest() -> UnlockRequest? {
        guard let data = defaults.data(forKey: Keys.pendingUnlock),
              let request = try? decoder.decode(UnlockRequest.self, from: data) else {
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
        defaults.set(try? encoder.encode(sessions), forKey: Keys.unlockSessions)
    }

    public func loadUnlockSessions() -> [UnlockSession] {
        guard let data = defaults.data(forKey: Keys.unlockSessions),
              let sessions = try? decoder.decode([UnlockSession].self, from: data) else {
            return []
        }
        return sessions
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
        defaults.set(try? encoder.encode(policies), forKey: Keys.monitorPolicies)
    }

    public func loadMonitorPolicies() -> [MonitorPolicy] {
        guard let data = defaults.data(forKey: Keys.monitorPolicies),
              let policies = try? decoder.decode([MonitorPolicy].self, from: data) else {
            return []
        }
        return policies
    }

    // MARK: - Helpers

    public static var todayString: String {
        dayFormatter.string(from: Date())
    }

    private enum Keys {
        static let rules = "rules_v2"           // bumped: AppRule.policy replaced dailyLimitMinutes
        static let settings = "settings_v1"
        static let dailyState = "daily_state_v1"
        static let pendingUnlock = "pending_unlock_v1"
        static let unlockSessions = "unlock_sessions_v1"
        static let shieldState = "shield_state_v1"
        static let monitorPolicies = "monitor_policies_v2"  // bumped: MonitorPolicy.policy added
    }
}
