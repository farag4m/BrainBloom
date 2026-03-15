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
        breathingTask = Task {
            for cycle in 0..<3 {
                guard !Task.isCancelled else { break }
                breathingCycle = cycle

                breathingPhase = .inhale
                await animateBreathing(to: 1.0, duration: 5.0)
                guard !Task.isCancelled else { break }
                breathingPhase = .exhale
                await animateBreathing(to: 0.0, duration: 5.0)
            }
            guard !Task.isCancelled else { return }
            if friction.includesIntention {
                currentStep = .intention
            } else {
                currentStep = .complete
            }
        }
    }

    private func animateBreathing(to value: Double, duration: Double) async {
        let steps = 40
        let stepDuration = duration / Double(steps)
        let start = breathingProgress
        for i in 0...steps {
            guard !Task.isCancelled else { return }
            breathingProgress = start + (value - start) * (Double(i) / Double(steps))
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }

    // MARK: - Math challenge

    func advanceFromMathChallenge() {
        currentStep = .complete
    }

    // MARK: - Intention / delay

    func onIntentionAppear() {
        if friction.includesDelay {
            startCountdownDelay()
        } else {
            startMinimumDelay()
        }
    }

    private func startMinimumDelay() {
        isConfirmEnabled = false
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isConfirmEnabled = true
        }
    }

    private func startCountdownDelay() {
        delayRemaining = 10
        isConfirmEnabled = false
        delayTask = Task {
            for i in stride(from: 10, through: 0, by: -1) {
                guard !Task.isCancelled else { return }
                delayRemaining = i
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            isConfirmEnabled = true
        }
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
}
