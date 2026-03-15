import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Core brand palette
    static let sgTeal       = Color(red: 0.08, green: 0.78, blue: 0.62)
    static let sgTealDark   = Color(red: 0.03, green: 0.48, blue: 0.38)
    static let sgYellow     = Color(red: 1.00, green: 0.82, blue: 0.13)
    static let sgBackground = Color(red: 0.04, green: 0.11, blue: 0.10)

    // Legacy aliases — keeps every existing call site compiling.
    static let scrollGremlinPrimary    = sgTeal
    static let scrollGremlinBackground = sgBackground

    // Adaptive card surface: teal-tinted dark in dark mode, white in light.
    static let sgCardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.17, blue: 0.15, alpha: 1)
            : .white
    })

    // Adaptive subtle surface (for permission rows, info rows).
    static let scrollGremlinSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.07)
            : UIColor(white: 0, alpha: 0.04)
    })

    // Adaptive border.
    static let scrollGremlinBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.12)
            : UIColor(white: 0, alpha: 0.08)
    })
}

extension UIColor {
    static let scrollGremlinPrimary    = UIColor(red: 0.08, green: 0.78, blue: 0.62, alpha: 1)
    static let scrollGremlinBackground = UIColor(red: 0.04, green: 0.11, blue: 0.10, alpha: 0.95)
}

// MARK: - Gradient Library

enum SGGradient {
    /// Brand gradient — teal to deeper teal. Primary buttons, active accents.
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color.sgTeal, Color(red: 0.04, green: 0.56, blue: 0.45)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    /// Yellow accent gradient — "Get Started" / highest-priority CTA.
    static var accent: LinearGradient {
        LinearGradient(
            colors: [Color.sgYellow, Color(red: 0.96, green: 0.68, blue: 0.04)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    /// Hero wash — tinted gradient for header / card backgrounds.
    static var hero: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.sgTeal.opacity(0.22), location: 0),
                .init(color: Color.sgTeal.opacity(0.07), location: 0.6),
                .init(color: Color.clear,                location: 1.0),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    /// Immersive dark — multi-stop for onboarding and unlock screens.
    static var immersiveDark: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.06, green: 0.20, blue: 0.17), location: 0.0),
                .init(color: Color(red: 0.04, green: 0.13, blue: 0.11), location: 0.5),
                .init(color: Color(red: 0.02, green: 0.07, blue: 0.06), location: 1.0),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// Page tint — barely-there teal wash at the top of main app screens.
    static var pageTint: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.sgTeal.opacity(0.10), location: 0),
                .init(color: Color.clear,                location: 0.55),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// Card sheen — subtle inner gradient overlay on premium cards.
    static func cardSheen(opacity: Double = 0.06) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.sgTeal.opacity(opacity), location: 0),
                .init(color: Color.clear,                   location: 0.65),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Reusable Background Views

/// Full-screen gradient for onboarding / unlock immersive screens.
struct SGImmersiveBackground: View {
    var body: some View {
        SGGradient.immersiveDark.ignoresSafeArea()
    }
}

/// Radial teal glow — place behind a mascot image for depth.
struct SGMascotGlow: View {
    var size: CGFloat = 200

    var body: some View {
        Circle()
            .fill(RadialGradient(
                colors: [Color.sgTeal.opacity(0.30), Color.sgTeal.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: size / 2
            ))
            .frame(width: size, height: size)
            .blur(radius: 22)
    }
}

// MARK: - Page Background Modifier
//
// Applies a soft teal gradient tint at the top of standard (non-immersive) screens.

struct SGPageBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            SGGradient.pageTint
                .frame(maxWidth: .infinity, maxHeight: 400)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            content
        }
    }
}

extension View {
    func sgPageBackground() -> some View {
        modifier(SGPageBackgroundModifier())
    }
}

// MARK: - Premium Card Modifier
//
// Replaces the flat secondarySystemGroupedBackground pattern with a layered,
// shadow-rich surface. Supports active (unlocked), locked, and default states.

struct SGCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var isActive: Bool = false
    var isLocked: Bool = false
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base surface
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.sgCardSurface)
                    // Gradient sheen
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(SGGradient.cardSheen(opacity: isActive ? 0.10 : 0.04))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Coloured glow
            .shadow(
                color: Color.sgTeal.opacity(isActive ? 0.20 : isLocked ? 0.13 : 0.07),
                radius: isActive ? 22 : 12,
                y: isActive ? 7 : 3
            )
            // Crisp depth shadow
            .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.05), radius: 2, y: 1)
            // Gradient border
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.sgTeal.opacity(isActive ? 0.30 : isLocked ? 0.20 : 0.10),
                                Color.sgTeal.opacity(0.03),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func sgCard(active: Bool = false, locked: Bool = false, cornerRadius: CGFloat = 18) -> some View {
        modifier(SGCardModifier(isActive: active, isLocked: locked, cornerRadius: cornerRadius))
    }
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

/// Primary — brand gradient fill, dark foreground text, glow shadow.
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if isEnabled {
                        AnyView(SGGradient.brand)
                    } else {
                        AnyView(Color.white.opacity(0.15))
                    }
                }
            )
            .foregroundStyle(isEnabled ? Color.sgBackground : Color.white.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: isEnabled
                    ? Color.sgTeal.opacity(configuration.isPressed ? 0.20 : 0.42)
                    : .clear,
                radius: configuration.isPressed ? 4 : 13,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Secondary — frosted glass look; works on both dark and light backgrounds.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .foregroundStyle(.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Accent — gremlin-eye yellow gradient, bold text, warm glow.
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(SGGradient.accent)
            .foregroundStyle(Color.sgBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: Color.sgYellow.opacity(configuration.isPressed ? 0.25 : 0.52),
                radius: configuration.isPressed ? 4 : 15,
                y: configuration.isPressed ? 2 : 7
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Interactive Press Modifier

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

// MARK: - Legacy CardView (kept for compatibility)

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .sgCard()
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
    var swiftUIColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
