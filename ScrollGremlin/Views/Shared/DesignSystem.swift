import SwiftUI

// MARK: - Color Palette

extension Color {
    static let scrollGremlinPrimary = Color(red: 0.4, green: 0.3, blue: 0.9)
    static let scrollGremlinBackground = Color(red: 0.07, green: 0.07, blue: 0.12)
    /// Adaptive surface: subtle glass on dark backgrounds, subtle fill on light backgrounds.
    static let scrollGremlinSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.08)
            : UIColor(white: 0, alpha: 0.05)
    })
    /// Adaptive border: soft on dark, soft on light.
    static let scrollGremlinBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.12)
            : UIColor(white: 0, alpha: 0.10)
    })
}

extension UIColor {
    static let scrollGremlinPrimary = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1)
    static let scrollGremlinBackground = UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 0.95)
}

// MARK: - Typography Modifiers

extension View {
    func scrollGremlinTitle() -> some View {
        self.font(.title2).fontWeight(.semibold).foregroundStyle(.white)
    }

    func scrollGremlinSubtitle() -> some View {
        self.font(.subheadline).foregroundStyle(.white.opacity(0.5))
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.scrollGremlinPrimary : Color.white.opacity(0.15))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.10))
            .foregroundStyle(.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Card View

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color.scrollGremlinSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.scrollGremlinBorder, lineWidth: 1)
            )
    }
}

// MARK: - Status Badge

struct StatusBadgeView: View {
    let badge: RuleStatusBadge

    var body: some View {
        Text(badge.label)
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badge.color.opacity(0.2))
            .foregroundStyle(badge.color)
            .clipShape(Capsule())
    }
}

// MARK: - AppColorScheme + SwiftUI

extension AppColorScheme {
    /// Maps to SwiftUI's ColorScheme? where nil means "follow system".
    var swiftUIColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
