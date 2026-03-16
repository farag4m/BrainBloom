import Foundation

struct RuleValidationResult {
    let isValid: Bool
    let scheduleMessage: String?
    let policyMessage: String?
    let maxAllowanceMinutes: Int
}

enum RuleValidation {
    static func validate(
        mode: RuleMode,
        allowedMinutes: Int,
        intervalHours: Int,
        schedule: RuleSchedule
    ) -> RuleValidationResult {
        let scheduleCheck = validateSchedule(mode: mode, schedule: schedule)
        let policyCheck = validatePolicy(mode: mode, allowedMinutes: allowedMinutes, intervalHours: intervalHours, schedule: schedule)
        let isValid = scheduleCheck.isValid && policyCheck.isValid
        let maxAllowance = policyCheck.maxAllowanceMinutes
        return RuleValidationResult(
            isValid: isValid,
            scheduleMessage: scheduleCheck.message,
            policyMessage: policyCheck.message,
            maxAllowanceMinutes: maxAllowance
        )
    }

    private static func validateSchedule(mode: RuleMode, schedule: RuleSchedule) -> (isValid: Bool, message: String?) {
        if mode == .scheduledWindow {
            let start = schedule.startHour * 60 + schedule.startMinute
            let end = schedule.endHour * 60 + schedule.endMinute
            if start >= end {
                return (
                    false,
                    "Scheduled windows must start and end on the same day. Choose an end time later than the start time."
                )
            }
            if schedule.activeDays.isEmpty {
                return (false, "Select at least one active day.")
            }
            return (true, nil)
        }

        if schedule != .allDayEveryDay {
            return (false, "Schedule is only available for Scheduled Window mode.")
        }

        return (true, nil)
    }

    private static func validatePolicy(
        mode: RuleMode,
        allowedMinutes: Int,
        intervalHours: Int,
        schedule: RuleSchedule
    ) -> (isValid: Bool, message: String?, maxAllowanceMinutes: Int) {
        let maxAllowance: Int
        switch mode {
        case .daily:
            maxAllowance = 24 * 60
        case .hourly:
            let hours = max(1, min(intervalHours, 24))
            maxAllowance = hours * 60
        case .scheduledWindow:
            let start = schedule.startHour * 60 + schedule.startMinute
            let end = schedule.endHour * 60 + schedule.endMinute
            maxAllowance = max(0, end - start)
        }

        if allowedMinutes < 0 {
            return (false, "Allowance must be at least 0 minutes.", maxAllowance)
        }
        if allowedMinutes > maxAllowance {
            return (false, "Allowance must fit inside the selected window.", maxAllowance)
        }

        if mode == .hourly && intervalHours <= 0 {
            return (false, "Select a reset window greater than 0.", maxAllowance)
        }

        return (true, nil, maxAllowance)
    }
}
