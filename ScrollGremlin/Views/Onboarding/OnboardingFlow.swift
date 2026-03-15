import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step: OnboardingStep = .welcome

    enum OnboardingStep {
        case welcome, permission, firstRule
    }

    var body: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView(onGetStarted: {
                withAnimation { step = .permission }
            })
        case .permission:
            OnboardingPermissionView(onAuthorized: {
                withAnimation { step = .firstRule }
            })
            .environmentObject(authManager)
        case .firstRule:
            OnboardingFirstRuleView(onComplete: {
                hasCompletedOnboarding = true
            })
        }
    }
}

struct OnboardingFirstRuleView: View {
    let onComplete: () -> Void
    @State private var showRuleEditor = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.sgBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 20) {
                    Image("Gremlin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(appeared ? 1.0 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

                    Text("Add Your First Rule")
                        .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                    Text("Pick the app you find most distracting and set a daily time limit.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Add an App to Block") {
                        showRuleEditor = true
                    }
                    .buttonStyle(AccentButtonStyle())

                    Button("Skip for now") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
            }
        }
        .onAppear { appeared = true }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorView(rule: nil) { _ in
                showRuleEditor = false
                onComplete()
            }
        }
    }
}
