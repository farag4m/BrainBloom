import SwiftUI

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Rich multi-stop gradient background
            SGGradient.immersiveDark.ignoresSafeArea()

            // Ambient top-right teal glow
            Circle()
                .fill(RadialGradient(
                    colors: [Color.sgTeal.opacity(0.18), Color.clear],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 360, height: 360)
                .offset(x: 120, y: -160)
                .blur(radius: 30)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // Mascot with layered glow
                ZStack {
                    SGMascotGlow(size: 220)
                    Image("Gremlin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .shadow(color: Color.sgTeal.opacity(0.30), radius: 20, y: 8)
                }
                .scaleEffect(appeared ? 1.0 : 0.55)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.55).delay(0.05), value: appeared)
                .padding(.bottom, 16)

                // Headline
                VStack(spacing: 10) {
                    Text("Meet Your")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text("ScrollGremlin")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.sgTeal)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.45).delay(0.22), value: appeared)

                // Body
                Text("Set daily limits for your most distracting apps.\nWhen time's up, ScrollGremlin helps you pause and decide — instead of endlessly scrolling.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.32), value: appeared)

                Spacer()

                // Feature rows on frosted card
                VStack(spacing: 12) {
                    FeatureRow(icon: "timer",          text: "Set daily time budgets per app")
                    FeatureRow(icon: "lungs.fill",     text: "Mindful unlock flow with breathing")
                    FeatureRow(icon: "chart.bar.fill", text: "Track your habits over time")
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.30), .white.opacity(0.06)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.14), radius: 12, y: 4)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.easeOut(duration: 0.45).delay(0.44), value: appeared)

                Button(action: onGetStarted) {
                    Text("Get Started")
                }
                .buttonStyle(AccentButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.56), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.sgTeal.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(Color.sgTeal)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.80))
            Spacer()
        }
    }
}
