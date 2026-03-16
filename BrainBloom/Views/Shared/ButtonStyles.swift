import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let tintOverlay = LinearGradient(
            colors: scheme == .dark ? [
                Color(red: 0.60, green: 0.70, blue: 1.00).opacity(isEnabled ? 0.20 : 0.08),
                Color(red: 0.30, green: 0.35, blue: 0.55).opacity(isEnabled ? 0.12 : 0.05),
                Color.clear,
            ] : [
                Color(red: 0.55, green: 0.70, blue: 0.98).opacity(isEnabled ? 0.12 : 0.06),
                Color(red: 0.75, green: 0.82, blue: 1.00).opacity(isEnabled ? 0.08 : 0.04),
                Color.clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(tintOverlay)
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color.white.opacity(scheme == .dark ? 0.18 : 0.55), Color.clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.55)
                        )
                    )
                    Capsule().stroke(Color.white.opacity(scheme == .dark ? 0.22 : 0.45), lineWidth: 1)
                }
            }
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.6))
            .clipShape(Capsule())
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.35 : 0.12),
                radius: configuration.isPressed ? 4 : 12,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .overlay {
                Capsule().stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.42), .white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .foregroundStyle(.white.opacity(0.88))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
