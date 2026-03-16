import Foundation
import FamilyControls

public enum AppName {
    public static let displayName = "Brain Bloom"
    public static let compactName = "BrainBloom"
}

// MARK: - UsagePolicy

/// Describes how much usage is allowed and over what time window.
public enum UsagePolicyType: String, Codable, CaseIterable {
    case daily              // X minutes per day; one reset at midnight
    case recurringInterval  // X minutes per N hours; resets every N hours
}

public struct UsagePolicy: Codable, Equatable, Hashable {
    public var type: UsagePolicyType
    public var allowedMinutes: Int  // usage allowed per interval
    public var intervalHours: Int   // window length: 24 for daily, 1–12 for recurring

    public init(type: UsagePolicyType, allowedMinutes: Int, intervalHours: Int) {
        self.type = type
        self.allowedMinutes = allowedMinutes
        self.intervalHours = intervalHours
    }

    public static func daily(minutes: Int) -> UsagePolicy {
        UsagePolicy(type: .daily, allowedMinutes: minutes, intervalHours: 24)
    }

    public static func recurring(minutes: Int, everyHours: Int) -> UsagePolicy {
        UsagePolicy(type: .recurringInterval, allowedMinutes: minutes, intervalHours: everyHours)
    }

    /// Human-readable summary, e.g. "4 hours per day", "20 minutes per hour", "10 minutes every 2 hours".
    public var displayLabel: String {
        let time = formatMinutes(allowedMinutes)
        switch type {
        case .daily:
            return "\(time) per day"
        case .recurringInterval:
            return intervalHours == 1 ? "\(time) per hour" : "\(time) every \(intervalHours) hours"
        }
    }

    /// Returns the (start, end) DateComponents for the current midnight-aligned slot.
    /// For daily use, returns the schedule's own start/end instead (caller handles that).
    /// For recurring: divides 00:00–23:59 into slots of `intervalHours` each and returns the active one.
    public static func currentSlotWindow(intervalHours: Int) -> (start: DateComponents, end: DateComponents) {
        let hour = Calendar.current.component(.hour, from: Date())
        let slotStart = (hour / intervalHours) * intervalHours
        let rawEnd   = slotStart + intervalHours
        let endHour  = rawEnd >= 24 ? 23 : rawEnd
        let endMin   = rawEnd >= 24 ? 59 : 0
        return (
            DateComponents(hour: slotStart, minute: 0),
            DateComponents(hour: endHour,   minute: endMin)
        )
    }

    // MARK: - Helpers

    private func formatMinutes(_ total: Int) -> String {
        let h = total / 60, m = total % 60
        if h == 0 { return m == 1 ? "1 minute" : "\(m) minutes" }
        if m == 0 { return h == 1 ? "1 hour" : "\(h) hours" }
        return "\(h)h \(m)m"
    }
}

// MARK: - AppRule

public struct AppRule: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var selectionData: Data          // JSONEncoder-encoded FamilyActivitySelection
    public var policy: UsagePolicy          // replaces dailyLimitMinutes
    public var isEnabled: Bool
    public var schedule: RuleSchedule
    public var frictionOverride: FrictionType?
    public var unlockDurationOverride: UnlockType?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        selection: FamilyActivitySelection,
        policy: UsagePolicy,
        isEnabled: Bool = true,
        schedule: RuleSchedule = .allDayEveryDay,
        frictionOverride: FrictionType? = nil,
        unlockDurationOverride: UnlockType? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.selectionData = (try? JSONEncoder().encode(selection)) ?? Data()
        self.policy = policy
        self.isEnabled = isEnabled
        self.schedule = schedule
        self.frictionOverride = frictionOverride
        self.unlockDurationOverride = unlockDurationOverride
        self.createdAt = createdAt
        self.updatedAt = Date()
    }

    public var selection: FamilyActivitySelection? {
        try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData)
    }

    public var activityName: String { "rule-\(id.uuidString)" }
    public var eventName: String    { "limit-\(id.uuidString)" }
    public var storeName: String    { "scrollgremlin-\(id.uuidString)" }
}

// MARK: - RuleSchedule

public struct RuleSchedule: Codable, Equatable {
    public var activeDays: Set<Int>         // Calendar.weekday values (1=Sun, 7=Sat)
    public var startHour: Int               // 0-23
    public var startMinute: Int             // 0-59
    public var endHour: Int
    public var endMinute: Int

    public init(activeDays: Set<Int>, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.activeDays = activeDays
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    public static let allDayEveryDay = RuleSchedule(
        activeDays: [1, 2, 3, 4, 5, 6, 7],
        startHour: 0, startMinute: 0,
        endHour: 23, endMinute: 59
    )

    /// Monday–Friday, 09:00–17:00. Used by the Work (9–5) quick preset.
    public static let workDays = RuleSchedule(
        activeDays: [2, 3, 4, 5, 6],   // 1=Sun … 7=Sat
        startHour: 9, startMinute: 0,
        endHour: 17, endMinute: 0
    )

    public var isActiveNow: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        guard activeDays.contains(weekday) else { return false }
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }

