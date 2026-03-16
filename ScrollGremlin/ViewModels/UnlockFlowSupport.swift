import Foundation

enum BreathingPhase {
    case inhale
    case exhale

    var label: String {
        switch self {
        case .inhale:
            return "Inhale"
        case .exhale:
            return "Exhale"
        }
    }
}

enum BreathingExerciseRunner {
    @MainActor
    static func start(
        cycles: Int = 3,
        setCycle: @escaping @MainActor (Int) -> Void,
        setPhase: @escaping @MainActor (BreathingPhase) -> Void,
        setProgress: @escaping @MainActor (Double) -> Void,
        onComplete: @escaping @MainActor () -> Void
    ) -> Task<Void, Never> {
        Task {
            for cycle in 0..<cycles {
                guard !Task.isCancelled else { return }
                setCycle(cycle)
                setPhase(.inhale)
                await animateBreathing(from: 0.0, to: 1.0, duration: 5.0, setProgress: setProgress)

                guard !Task.isCancelled else { return }
                setPhase(.exhale)
                await animateBreathing(from: 1.0, to: 0.0, duration: 5.0, setProgress: setProgress)
            }

            guard !Task.isCancelled else { return }
            onComplete()
        }
    }

    @MainActor
    private static func animateBreathing(
        from start: Double,
        to end: Double,
        duration: Double,
        setProgress: @escaping @MainActor (Double) -> Void
    ) async {
        let steps = 40
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            guard !Task.isCancelled else { return }
            let progress = start + (end - start) * (Double(step) / Double(steps))
            setProgress(progress)
            guard await SleepTimer.pause(seconds: stepDuration) else {
                return
            }
        }
    }
}

enum ConfirmationDelayRunner {
    @MainActor
    static func start(
        for friction: FrictionType,
        setRemaining: @escaping @MainActor (Int) -> Void,
        setIsEnabled: @escaping @MainActor (Bool) -> Void
    ) -> Task<Void, Never>? {
        if friction == .none {
            setIsEnabled(true)
            return nil
        }

        if friction.includesDelay {
            setRemaining(10)
            setIsEnabled(false)
            return Task {
                for second in stride(from: 10, through: 0, by: -1) {
                    guard !Task.isCancelled else { return }
                    setRemaining(second)
                    guard await SleepTimer.pause(seconds: 1) else {
                        return
                    }
                }
                guard !Task.isCancelled else { return }
                setIsEnabled(true)
            }
        }

        setIsEnabled(false)
        return Task {
            guard await SleepTimer.pause(seconds: 2) else {
                return
            }
            guard !Task.isCancelled else { return }
            setIsEnabled(true)
        }
    }
}

enum SleepTimer {
    static func pause(seconds: Double) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return true
        } catch {
            return false
        }
    }
}
