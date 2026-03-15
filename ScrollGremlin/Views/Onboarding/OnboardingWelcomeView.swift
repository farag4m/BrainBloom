import SwiftUI

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.sgBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Mascot hero
                Image("Gremlin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.65, dampingFraction: 0.58).delay(0.05), value: appeared)
                    .padding(.bottom, 12)

                VStack(spacing: 10) {
                    Text("Meet Your")
                        .font(.largeTitle).fontWeight(.bold).foregroundStyle(.white)
                    Text("ScrollGremlin")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundStyle(Color.sgTeal)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.45).delay(0.2), value: appeared)

                Text("Set daily limits for your most distracting apps.\nWhen time's up, ScrollGremlin helps you pause and decide — instead of endlessly scrolling.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.3), value: appeared)

                Spacer()

                VStack(spacing: 14) {
                    FeatureRow(icon: "timer",          text: "Set daily time budgets per app")
                    FeatureRow(icon: "lungs.fill",     text: "Mindful unlock flow with breathing")
                    FeatureRow(icon: "chart.bar.fill", text: "Track your habits over time")
                }
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.45).delay(0.42), value: appeared)

                Button(action: onGetStarted) {
                    Text("Get Started")
                }
                .buttonStyle(AccentButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.55), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.sgTeal)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