    public var intervalStart: DateComponents {
        DateComponents(hour: startHour, minute: startMinute)
    }

    public var intervalEnd: DateComponents {
        DateComponents(hour: endHour, minute: endMinute)
    }
}

// MARK: - DailyState

public struct DailyState: Codable {
    public let ruleID: UUID
    public let date: String                 // "yyyy-MM-dd"
    public var thresholdReachedAt: Date?
    public var isCurrentlyShielded: Bool
    public var activeUnlockSessionID: UUID?
    public var totalUnlockSeconds: Int
    /// Set to true when the user selects "until end of day" — suppresses slot re-registration.
    public var isUnlockedUntilEndOfDay: Bool

    public init(ruleID: UUID, date: String = AppGroupStore.todayString) {
        self.ruleID = ruleID
        self.date = date
        self.thresholdReachedAt = nil
        self.isCurrentlyShielded = false
        self.activeUnlockSessionID = nil
        self.totalUnlockSeconds = 0
        self.isUnlockedUntilEndOfDay = false
    }

    // Backward-compatible decoding: existing records without isUnlockedUntilEndOfDay decode as false.
    enum CodingKeys: String, CodingKey {
        case ruleID, date, thresholdReachedAt, isCurrentlyShielded
        case activeUnlockSessionID, totalUnlockSeconds, isUnlockedUntilEndOfDay
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ruleID = try c.decode(UUID.self, forKey: .ruleID)
        date = try c.decode(String.self, forKey: .date)
        thresholdReachedAt = try c.decodeIfPresent(Date.self, forKey: .thresholdReachedAt)
        isCurrentlyShielded = try c.decode(Bool.self, forKey: .isCurrentlyShielded)
        activeUnlockSessionID = try c.decodeIfPresent(UUID.self, forKey: .activeUnlockSessionID)
        totalUnlockSeconds = try c.decode(Int.self, forKey: .totalUnlockSeconds)
        isUnlockedUntilEndOfDay = try c.decodeIfPresent(Bool.self, forKey: .isUnlockedUntilEndOfDay) ?? false
    }
}

// MARK: - UnlockSession

public struct UnlockSession: Codable, Identifiable {
    public let id: UUID
    public let ruleID: UUID
    public let startedAt: Date
    public var expiresAt: Date?
    public var actualEndedAt: Date?
    public var unlockType: UnlockType
    public var intention: String?
    public var frictionType: FrictionType
    public var wasEndedManually: Bool

    public init(
        ruleID: UUID,
        unlockType: UnlockType,
        frictionType: FrictionType,
        intention: String? = nil
    ) {
        self.id = UUID()
        self.ruleID = ruleID
        self.startedAt = Date()
        self.unlockType = unlockType
        self.frictionType = frictionType
        self.intention = intention
        self.wasEndedManually = false
        if let minutes = unlockType.minutes {
            self.expiresAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
        }
    }
}

// MARK: - UnlockType

public enum UnlockType: String, Codable, CaseIterable {
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case untilEndOfDay

    public var minutes: Int? {
        switch self {
        case .fiveMinutes: return 5
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        case .oneHour: return 60
        case .twoHours: return 120
        case .untilEndOfDay: return nil
        }
    }

    public var displayLabel: String {
        switch self {
        case .fiveMinutes: return "5 min"
        case .fifteenMinutes: return "15 min"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .untilEndOfDay: return "Rest of Day"
        }
    }

    public var subtitle: String {
        switch self {
        case .fiveMinutes: return "Quick check"
        case .fifteenMinutes: return "Short break"
        case .thirtyMinutes: return "Longer session"
        case .oneHour: return "Extended session"
        case .twoHours: return "Long session"
        case .untilEndOfDay: return "No more limits today"
        }
    }
}

// MARK: - FrictionType

public enum FrictionType: String, Codable, CaseIterable {
    case none
    case confirmOnly
    case shortDelay
    case breathingScreen
    case typedIntention
    case full
    case mathChallenge

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .confirmOnly: return "Confirm only"
        case .shortDelay: return "Short delay (10s)"
        case .breathingScreen: return "Breathing exercise"
        case .typedIntention: return "Typed intention"
        case .full: return "Full (breathing + intention)"
        case .mathChallenge: return "Math challenge"
        }
    }

    public var includesBreathing: Bool { self == .breathingScreen || self == .full }
    public var includesIntention: Bool { self == .typedIntention || self == .full }
    public var includesDelay: Bool { self == .shortDelay }
    public var includesMath: Bool { self == .mathChallenge }
}

