import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step: OnboardingStep = .welcome

    enum OnboardingStep { case welcome, permission, firstRule }

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
    @EnvironmentObject var ruleManager: RuleManager
    let onComplete: () -> Void
    @State private var showRuleEditor = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()

            // Soft pink-lavender bloom - bottom
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.72, green: 0.50, blue: 0.98).opacity(0.18), Color.clear],
                    center: .center, startRadius: 0, endRadius: 200
                ))
                .frame(width: 400, height: 400)
                .offset(y: 250)
                .blur(radius: 40)
                .allowsHitTesting(false)

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        SGMascotGlow(size: 180)
                        GlassLeafIcon(size: 140, tint: Color.sgTeal, glassTint: Color.sgTeal.opacity(0.35))
                            .shadow(color: Color.sgTeal.opacity(0.28), radius: 18, y: 6)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.65)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.60, dampingFraction: 0.58), value: appeared)

                    Text("Add Your First Rule")
                        .font(.title2.weight(.bold)).foregroundStyle(.primary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                    Text("Pick the app you find most distracting and set a daily time limit.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Add an App to Block") { showRuleEditor = true }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("Skip for now") { onComplete() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
            }
        }
        .onAppear { appeared = true }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorView(rule: nil) { rule in
                do {
                    try ruleManager.addRule(rule)
                } catch {
                    AppLogger.log(error: error, context: "Failed to add onboarding rule", category: "Onboarding")
                }
                showRuleEditor = false
                onComplete()
            }
        }
    }
}
