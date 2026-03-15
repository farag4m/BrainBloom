import SwiftUI

// MARK: - FrictionPreviewView
//
// Presents an interactive, no-side-effect preview of a FrictionType's full UI flow.
// Reuses every production friction component (BreathingView, MathChallengeView,
// IntentionView) — no static screenshots, no fake UI.
// "Confirm / Unlock" advances to a preview-complete screen instead of mutating any state.

struct FrictionPreviewView: View {
    @StateObject private var viewModel: FrictionPreviewViewModel
    @Environment(\.dismiss) private var dismiss

    init(friction: FrictionType) {
        _viewModel = StateObject(wrappedValue: FrictionPreviewViewModel(friction: friction))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.scrollGremlinBackground.ignoresSafeArea()

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
                        MathChallengeView(difficulty: 0, onSolved: { viewModel.advanceFromMathChallenge() })
                            .transition(.opacity)

                    case .intention:
                        IntentionView(
                            text: $viewModel.intentionText,
                            isConfirmEnabled: viewModel.isConfirmEnabled,
                            delayRemaining: viewModel.delayRemaining,
                            friction: viewModel.friction,
                            onConfirm: { viewModel.confirmPreview() }
                        )
                        .onAppear { viewModel.onIntentionAppear() }
                        .transition(.opacity)

                    case .complete:
                        FrictionPreviewCompleteView(
                            friction: viewModel.friction,
                            onDismiss: { dismiss() }
                        )
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // Preview mode indicator — always visible at the top
                VStack {
                    Text("PREVIEW")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                    Spacer()
                }
            }
            .toolbar {
                if viewModel.currentStep != .complete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
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

// MARK: - Preview Complete Screen

private struct FrictionPreviewCompleteView: View {
    let friction: FrictionType
    let onDismiss: () -> Void

    private var isNone: Bool { friction == .none }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: isNone ? "circle.slash" : "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(isNone ? Color.white.opacity(0.3) : Color.scrollGremlinPrimary)

            VStack(spacing: 8) {
                Text(isNone ? "No Friction" : "Preview Complete")
                    .font(.title2).fontWeight(.semibold).foregroundStyle(.white)

                Text(isNone
                     ? "No friction is configured. When the limit is hit the app unlocks immediately — no extra steps."
                     : "That's exactly what users will see before unlocking with \"\(friction.displayName)\" friction.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

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
