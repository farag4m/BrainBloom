import Combine
import SwiftUI
import FamilyControls

@MainActor
final class RuleEditorViewModel: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var ruleName: String = ""
    @Published var ruleMode: RuleMode = .daily
    @Published var allowedMinutes: Int = 30
    @Published var intervalHours: Int = 1       // preserved for existing interval rules
    @Published var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @Published var startHour: Int = 0
    @Published var startMinute: Int = 0
    @Published var endHour: Int = 23
    @Published var endMinute: Int = 59
    @Published var showPicker = false
    @Published var requestDelete = false
    // "default" sentinel = use Settings value; otherwise the rawValue of the chosen type
    @Published var unlockDurationKey: String = "default"
    @Published var frictionKey: String = "default"

    let defaultUnlockType: UnlockType
    let defaultFriction: FrictionType
    var unlockDuration: UnlockType?   { UnlockType(rawValue: unlockDurationKey) }
    var frictionOverride: FrictionType? { FrictionType(rawValue: frictionKey) }

    let existingRule: AppRule?

    /// Edit an existing rule, or create a blank new one (rule == nil).
    init(rule: AppRule?) {
        let settings = AppGroupStore.shared.loadSettings()
        self.defaultUnlockType = settings.defaultUnlockType
        self.defaultFriction = settings.defaultFriction
        self.existingRule = rule
        if let rule = rule {
            self.ruleName = rule.name
            self.allowedMinutes = rule.policy.allowedMinutes
            self.intervalHours = rule.policy.type == .recurringInterval ? rule.policy.intervalHours : 1
            self.activeDays = rule.schedule.activeDays
            self.startHour = rule.schedule.startHour
            self.startMinute = rule.schedule.startMinute
            self.endHour = rule.schedule.endHour
            self.endMinute = rule.schedule.endMinute
            if let sel = rule.selection { self.selection = sel }
            self.unlockDurationKey = rule.unlockDurationOverride?.rawValue ?? "default"
            self.frictionKey = rule.frictionOverride?.rawValue ?? "default"
            self.ruleMode = resolveInitialMode(policy: rule.policy, schedule: rule.schedule)
        }
    }

    /// Create a new rule pre-populated with a schedule template (e.g. Work 9-5).
    /// isEditing stays false - no Delete button, title reads "New Rule".
    init(templateSchedule: RuleSchedule) {
        let settings = AppGroupStore.shared.loadSettings()
        self.defaultUnlockType = settings.defaultUnlockType
        self.defaultFriction = settings.defaultFriction
        self.existingRule = nil
        self.activeDays = templateSchedule.activeDays
        self.startHour = templateSchedule.startHour
        self.startMinute = templateSchedule.startMinute
        self.endHour = templateSchedule.endHour
        self.endMinute = templateSchedule.endMinute
        self.ruleMode = .scheduledWindow
    }

    var isEditing: Bool { existingRule != nil }
    var hasSelection: Bool { !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty }
    var isValid: Bool {
        hasSelection
            && !ruleName.trimmingCharacters(in: .whitespaces).isEmpty
            && validationResult.isValid
    }
    var hasValidScheduleWindow: Bool {
        guard ruleMode == .scheduledWindow else { return true }
        return startTotalMinutes < endTotalMinutes
    }
    var scheduleValidationMessage: String? {
        validationResult.scheduleMessage
    }

    var policyValidationMessage: String? {
        validationResult.policyMessage
    }

    var maxAllowanceMinutes: Int {
        validationResult.maxAllowanceMinutes
    }

    var selectionSummary: String {
        let appCount = selection.applicationTokens.count
        let catCount = selection.categoryTokens.count
        if appCount == 0 && catCount == 0 { return "Tap to select apps" }
        var parts: [String] = []
        if appCount > 0 { parts.append("\(appCount) app\(appCount == 1 ? "" : "s")") }
        if catCount > 0 { parts.append("\(catCount) categor\(catCount == 1 ? "y" : "ies")") }
        return parts.joined(separator: ", ")
    }

    var policyPreview: String { buildPolicy().displayLabel }

    private var validationResult: RuleValidationResult {
        RuleValidation.validate(
            mode: ruleMode,
            allowedMinutes: allowedMinutes,
            intervalHours: intervalHours,
            schedule: RuleSchedule(
                activeDays: activeDays,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute
            )
        )
    }

    func buildRule() -> AppRule? {
        guard isValid else { return nil }
        let schedule = RuleSchedule(
            activeDays: activeDays,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
        return AppRule(
            id: existingRule?.id ?? UUID(),
            name: ruleName.trimmingCharacters(in: .whitespaces),
            selection: selection,
            policy: buildPolicy(),
            schedule: schedule,
            frictionOverride: frictionOverride,
            unlockDurationOverride: unlockDuration,
            createdAt: existingRule?.createdAt ?? Date()
        )
    }

    private func buildPolicy() -> UsagePolicy {
        switch ruleMode {
        case .daily:
            return .daily(minutes: allowedMinutes)
        case .hourly:
            let hours = max(1, min(intervalHours, 24))
            return .recurring(minutes: allowedMinutes, everyHours: hours)
        case .scheduledWindow:
            return .daily(minutes: allowedMinutes)
        }
    }

    private func resolveInitialMode(policy: UsagePolicy, schedule: RuleSchedule) -> RuleMode {
        if !isFullDay(schedule: schedule) {
            return .scheduledWindow
        }
        switch policy.type {
        case .daily:
            return .daily
        case .recurringInterval:
            return .hourly
        }
    }

    private func isFullDay(schedule: RuleSchedule) -> Bool {
        let allDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        return schedule.activeDays == allDays
            && schedule.startHour == 0
            && schedule.startMinute == 0
            && schedule.endHour == 23
            && schedule.endMinute == 59
    }

    func resetScheduleToAllDay() {
        activeDays = [1, 2, 3, 4, 5, 6, 7]
        startHour = 0
        startMinute = 0
        endHour = 23
        endMinute = 59
    }

    private var startTotalMinutes: Int {
        (startHour * 60) + startMinute
    }

    private var endTotalMinutes: Int {
        (endHour * 60) + endMinute
    }
}
