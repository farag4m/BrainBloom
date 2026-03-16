import SwiftUI
import Combine

@MainActor
final class UnlockViewModel: ObservableObject {
    enum Step {
        case breathing
        case mathChallenge
        case chooseDuration
        case intention
        case confirming
        case done
    }

    @Published var currentStep: Step
    @Published var selectedDuration: UnlockType
    @Published var intentionText: String = ""
    @Published var breathingProgress: Double = 0
    @Published var breathingPhase: BreathingPhase = .inhale
    @Published var mathDifficulty: Int = 0
    @Published var breathingCycle: Int = 0
    @Published var delayRemaining: Int = 10
    @Published var isConfirmEnabled: Bool = false

    let ruleID: UUID
    let settings: UserSettings

    private let store = AppGroupStore.shared
    private let monitoringService = MonitoringService.shared
    private var breathingTask: Task<Void, Never>?
    private var delayTask: Task<Void, Never>?
    let effectiveFriction: FrictionType
    private var requiresIntention: Bool { effectiveFriction.includesIntention || settings.requireIntentionText }
    private var requiresDelay: Bool { effectiveFriction.includesDelay }
    private var requiresConfirmationStep: Bool {
        requiresIntention || requiresDelay || effectiveFriction == .confirmOnly
    }

    init(ruleID: UUID) {
        self.ruleID = ruleID
        let settings = AppGroupStore.shared.loadSettings()
        self.settings = settings

        // Load the rule to check for per-rule overrides
        let rule = AppGroupStore.shared.loadRules().first(where: { $0.id == ruleID })

        // Use rule override if set, otherwise fall back to Settings default
        let duration = rule?.unlockDurationOverride ?? settings.defaultUnlockType
        self.selectedDuration = duration

        let friction = rule?.frictionOverride ?? settings.defaultFriction
        self.effectiveFriction = friction

        self.mathDifficulty = min(Self.windowUnlockCount(ruleID: ruleID), 3)

        if friction.includesBreathing {
            currentStep = .breathing
        } else if friction.includesMath {
            currentStep = .mathChallenge
        } else {
            currentStep = .chooseDuration
        }
    }

    // Returns the number of completed unlock sessions for this rule in the current policy window.
    // Daily rules: today's sessions. Recurring: sessions since the current slot start.
    private static func windowUnlockCount(ruleID: UUID) -> Int {
        let sessions = AppGroupStore.shared.loadUnlockSessions()
        let rule = AppGroupStore.shared.loadRules().first { $0.id == ruleID }
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { session in
            guard session.ruleID == ruleID,
                  calendar.isDateInToday(session.startedAt) else { return false }
            if let rule, rule.policy.type == .recurringInterval {
                let hours = rule.policy.intervalHours
                let slotStartHour = (calendar.component(.hour, from: now) / hours) * hours
                guard let slotStart = calendar.date(
                    bySettingHour: slotStartHour, minute: 0, second: 0, of: now) else { return false }
                return session.startedAt >= slotStart
            }
            return true
        }.count
    }

    func advanceFromMathChallenge() {
        currentStep = .chooseDuration
    }

    func startBreathing() {
        breathingTask?.cancel()
        breathingTask = BreathingExerciseRunner.start(
            setCycle: { [weak self] cycle in self?.breathingCycle = cycle },
            setPhase: { [weak self] phase in self?.breathingPhase = phase },
            setProgress: { [weak self] progress in self?.breathingProgress = progress }
        ) { [weak self] in
            guard let self else { return }
            if self.currentStep == .breathing {
                self.currentStep = .chooseDuration
            }
        }
    }

    func proceedFromDuration() {
        guard requiresConfirmationStep else {
            Task { [weak self] in
                await self?.confirmUnlock()
            }
            return
        }

        if requiresIntention || requiresDelay || effectiveFriction == .confirmOnly {
            currentStep = .intention
        }
        startConfirmationDelay()
    }

    func confirmUnlock() async {
        currentStep = .confirming
        breathingTask?.cancel()
        delayTask?.cancel()

        let rules = store.loadRules()
        guard let rule = rules.first(where: { $0.id == ruleID }) else {
            currentStep = .done
            return
        }

        // Remove shield
        monitoringService.removeShield(for: rule)

        // "Until end of day" — stop remaining slot monitoring so recurring rules don't re-shield.
        if selectedDuration.minutes == nil {
            if rule.policy.type == .recurringInterval {
                monitoringService.stopRemainingSlotMonitoring(for: rule)
            }
        } else {
            // Start grace monitoring for timed unlocks
            do {
                try monitoringService.startGraceMonitoring(for: rule, gracePeriodMinutes: selectedDuration.minutes!)
            } catch {
                AppLogger.log(error: error, context: "Failed to start grace monitoring for rule \(rule.id)", category: "Unlock")
            }
        }

        // Record unlock session
        let session = UnlockSession(
            ruleID: ruleID,
            unlockType: selectedDuration,
            frictionType: effectiveFriction,
            intention: intentionText.isEmpty ? nil : intentionText
        )
        store.appendUnlockSession(session)
        store.clearPendingUnlockRequest()

        // Update daily state
        var dailyState = store.loadDailyState(ruleID: ruleID) ?? DailyState(ruleID: ruleID)
        dailyState.isCurrentlyShielded = false
        dailyState.activeUnlockSessionID = session.id
        if selectedDuration.minutes == nil {
            dailyState.isUnlockedUntilEndOfDay = true
        }
        store.saveDailyState(dailyState)

        _ = await SleepTimer.pause(seconds: 0.8)
        currentStep = .done
    }

    func cancel() {
        breathingTask?.cancel()
        delayTask?.cancel()
        store.clearPendingUnlockRequest()
    }

    private func startConfirmationDelay() {
        delayTask?.cancel()
        isConfirmEnabled = false
        delayTask = ConfirmationDelayRunner.start(
            for: effectiveFriction,
            setRemaining: { [weak self] remaining in self?.delayRemaining = remaining },
            setIsEnabled: { [weak self] isEnabled in self?.isConfirmEnabled = isEnabled }
        )
    }
}
