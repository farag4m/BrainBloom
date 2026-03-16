import SwiftUI

struct FrictionPreviewView: View {
    @StateObject private var viewModel: FrictionPreviewViewModel
    @Environment(\.dismiss) private var dismiss

    init(friction: FrictionType) {
        _viewModel = StateObject(wrappedValue: FrictionPreviewViewModel(friction: friction))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground().ignoresSafeArea()

                // Ambient lavender glow - top
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.62, green: 0.50, blue: 0.98).opacity(0.18), Color.clear],
                        center: .center, startRadius: 0, endRadius: 180
                    ))
                    .frame(width: 360, height: 360)
                    .offset(x: 100, y: -180)
                    .blur(radius: 30)
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

                    case .mathChallenge:
                        MathChallengeView(difficulty: 0,
                                          onSolved: { viewModel.advanceFromMathChallenge() })
                            .transition(.opacity)

                    case .intention:
                        IntentionView(
                            text: $viewModel.intentionText,
                            isConfirmEnabled: viewModel.isConfirmEnabled,
                            delayRemaining: viewModel.delayRemaining,
                            requiresIntention: viewModel.friction.includesIntention,
                            showsCountdownDelay: viewModel.friction.includesDelay,
                            onConfirm: { viewModel.confirmPreview() }
                        )
                        .onAppear { viewModel.onIntentionAppear() }
                        .transition(.opacity)

                    case .complete:
                        FrictionPreviewCompleteView(
                            friction: viewModel.friction,
                            onDismiss: { dismiss() }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.88).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // PREVIEW pill - always visible at top
                VStack {
                    Text("PREVIEW")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.sgTeal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.sgTeal.opacity(0.14))
                        .overlay(Capsule().stroke(Color.sgTeal.opacity(0.40), lineWidth: 1))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                    Spacer()
                }
            }
            .toolbar {
                if viewModel.currentStep != .complete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { viewModel.cancel(); dismiss() }
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
        }
    }
}

#Preview("Breathing") {
    FrictionPreviewView(friction: .breathingScreen)
}

#Preview("Full") {
    FrictionPreviewView(friction: .full)
}

#Preview("None") {
    FrictionPreviewView(friction: .none)
}

// MARK: - Preview Complete Screen

private struct FrictionPreviewCompleteView: View {
    let friction: FrictionType
    let onDismiss: () -> Void
    @State private var appeared = false

    private var isNone: Bool { friction == .none }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                SGMascotGlow(size: 180)
                GlassLeafIcon(size: 120, tint: Color.sgTeal, glassTint: Color.sgTeal.opacity(0.35))
                    .shadow(color: Color.sgTeal.opacity(0.28), radius: 16, y: 6)
            }
            .scaleEffect(appeared ? 1.0 : 0.60)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.58), value: appeared)

            VStack(spacing: 8) {
                Text(isNone ? "No Friction" : "Preview Complete")
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)

                Text(isNone
                     ? "No friction is configured. Unlocks immediately with no extra steps."
                     : "That's exactly what users will see with \"\(friction.displayName)\" friction.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

            Spacer()

            Button(action: onDismiss) { Text("Done") }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
        }
        .onAppear { appeared = true }
    }
}
