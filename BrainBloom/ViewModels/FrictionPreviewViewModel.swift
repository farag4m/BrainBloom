import SwiftUI
import Combine

@MainActor
final class FrictionPreviewViewModel: ObservableObject {

    enum Step { case breathing, mathChallenge, intention, complete }

    @Published var currentStep: Step
    @Published var intentionText: String = ""
    @Published var breathingProgress: Double = 0
    @Published var breathingPhase: BreathingPhase = .inhale
    @Published var breathingCycle: Int = 0
    @Published var delayRemaining: Int = 10
    @Published var isConfirmEnabled: Bool = false

    let friction: FrictionType

    private var breathingTask: Task<Void, Never>?
    private var delayTask: Task<Void, Never>?

    init(friction: FrictionType) {
        self.friction = friction
        if friction == .none {
            self.currentStep = .complete
        } else if friction.includesBreathing {
            self.currentStep = .breathing
        } else if friction.includesMath {
            self.currentStep = .mathChallenge
        } else {
            self.currentStep = .intention
        }
    }

    // MARK: - Breathing

    func startBreathing() {
        breathingTask?.cancel()
        breathingTask = BreathingExerciseRunner.start(
            setCycle: { [weak self] cycle in self?.breathingCycle = cycle },
            setPhase: { [weak self] phase in self?.breathingPhase = phase },
            setProgress: { [weak self] progress in self?.breathingProgress = progress }
        ) { [weak self] in
            self?.currentStep = self?.requiresConfirmationStep == true ? .intention : .complete
        }
    }

    // MARK: - Math challenge

    func advanceFromMathChallenge() {
        currentStep = requiresConfirmationStep ? .intention : .complete
    }

    // MARK: - Intention / delay

    func onIntentionAppear() {
        delayTask?.cancel()
        delayTask = ConfirmationDelayRunner.start(
            for: friction,
            setRemaining: { [weak self] remaining in self?.delayRemaining = remaining },
            setIsEnabled: { [weak self] isEnabled in self?.isConfirmEnabled = isEnabled }
        )
    }

    // MARK: - Confirm / cancel

    func confirmPreview() {
        breathingTask?.cancel()
        delayTask?.cancel()
        currentStep = .complete
    }

    func cancel() {
        breathingTask?.cancel()
        delayTask?.cancel()
    }

    private var requiresConfirmationStep: Bool {
        friction.includesIntention || friction.includesDelay || friction == .confirmOnly
    }
}