// MARK: - UserSettings

public struct UserSettings: Codable, Equatable {
    public var defaultFriction: FrictionType
    public var defaultUnlockType: UnlockType
    public var warningMinutes: Int          // 0=off, 5, 10
    public var notificationsEnabled: Bool
    public var requireIntentionText: Bool
    public var showStreakCounter: Bool
    public var colorScheme: AppColorScheme

    public init(
        defaultFriction: FrictionType,
        defaultUnlockType: UnlockType,
        warningMinutes: Int,
        notificationsEnabled: Bool,
        requireIntentionText: Bool,
        showStreakCounter: Bool,
        colorScheme: AppColorScheme = .light
    ) {
        self.defaultFriction = defaultFriction
        self.defaultUnlockType = defaultUnlockType
        self.warningMinutes = warningMinutes
        self.notificationsEnabled = notificationsEnabled
        self.requireIntentionText = requireIntentionText
        self.showStreakCounter = showStreakCounter
        self.colorScheme = colorScheme
    }

    public static let `default` = UserSettings(
        defaultFriction: .breathingScreen,
        defaultUnlockType: .fifteenMinutes,
        warningMinutes: 5,
        notificationsEnabled: true,
        requireIntentionText: false,
        showStreakCounter: true,
        colorScheme: .light
    )

    // Backward-compatible decoding: existing data without colorScheme defaults to .light.
    enum CodingKeys: String, CodingKey {
        case defaultFriction, defaultUnlockType, warningMinutes
        case notificationsEnabled, requireIntentionText, showStreakCounter, colorScheme
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        defaultFriction      = try c.decode(FrictionType.self,  forKey: .defaultFriction)
        defaultUnlockType    = try c.decode(UnlockType.self,     forKey: .defaultUnlockType)
        warningMinutes       = try c.decode(Int.self,            forKey: .warningMinutes)
        notificationsEnabled = try c.decode(Bool.self,           forKey: .notificationsEnabled)
        requireIntentionText = try c.decode(Bool.self,           forKey: .requireIntentionText)
        showStreakCounter     = try c.decode(Bool.self,           forKey: .showStreakCounter)
        if let rawColorScheme = try c.decodeIfPresent(String.self, forKey: .colorScheme) {
            colorScheme = AppColorScheme(rawValue: rawColorScheme) ?? .light
        } else {
            colorScheme = .light
        }
    }
}

// MARK: - UnlockRequest (cross-process bridge)

public struct UnlockRequest: Codable {
    public let id: UUID
    public let ruleID: UUID
    public let requestedAt: Date

    public init(ruleID: UUID) {
        self.id = UUID()
        self.ruleID = ruleID
        self.requestedAt = Date()
    }
}

// MARK: - MonitorPolicy (lean snapshot for extensions)
//
// Extensions cannot call DeviceActivityCenter.startMonitoring (entitlement-gated).
// This struct is written by the main app and read by ScrollGremlinMonitor.
// It carries everything the extension needs to respond to callbacks correctly.

public struct MonitorPolicy: Codable {
    public let ruleID: UUID
    public let applicationTokensData: Data?
    public let categoryTokensData: Data?
    public let policy: UsagePolicy
    public let schedule: RuleSchedule
    /// All DeviceActivityName.rawValues registered for this rule (one for daily, N for recurring slots).
    public let registeredActivityNames: [String]

    public init(from rule: AppRule, registeredActivityNames: [String]) {
        self.ruleID = rule.id
        self.policy = rule.policy
        self.schedule = rule.schedule
        self.registeredActivityNames = registeredActivityNames
        if let sel = rule.selection {
            self.applicationTokensData = try? JSONEncoder().encode(sel.applicationTokens)
            self.categoryTokensData = sel.categoryTokens.isEmpty ? nil :
                try? JSONEncoder().encode(sel.categoryTokens)
        } else {
            self.applicationTokensData = nil
            self.categoryTokensData = nil
        }
    }

    public var eventName: String    { "limit-\(ruleID.uuidString)" }
    public var activityName: String { "rule-\(ruleID.uuidString)" }
}

// MARK: - DailyState helpers

extension DailyState {
    public var storageKey: String { "\(ruleID)-\(date)" }
}

// MARK: - AppColorScheme

public enum AppColorScheme: String, Codable, CaseIterable {
    case light
    case dark

    public var displayName: String {
        switch self {
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

// MARK: - Usage Summary

public struct UsageDaySummary: Codable, Equatable {
    public let date: String           // "yyyy-MM-dd"
    public let totalScreenTimeSeconds: Double

    public init(date: String, totalScreenTimeSeconds: Double) {
        self.date = date
        self.totalScreenTimeSeconds = totalScreenTimeSeconds
    }
}
