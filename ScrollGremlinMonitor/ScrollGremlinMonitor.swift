import DeviceActivity
import ManagedSettings
import UserNotifications
import Foundation

// IMPORTANT: This extension has a ~5 MB memory limit.
// No Combine, no SwiftUI, no networking. Struct-based models only.
//
// NOTE ON RECURRING INTERVALS:
// The monitor extension cannot call DeviceActivityCenter.startMonitoring because
// that API requires com.apple.developer.family-controls, granted only to the main app.
// The main app pre-registers all remaining day slots when monitoring starts and on
// every app foreground. This extension only reacts to threshold/interval events.

class ScrollGremlinMonitor: DeviceActivityMonitor {

    private let groupStore = AppGroupStore.shared

    // MARK: - Threshold reached: shield the app

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        guard let ruleID = extractRuleID(from: activity) else { return }
        applyShield(for: ruleID)
        updateDailyState(ruleID: ruleID, shielded: true)
        postNotification(type: .locked, ruleID: ruleID)
    }

    // MARK: - Warning before threshold

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        guard let ruleID = extractRuleID(from: activity) else { return }
        postNotification(type: .warning, ruleID: ruleID)
    }

    // MARK: - Interval ended
    //
    // For daily rules: fires at schedule end (e.g. 23:59). Shield removed; the main app
    // re-registers on next foreground via startAllActive().
    // For recurring-interval slots: fires at end of each N-hour slot. Remove shield so the
    // next pre-registered slot starts clean. No re-registration needed — main app already
    // registered all remaining slots for today when monitoring was set up.

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard let ruleID = extractRuleID(from: activity) else { return }
        removeShield(for: ruleID)
        updateDailyState(ruleID: ruleID, shielded: false)
    }

    // MARK: - Interval started
    //
    // For daily rules: fires at the start of a new day — reset the daily state.
    // For recurring slots: also fires at each slot start mid-day. Guard against
    // clobbering accumulated state by only resetting on genuine new-day starts.

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let ruleID = extractRuleID(from: activity) else { return }

        let existingState = groupStore.loadDailyState(ruleID: ruleID)
        if existingState?.date != AppGroupStore.todayString {
            groupStore.saveDailyState(DailyState(ruleID: ruleID))
        }
    }

    // MARK: - Shield logic

    private func applyShield(for ruleID: UUID) {
        guard let policy = loadPolicy(for: ruleID) else { return }
        let settingsStore = ManagedSettingsStore(
            named: ManagedSettingsStore.Name("scrollgremlin-\(ruleID.uuidString)")
        )
        if let data = policy.applicationTokensData,
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data) {
            settingsStore.shield.applications = tokens
        }
        if let data = policy.categoryTokensData,
           let tokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: data) {
            settingsStore.shield.applicationCategories = .specific(tokens)
        }
        groupStore.setShielded(ruleID, isShielded: true)
    }

    private func removeShield(for ruleID: UUID) {
        let settingsStore = ManagedSettingsStore(
            named: ManagedSettingsStore.Name("scrollgremlin-\(ruleID.uuidString)")
        )
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = .none
        groupStore.setShielded(ruleID, isShielded: false)
    }

    // MARK: - Helpers

    private func extractRuleID(from activity: DeviceActivityName) -> UUID? {
        // Name formats:
        //   daily:  "rule-{uuid}"                     → parts[1...5]
        //   slot:   "rule-{uuid}-slot-{N}"             → parts[1...5]
        //   grace:  "grace-{uuid}-{sessionUUID}"       → parts[1...5]
        // The UUID always occupies parts[1...5] after splitting on "-".
        let parts = activity.rawValue.components(separatedBy: "-")
        guard parts.count >= 6 else { return nil }
        return UUID(uuidString: parts[1...5].joined(separator: "-"))
    }

    private func loadPolicy(for ruleID: UUID) -> MonitorPolicy? {
        groupStore.loadMonitorPolicies().first { $0.ruleID == ruleID }
    }

    private func updateDailyState(ruleID: UUID, shielded: Bool) {
        var state = groupStore.loadDailyState(ruleID: ruleID) ?? DailyState(ruleID: ruleID)
        state.isCurrentlyShielded = shielded
        if shielded { state.thresholdReachedAt = Date() }
        groupStore.saveDailyState(state)
    }

    // MARK: - Notifications

    private enum NotifType { case warning, locked }

    private func postNotification(type: NotifType, ruleID: UUID) {
        let settings = groupStore.loadSettings()
        guard settings.notificationsEnabled else { return }

        let isRecurring = loadPolicy(for: ruleID)?.policy.type == .recurringInterval

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch type {
        case .warning:
            content.title = "Almost at your limit"
            content.body = isRecurring
                ? "You're almost out of time for this interval."
                : "You're close to your daily limit."
        case .locked:
            content.title = "Time's up"
            content.body = isRecurring
                ? "You've used your allowance for this interval. The next slot resets automatically."
                : "You've reached your daily limit. Open \(AppName.displayName) to continue."
            content.userInfo = ["ruleID": ruleID.uuidString]
        }

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: "scrollgremlin-\(type)-\(ruleID)",
                content: content,
                trigger: nil
            )
        )
    }
}
