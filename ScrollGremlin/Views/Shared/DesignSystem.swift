import SwiftUI

// MARK: - Brand Palette
//
// Derived from the ScrollGremlin mascot:
//   sgTeal      — mascot body colour; primary interactive teal/mint
//   sgTealDark  — outlines, emphasis, foreground on teal backgrounds
//   sgYellow    — mascot eye colour; accent for high-priority CTAs
//   sgBackground — deep teal-black for immersive screens (onboarding / unlock)

extension Color {
    static let sgTeal       = Color(red: 0.08, green: 0.78, blue: 0.62)
    static let sgTealDark   = Color(red: 0.03, green: 0.48, blue: 0.38)
    static let sgYellow     = Color(red: 1.00, green: 0.82, blue: 0.13)
    static let sgBackground = Color(red: 0.04, green: 0.11, blue: 0.10)

    // Legacy aliases — keeps every existing call site compiling without mass rename.
    static let scrollGremlinPrimary    = sgTeal
    static let scrollGremlinBackground = sgBackground

    /// Adaptive surface: subtle glass on dark backgrounds, subtle fill on light.
    static let scrollGremlinSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.08)
            : UIColor(white: 0, alpha: 0.05)
    })
    /// Adaptive border: soft on both dark and light.
    static let scrollGremlinBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.12)
            : UIColor(white: 0, alpha: 0.10)
    })
    /// Tinted teal surface — used for selected/active card highlights.
    static let sgTealSurface = Color(red: 0.08, green: 0.78, blue: 0.62).opacity(0.12)
}

extension UIColor {
    static let scrollGremlinPrimary    = UIColor(red: 0.08, green: 0.78, blue: 0.62, alpha: 1)
    static let scrollGremlinBackground = UIColor(red: 0.04, green: 0.11, blue: 0.10, alpha: 0.95)
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

/// Primary — teal fill, dark foreground, spring press + soft glow shadow.
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.sgTeal : Color.white.opacity(0.15))
            .foregroundStyle(isEnabled ? Color.sgBackground : Color.white.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: isEnabled ? Color.sgTeal.opacity(0.4) : .clear,
                radius: configuration.isPressed ? 4 : 10,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Secondary — ghost fill, white text.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.10))
            .foregroundStyle(.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Accent — gremlin-eye yellow fill, bold text, strong glow. Use for the single
/// most important CTA on a screen (e.g. "Get Started").
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.sgYellow)
            .foregroundStyle(Color.sgBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: Color.sgYellow.opacity(0.45),
                radius: configuration.isPressed ? 4 : 12,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
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

// MARK: - Interactive Press Modifier
//
// Drop onto any tappable card for a subtle spring-press effect without
// needing a custom ButtonStyle.

struct InteractivePressModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
    }
}

extension View {
    func interactivePress() -> some View {
        modifier(InteractivePressModifier())
    }
}

// MARK: - Status Badge

struct StatusBadgeView: View {
    let badge: RuleStatusBadge

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badge.color)
                .frame(width: 6, height: 6)
            Text(badge.label)
                .font(.caption2).fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badge.color.opacity(0.15))
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
