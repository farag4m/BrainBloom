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
                GradientBackground().ignoresSafeArea()

                // Ambient violet glow - top
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.55, green: 0.40, blue: 0.92).opacity(0.20), Color.clear],
                        center: .center, startRadius: 0, endRadius: 200
                    ))
                    .frame(width: 400, height: 400)
                    .offset(y: -200)
                    .blur(radius: 40)
                    .allowsHitTesting(false)

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
                        MathChallengeView(difficulty: viewModel.mathDifficulty,
                                          onSolved: { viewModel.advanceFromMathChallenge() })
                            .transition(.opacity)

                    case .chooseDuration:
                        DurationPickerView(
                            selected: $viewModel.selectedDuration,
                            onNext: { viewModel.proceedFromDuration() }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                    case .intention:
                        IntentionView(
                            text: $viewModel.intentionText,
                            isConfirmEnabled: viewModel.isConfirmEnabled,
                            delayRemaining: viewModel.delayRemaining,
                            requiresIntention: viewModel.effectiveFriction.includesIntention || viewModel.settings.requireIntentionText,
                            showsCountdownDelay: viewModel.effectiveFriction.includesDelay,
                            onConfirm: { Task { await viewModel.confirmUnlock() } }
                        )
                        .transition(.opacity)

                    case .confirming:
                        ConfirmingView()

                    case .done:
                        UnlockDoneView(
                            duration: viewModel.selectedDuration,
                            onDismiss: { dismiss() }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.82).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.easeInOut(duration: 0.32), value: viewModel.currentStep)
            }
            .toolbar {
                if viewModel.currentStep != .done && viewModel.currentStep != .confirming {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.cancel()
                            dismiss()
                        }
                        .foregroundStyle(.white.opacity(0.50))
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
                .font(.title.weight(.thin))
                .foregroundStyle(.white)
                .animation(.easeInOut(duration: 0.4), value: phase.label)

            ZStack {
                GlassCard(cornerRadius: 30)
                    .frame(width: 280, height: 280)
                    .shadow(color: Color.black.opacity(0.25), radius: 20, y: 10)

                // Static outer ring
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 246, height: 246)

                // Breathing glow blob
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            Color.sgTeal.opacity(0.65),
                            Color.sgTeal.opacity(0.18),
                            Color.clear
                        ],
                        center: .center, startRadius: 0, endRadius: 130
                    ))
                    .frame(
                        width:  CGFloat(120 + 120 * progress),
                        height: CGFloat(120 + 120 * progress)
                    )
                    .animation(.easeInOut(duration: 0.1), value: progress)

                // Crisp edge ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.sgTeal.opacity(0.95), Color.sgTealDark.opacity(0.40)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width:  CGFloat(120 + 120 * progress),
                        height: CGFloat(120 + 120 * progress)
                    )
                    .animation(.easeInOut(duration: 0.1), value: progress)
            }

            Text("Breathe slowly.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))

            Spacer()

            // Pill-style cycle progress
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= cycle
                              ? LinearGradient(colors: [Color.sgTeal, Color.sgTealDark],
                                               startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.18)],
                                               startPoint: .leading, endPoint: .trailing))
                        .frame(width: i <= cycle ? 22 : 8, height: 8)
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
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                Text("You can always unlock again if needed.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.50))
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

            Button(action: onNext) { Text("Continue") }
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
                        .font(.caption).foregroundStyle(.white.opacity(0.50))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.sgTeal : Color.white.opacity(0.22), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(SGGradient.brand)
                            .frame(width: 13, height: 13)
                    }
                }
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected
                              ? Color.sgTeal.opacity(0.16)
                              : Color.white.opacity(0.06))
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(SGGradient.cardSheen(opacity: 0.10))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.sgTeal.opacity(0.55) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - IntentionView

