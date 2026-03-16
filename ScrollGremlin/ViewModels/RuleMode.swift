import Foundation

enum RuleMode: String, CaseIterable {
    case daily
    case hourly
    case scheduledWindow

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .hourly: return "Hourly"
        case .scheduledWindow: return "Scheduled Window"
        }
    }

    var helperText: String {
        switch self {
        case .daily:
            return "Block after the daily allowance is used. Resets at midnight."
        case .hourly:
            return "Block after the hourly allowance is used. Resets each hour."
        case .scheduledWindow:
            return "Allowance applies only during the scheduled window."
        }
    }
}
