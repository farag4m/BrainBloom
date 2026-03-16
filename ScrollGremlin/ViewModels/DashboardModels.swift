import SwiftUI

struct RuleDisplayItem: Identifiable {
    let rule: AppRule
    let badge: RuleStatusBadge
    let activeSession: UnlockSession?

    var id: UUID { rule.id }
}

struct DayGroup: Identifiable {
    let activeDays: Set<Int>
    let items: [RuleDisplayItem]

    var id: String { activeDays.sorted().map(String.init).joined(separator: "-") }
    var title: String { DayGroup.title(for: activeDays) }

    static func title(for days: Set<Int>) -> String {
        if days == Set(1...7) { return "Every Day" }
        if days == Set([2, 3, 4, 5, 6]) { return "Weekdays" }
        if days == Set([1, 7]) { return "Weekends" }

        let dayNames: [Int: String] = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        return days
            .sorted { ($0 - 2 + 7) % 7 < ($1 - 2 + 7) % 7 }
            .compactMap { dayNames[$0] }
            .joined(separator: " · ")
    }
}

enum RuleStatusBadge {
    case active
    case locked
    case disabled
    case offToday

    static func make(for rule: AppRule, isShielded: Bool) -> RuleStatusBadge {
        if !rule.isEnabled { return .disabled }
        if isShielded { return .locked }
        if !rule.schedule.isActiveNow { return .offToday }
        return .active
    }

    var label: String {
        switch self {
        case .active:
            return "Active"
        case .locked:
            return "Locked"
        case .disabled:
            return "Disabled"
        case .offToday:
            return "Off today"
        }
    }

    var color: Color {
        switch self {
        case .active:
            return Color(red: 0.55, green: 0.62, blue: 0.98)
        case .locked:
            return Color(red: 0.85, green: 0.45, blue: 0.55)
        case .disabled:
            return .secondary
        case .offToday:
            return Color(red: 0.90, green: 0.68, blue: 0.42)
        }
    }
}
