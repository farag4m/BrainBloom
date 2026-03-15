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
                Color.sgBackground.ignoresSafeArea()

                Group {
                    switch viewModel.currentStep {
                    case .breathing:
                        BreathingView(
                            progress: viewModel.breathingProgress,
                            phase: viewModel.breathingPhase,
                            cycle: viewModel.breathingCycle
                        )
                        .onAppear { viewModel.startBreathing() }
                        .transition(.opacity)

                    case .mathChallenge:
                        MathChallengeView(difficulty: viewModel.mathDifficulty, onSolved: { viewModel.advanceFromMathChallenge() })
                            .transition(.opacity)

                    case .chooseDuration:
                        DurationPickerView(
                            selected: $viewModel.selectedDuration,
                            onNext: { viewModel.proceedFromDuration() }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .opacity))

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
                        .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity),
                                                removal: .opacity))
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
                        .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }
}

// MARK: - BreathingView

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
                // Outer ring
                Circle()
                    .stroke(Color.sgTeal.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 240, height: 240)

                // Breathing blob — teal fill
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.sgTeal.opacity(0.35), Color.sgTeal.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(
                        width:  CGFloat(120 + 120 * progress),
                        height: CGFloat(120 + 120 * progress)
                    )
                    .animation(.easeInOut(duration: 0.1), value: progress)

                // Glow ring
                Circle()
                    .stroke(Color.sgTeal.opacity(0.55), lineWidth: 1.5)
                    .frame(
                        width:  CGFloat(120 + 120 * progress),
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
                    Capsule()
                        .fill(i <= cycle ? Color.sgTeal : Color.white.opacity(0.18))
                        .frame(width: i <= cycle ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.35), value: cycle)
                }
            }
            .padding(.bottom, 52)
        }
    }
}

// MARK: - DurationPickerView

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
                        withAnimation(.spring(response: 0.3)) { selected = type }
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
            .padding(.bottom, 52)
        }
    }
}

// MARK: - DurationOptionRow

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
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.sgTeal : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.sgTeal)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.sgTeal.opacity(0.14) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.sgTeal.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .interactivePress()
    }
}

// MARK: - IntentionView

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
                Text(friction.includesIntention ? "Writing it down builds awareness." : "Take a breath before you continue.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
            }

            if friction.includesIntention {
                TextField("", text: $text, prompt: Text("e.g. Checking a message").foregroundColor(.white.opacity(0.3)))
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.white.opacity(0.12)
                                    : Color.sgTeal.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                    .focused($isFocused)
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
            }

            Spacer()

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
            .padding(.bottom, 52)
        }
        .onAppear { if friction.includesIntention { isFocused = true } }
    }
}

// MARK: - ConfirmingView

struct ConfirmingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color.sgTeal)
                .scaleEffect(1.5)
            Text("Unlocking...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - UnlockDoneView

struct UnlockDoneView: View {
    let duration: UnlockType
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("Gremlin")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .scaleEffect(appeared ? 1.0 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.55), value: appeared)

            VStack(spacing: 8) {
                Text("You're in!")
                    .font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                if let minutes = duration.minutes {
                    Text("You have \(minutes) minutes. Use them well.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Unlocked for the rest of today.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

            Text("Switch back to the app manually.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - MathChallengeView

struct MathChallengeView: View {
    let difficulty: Int
    let onSolved: () -> Void

    @State private var problem: MathProblem
    @State private var solvedCount = 0
    @State private var userAnswer = ""
    @State private var isWrong = false
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isFocused: Bool

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
                    Text("Solve to continue.")
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
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isWrong ? Color.red.opacity(0.6) : Color.sgTeal.opacity(0.3), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 48)
                    .offset(x: shakeOffset)

                if isWrong {
                    Text("Not quite — try again")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .transition(.opacity)
                }
            }

            Spacer()

            Button("Submit") {
                submitAnswer()
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !userAnswer.isEmpty))
            .disabled(userAnswer.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .onAppear { isFocused = true }
        .animation(.easeInOut(duration: 0.2), value: isWrong)
    }

    private func submitAnswer() {
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
            // Shake animation
            withAnimation(.default) { shakeOffset = -8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                withAnimation(.default) { shakeOffset = 8 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring()) { shakeOffset = 0 }
            }
        }
    }
}

// MARK: - MathProblem

struct MathProblem {
    let expression: String
    let answer: Int

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
