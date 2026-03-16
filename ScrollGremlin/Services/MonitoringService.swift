import DeviceActivity
import ManagedSettings
import Combine
import FamilyControls
import Foundation

@MainActor
public final class MonitoringService: ObservableObject {
    private let activityCenter = DeviceActivityCenter()
    private let store = AppGroupStore.shared

    public static let shared = MonitoringService()
    private init() {}

    // MARK: - Start monitoring for a rule

    public func startMonitoring(for rule: AppRule) throws {
        guard rule.isEnabled, let selection = rule.selection else { return }
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else { return }

        var registeredNames: [String] = []

        switch rule.policy.type {

        case .daily:
            let schedule = DeviceActivitySchedule(
                intervalStart: rule.schedule.intervalStart,
                intervalEnd: rule.schedule.intervalEnd,
                repeats: true,
                warningTime: warningComponents(for: rule)
            )
            let event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(minute: rule.policy.allowedMinutes)
            )
            let name = DeviceActivityName(rule.activityName)
            try activityCenter.startMonitoring(
                name,
                during: schedule,
                events: [DeviceActivityEvent.Name(rule.eventName): event]
            )
            registeredNames = [name.rawValue]

        case .recurringInterval:
            // Only register if the outer schedule says the rule is active today.
            // If not active (wrong day/time), save an empty policy and skip.
            guard rule.schedule.isActiveNow else {
                saveMonitorPolicy(for: rule, activityNames: [])
                return
            }
            // Skip re-registration if the user has already unlocked until end of day.
            let dailyState = store.loadDailyState(ruleID: rule.id)
            if dailyState?.isUnlockedUntilEndOfDay == true && dailyState?.date == AppGroupStore.todayString {
                return
            }
            let slots = remainingSlots(intervalHours: rule.policy.intervalHours)
            let event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(minute: rule.policy.allowedMinutes)
            )
            for slot in slots {
                let name  = DeviceActivityName("\(rule.activityName)-slot-\(slot.index)")
                let eName = DeviceActivityEvent.Name("\(rule.eventName)-slot-\(slot.index)")
                let schedule = DeviceActivitySchedule(
                    intervalStart: slot.start,
                    intervalEnd: slot.end,
                    repeats: false
                )
                do {
                    try activityCenter.startMonitoring(name, during: schedule, events: [eName: event])
                    registeredNames.append(name.rawValue)
                } catch {
                    AppLogger.log(
                        error: error,
                        context: "Failed to start recurring monitoring slot \(slot.index) for rule \(rule.id)",
                        category: "Monitoring"
                    )
                }
            }
        }

        saveMonitorPolicy(for: rule, activityNames: registeredNames)
    }

    // MARK: - Stop monitoring for a rule

    public func stopMonitoring(for rule: AppRule) {
        // Cancel every DeviceActivityName registered for this rule (daily or slots).
        let policies = store.loadMonitorPolicies()
        if let policy = policies.first(where: { $0.ruleID == rule.id }),
           !policy.registeredActivityNames.isEmpty {
            activityCenter.stopMonitoring(policy.registeredActivityNames.map { DeviceActivityName($0) })
        } else {
            // Fallback: stop by base name.
            activityCenter.stopMonitoring([DeviceActivityName(rule.activityName)])
        }
        removeShield(for: rule)
    }

    // MARK: - Stop remaining slot activities (used by untilEndOfDay unlock)

    /// Cancels all pre-registered slot activities for a recurring-interval rule.
    /// Does NOT touch the shield — caller is responsible for removing it first.
    public func stopRemainingSlotMonitoring(for rule: AppRule) {
        let policies = store.loadMonitorPolicies()
        guard let policy = policies.first(where: { $0.ruleID == rule.id }),
              !policy.registeredActivityNames.isEmpty else { return }
        activityCenter.stopMonitoring(policy.registeredActivityNames.map { DeviceActivityName($0) })
    }

    // MARK: - Start grace-period monitoring (after unlock)

    public func startGraceMonitoring(for rule: AppRule, gracePeriodMinutes: Int) throws {
        guard let selection = rule.selection else { return }

        let sessionID = UUID().uuidString
        let graceName = "grace-\(rule.id)-\(sessionID)"

        let now = Date()
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: now)
        let endTime = now.addingTimeInterval(TimeInterval(gracePeriodMinutes * 60))
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            threshold: DateComponents(minute: gracePeriodMinutes)
        )
        try activityCenter.startMonitoring(
            DeviceActivityName(graceName),
            during: schedule,
            events: [DeviceActivityEvent.Name("grace-limit-\(rule.id)"): event]
        )
    }

    // MARK: - Remove shield (called on unlock)

    public func removeShield(for rule: AppRule) {
        let settingsStore = ManagedSettingsStore(named: ManagedSettingsStore.Name(rule.storeName))
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
        store.setShielded(rule.id, isShielded: false)
    }

    // MARK: - Update monitoring when rule changes

    public func updateMonitoring(for rule: AppRule) throws {
        stopMonitoring(for: rule)
        if rule.isEnabled {
            try startMonitoring(for: rule)
        }
    }

    // MARK: - Start all active rules (call on app launch / foreground)
    //
    // For recurring-interval rules this re-registers today's remaining slots,
    // which handles the case where slots ran out overnight without the app open.

    public func startAllActive() {
        let rules = store.loadRules().filter { $0.isEnabled }
        for rule in rules {
            do {
                try startMonitoring(for: rule)
            } catch {
                AppLogger.log(error: error, context: "Failed to start monitoring for rule \(rule.id)", category: "Monitoring")
            }
        }
    }

    // MARK: - Slot calculation

    /// Midnight-aligned slots of `intervalHours` each, from the current slot to end of day.
    /// Capped at 15 to stay safely under DeviceActivity's concurrent-activity limit.
    static func remainingSlots(intervalHours: Int) -> [(index: Int, start: DateComponents, end: DateComponents)] {
        let hour = Calendar.current.component(.hour, from: Date())
        var slotStart = (hour / intervalHours) * intervalHours
        var results: [(index: Int, start: DateComponents, end: DateComponents)] = []

        while slotStart < 24, results.count < 15 {
            let rawEnd  = slotStart + intervalHours
            let endHour = rawEnd >= 24 ? 23 : rawEnd
            let endMin  = rawEnd >= 24 ? 59 : 0
            results.append((
                index: slotStart / intervalHours,
                start: DateComponents(hour: slotStart, minute: 0),
                end:   DateComponents(hour: endHour,   minute: endMin)
            ))
            slotStart += intervalHours
        }
        return results
    }

    private func remainingSlots(intervalHours: Int) -> [(index: Int, start: DateComponents, end: DateComponents)] {
        MonitoringService.remainingSlots(intervalHours: intervalHours)
    }

    // MARK: - Private helpers

    private func warningComponents(for rule: AppRule) -> DateComponents? {
        let settings = store.loadSettings()
        guard settings.warningMinutes > 0 else { return nil }
        let threshold = rule.policy.allowedMinutes - settings.warningMinutes
        guard threshold > 0 else { return nil }
        return DateComponents(minute: threshold)
    }

    private func saveMonitorPolicy(for rule: AppRule, activityNames: [String]) {
        let policy = MonitorPolicy(from: rule, registeredActivityNames: activityNames)
        var policies = store.loadMonitorPolicies()
        if let idx = policies.firstIndex(where: { $0.ruleID == rule.id }) {
            policies[idx] = policy
        } else {
            policies.append(policy)
        }
        store.saveMonitorPolicies(policies)
    }
}
