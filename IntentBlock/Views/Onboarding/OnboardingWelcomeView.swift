import SwiftUI

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        ZStack {
            Color.intentBlockBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.intentBlockPrimary.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.intentBlockPrimary)
                    }

                    VStack(spacing: 12) {
                        Text("Use Apps")
                            .font(.largeTitle).fontWeight(.bold).foregroundStyle(.white)
                        Text("Intentionally")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(Color.intentBlockPrimary)
                    }

                    Text("Set daily limits for your most distracting apps. When time's up, IntentBlock helps you pause and decide — instead of endlessly scrolling.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Spacer()

                VStack(spacing: 16) {
                    FeatureRow(icon: "timer", text: "Set daily time budgets per app")
                    FeatureRow(icon: "lungs.fill", text: "Mindful unlock flow with breathing")
                    FeatureRow(icon: "chart.bar.fill", text: "Track your habits over time")
                }
                .padding(.bottom, 32)

                Button(action: onGetStarted) {
                    Text("Get Started")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.intentBlockPrimary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
