import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step: OnboardingStep = .welcome
    @State private var showFirstRule = false

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
    @State private var ruleCreated = false

    var body: some View {
        ZStack {
            Color.scrollGremlinBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.scrollGremlinPrimary)

                    Text("Add Your First Rule")
                        .font(.title2).fontWeight(.bold).foregroundStyle(.white)

                    Text("Pick the app you find most distracting and set a daily time limit.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Add an App to Block") {
                        showRuleEditor = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Skip for now") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorView(rule: nil) { _ in
                showRuleEditor = false
                onComplete()
            }
        }
    }
}