struct IntentionView: View {
    @Binding var text: String
    let isConfirmEnabled: Bool
    let delayRemaining: Int
    let requiresIntention: Bool
    let showsCountdownDelay: Bool
    let onConfirm: () -> Void
    @FocusState private var isFocused: Bool

    private var canConfirm: Bool {
        guard isConfirmEnabled else { return false }
        if requiresIntention {
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text(requiresIntention ? "Why are you unlocking?" : "Ready to unlock?")
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                Text(requiresIntention
                     ? "Writing it down builds awareness."
                     : "Take a breath before you continue.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.50))
            }

            if requiresIntention {
                TextField("", text: $text,
                          prompt: Text("e.g. Checking a message")
                              .foregroundColor(.white.opacity(0.30)))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background {
                        GlassCard(cornerRadius: 14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.white.opacity(0.12)
                                    : Color.sgTeal.opacity(0.55),
                                lineWidth: 1.5
                            )
                    )
                    .focused($isFocused)
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
            }

            Spacer()

            Button(action: onConfirm) {
                if showsCountdownDelay && !isConfirmEnabled {
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
        .onAppear { if requiresIntention { isFocused = true } }
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
                .foregroundStyle(.white.opacity(0.60))
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

            ZStack {
                SGMascotGlow(size: 200)
                GlassLeafIcon(size: 130, tint: Color.sgTeal, glassTint: Color.sgTeal.opacity(0.35))
                    .shadow(color: Color.sgTeal.opacity(0.30), radius: 20, y: 8)
            }
            .scaleEffect(appeared ? 1.0 : 0.50)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.55), value: appeared)

            VStack(spacing: 8) {
                Text("You're in!")
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                if let minutes = duration.minutes {
                    Text("You have \(minutes) minutes. Use them well.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.60))
                } else {
                    Text("Unlocked for the rest of today.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.60))
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.20), value: appeared)

            Text("Switch back to the app manually.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.30))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.30), value: appeared)

            Spacer()

            Button(action: onDismiss) { Text("Done") }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.38), value: appeared)
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
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                if problemsRequired > 1 {
                    Text("Problem \(solvedCount + 1) of \(problemsRequired)")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.50))
                } else {
                    Text("Solve to continue.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.50))
                }
            }

            VStack(spacing: 14) {
                Text(problem.expression)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    TextField("", text: $userAnswer)
                        .keyboardType(.numberPad)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .focused($isFocused)
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isWrong
                                        ? Color.red.opacity(0.65)
                                        : Color.sgTeal.opacity(0.45),
                                        lineWidth: 1.5)
                        )
                        .padding(.horizontal, 48)
                        .offset(x: shakeOffset)

                    if isWrong {
                        Text("Not yet. Try again")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.80))
                            .transition(.opacity)
                    }
                }
            }
            .padding(20)
            .background {
                GlassCard(cornerRadius: 20)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Submit") { submitAnswer() }
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
            let a = Int.random(in: 3...15), b = Int.random(in: 1...9)
            return Bool.random() || a <= b
                ? MathProblem(expression: "\(a) + \(b) = ?", answer: a + b)
                : MathProblem(expression: "\(a) − \(b) = ?", answer: a - b)
        case 1:
            let a = Int.random(in: 12...35), b = Int.random(in: 3...15)
            return Bool.random()
                ? MathProblem(expression: "\(a) + \(b) = ?", answer: a + b)
                : MathProblem(expression: "\(a) − \(b) = ?", answer: a - b)
        case 2:
            let a = Int.random(in: 12...40), b = Int.random(in: 3...15)
            return Bool.random()
                ? MathProblem(expression: "\(a) × \(b) = ?", answer: a * b)
                : MathProblem(expression: "\(a) + \(b) = ?", answer: a + b)
        default:
            let a = Int.random(in: 15...49), b = Int.random(in: 6...19)
            return MathProblem(expression: "\(a) × \(b) = ?", answer: a * b)
        }
    }
}
