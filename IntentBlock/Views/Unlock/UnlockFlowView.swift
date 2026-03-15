import SwiftUI

struct UnlockFlowView: View {
    @StateObject private var viewModel: UnlockViewModel
    @Environment(\.dismiss) private var dismiss

    init(ruleID: UUID) {
        _viewModel = StateObject(wrappedValue: UnlockViewModel(ruleID: ruleID))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.intentBlockBackground.ignoresSafeArea()

                Group {
                    switch viewModel.currentStep {
                    case .breathing:
                        BreathingView(
                            progress: viewModel.breathingProgress,
                            phase: viewModel.breathingPhase,
                            cycle: viewModel.breathingCycle
                        )
                        .onAppear { viewModel.startBreathing() }

                    case .mathChallenge:
                        MathChallengeView(difficulty: viewModel.mathDifficulty, onSolved: { viewModel.advanceFromMathChallenge() })
                            .transition(.opacity)

                    case .chooseDuration:
                        DurationPickerView(
                            selected: $viewModel.selectedDuration,
                            onNext: { viewModel.proceedFromDuration() }
                        )
                        .transition(.opacity)

                    case .intention:
                        IntentionView(
                            text: $viewModel.intentionText,
                            isConfirmEnabled: viewModel.isConfirmEnabled,
                            delayRemaining: viewModel.delayRemaining,
                            friction: viewModel.effectiveFriction,
                            onConfirm: {
                                Task { await viewModel.confirmUnlock() }
                            }
                        )
                        .transition(.opacity)

                    case .confirming:
                        ConfirmingView()

                    case .done:
                        UnlockDoneView(
                            duration: viewModel.selectedDuration,
                            onDismiss: { dismiss() }
                        )
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
            .toolbar {
                if viewModel.currentStep != .done && viewModel.currentStep != .confirming {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.cancel()
                            dismiss()
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

struct BreathingView: View {
    let progress: Double
    let phase: BreathingPhase
    let cycle: Int

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            Text(phase.label)
                .font(.title).fontWeight(.thin)
                .foregroundStyle(.white.opacity(0.9))
                .animation(.easeInOut(duration: 0.4), value: phase.label)

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 240, height: 240)

                Circle()
                    .fill(Color.intentBlockPrimary.opacity(0.15))
                    .frame(
                        width: CGFloat(120 + 120 * progress),
                        height: CGFloat(120 + 120 * progress)
                    )
                    .animation(.easeInOut(duration: 0.1), value: progress)

                Circle()
                    .stroke(Color.intentBlockPrimary.opacity(0.5), lineWidth: 2)
                    .frame(
                        width: CGFloat(120 + 120 * progress),
                        height: CGFloat(120 + 120 * progress)
                    )
                    .animation(.easeInOut(duration: 0.1), value: progress)
            }

            Text("Breathe slowly.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i <= cycle ? Color.intentBlockPrimary : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 48)
        }
    }
}

struct DurationPickerView: View {
    @Binding var selected: UnlockType
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("How long do you need?")
                    .font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                Text("You can always unlock again if needed.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 10) {
                ForEach(UnlockType.allCases, id: \.self) { type in
                    DurationOptionRow(type: type, isSelected: selected == type) {
                        selected = type
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

struct DurationOptionRow: View {
    let type: UnlockType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayLabel)
                        .font(.headline).foregroundStyle(.white)
                    Text(type.subtitle)
                        .font(.caption).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.intentBlockPrimary)
                }
            }
            .padding()
            .background(isSelected ? Color.intentBlockPrimary.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.intentBlockPrimary : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

struct IntentionView: View {
    @Binding var text: String
    let isConfirmEnabled: Bool
    let delayRemaining: Int
    let friction: FrictionType
    let onConfirm: () -> Void
    @FocusState private var isFocused: Bool

    // Timer must have elapsed AND, when intention is required, text must be non-empty.
    private var canConfirm: Bool {
        guard isConfirmEnabled else { return false }
        if friction.includesIntention {
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text(friction.includesIntention ? "Why are you unlocking?" : "Ready to unlock?")
                    .font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                Text(friction.includesIntention ? "Writing it down helps build awareness." : "Take a breath before you continue.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
            }

            if friction.includesIntention {
                TextField("", text: $text, prompt: Text("e.g. Checking a message").foregroundColor(.white.opacity(0.3)))
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isFocused)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onConfirm) {
                    if friction.includesDelay && !isConfirmEnabled {
                        Text("Wait \(delayRemaining)s...")
                    } else if !isConfirmEnabled {
                        Text("Just a moment...")
                    } else {
                        Text("Unlock")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: canConfirm))
                .disabled(!canConfirm)
                .animation(.easeInOut(duration: 0.3), value: canConfirm)
                .padding(.horizontal, 24)

                if friction.includesIntention && !text.isEmpty {
                    // intent provided, confirm enabled faster
                }
            }
            .padding(.bottom, 48)
        }
        .onAppear { if friction.includesIntention { isFocused = true } }
    }
}

struct ConfirmingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text("Unlocking...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

struct UnlockDoneView: View {
    let duration: UnlockType
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.intentBlockPrimary)

            VStack(spacing: 8) {
                Text("Unlocked")
                    .font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                if let minutes = duration.minutes {
                    Text("You have \(minutes) minutes. Use them well.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Unlocked for the rest of today.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
            }

            Text("Switch back to the app manually.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - MathChallengeView

struct MathChallengeView: View {
    let difficulty: Int   // 0 = first unlock, 1 = second, 2 = third, 3+ = fourth+
    let onSolved: () -> Void

    @State private var problem: MathProblem
    @State private var solvedCount = 0
    @State private var userAnswer = ""
    @State private var isWrong = false
    @FocusState private var isFocused: Bool

    // Number of problems required scales with difficulty.
    private var problemsRequired: Int {
        switch difficulty {
        case 0, 1: return 1
        case 2:    return 2
        default:   return 3
        }
    }

    init(difficulty: Int, onSolved: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onSolved = onSolved
        self._problem = State(initialValue: .generate(difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Quick Check")
                    .font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                if problemsRequired > 1 {
                    Text("Problem \(solvedCount + 1) of \(problemsRequired)")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                } else {
                    Text("Solve the problem to continue.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                }
            }

            Text(problem.expression)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                TextField("", text: $userAnswer)
                    .keyboardType(.numberPad)
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 48)

                if isWrong {
                    Text("Not quite — try again")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button("Submit") {
                if let ans = Int(userAnswer), ans == problem.answer {
                    let next = solvedCount + 1
                    if next >= problemsRequired {
                        onSolved()
                    } else {
                        solvedCount = next
                        userAnswer = ""
                        isWrong = false
                        problem = .generate(difficulty: difficulty)
                        isFocused = true
                    }
                } else {
                    isWrong = true
                    userAnswer = ""
                    problem = .generate(difficulty: difficulty)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !userAnswer.isEmpty))
            .disabled(userAnswer.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - MathProblem

struct MathProblem {
    let expression: String
    let answer: Int

    /// Generates a problem scaled to the current difficulty level.
    /// difficulty 0 — first unlock:   1 easy add/subtract, small numbers
    /// difficulty 1 — second unlock:  1 harder add/subtract, larger numbers
    /// difficulty 2 — third unlock:   2 problems, introduces multiplication
    /// difficulty 3+ — fourth+ unlock: 3 problems, multiplication with large numbers
    static func generate(difficulty: Int) -> MathProblem {
        switch difficulty {
        case 0:
            let a = Int.random(in: 3...15)
            let b = Int.random(in: 1...9)
            if Bool.random() || a <= b {
                return MathProblem(expression: "\(a) + \(b) = ?", answer: a + b)
            } else {
                return MathProblem(expression: "\(a) − \(b) = ?", answer: a - b)
            }
        case 1:
            let a = Int.random(in: 12...35)
            let b = Int.random(in: 3...15)
            if Bool.random() {
                return MathProblem(expression: "\(a) + \(b) = ?", answer: a + b)
            } else {
                return MathProblem(expression: "\(a) − \(b) = ?", answer: a - b)
            }
        case 2:
            let a = Int.random(in: 12...40)
            let b = Int.random(in: 3...15)
            if Bool.random() {
                return MathProblem(expression: "\(a) × \(b) = ?", answer: a * b)
            } else {
                return MathProblem(expression: "\(a) + \(b) = ?", answer: a + b)
            }
        default:
            let a = Int.random(in: 15...49)
            let b = Int.random(in: 6...19)
            return MathProblem(expression: "\(a) × \(b) = ?", answer: a * b)
        }
    }
}
