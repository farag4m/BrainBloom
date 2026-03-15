import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let sgTeal       = Color(red: 0.08, green: 0.78, blue: 0.62)
    static let sgTealDark   = Color(red: 0.03, green: 0.48, blue: 0.38)
    static let sgYellow     = Color(red: 1.00, green: 0.82, blue: 0.13)
    static let sgBackground = Color(red: 0.04, green: 0.11, blue: 0.10)

    static let scrollGremlinPrimary    = sgTeal
    static let scrollGremlinBackground = sgBackground
    static let sgCardSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(red: 0.10, green: 0.17, blue: 0.15, alpha: 1) : .white
    })
    static let scrollGremlinSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 0, alpha: 0.04)
    })
    static let scrollGremlinBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.12) : UIColor(white: 0, alpha: 0.08)
    })
}

extension UIColor {
    static let scrollGremlinPrimary    = UIColor(red: 0.08, green: 0.78, blue: 0.62, alpha: 1)
    static let scrollGremlinBackground = UIColor(red: 0.04, green: 0.11, blue: 0.10, alpha: 0.95)
}

// MARK: - Gradient Library

enum SGGradient {
    /// Brand — teal to deeper teal. Buttons, active indicators.
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color.sgTeal, Color(red: 0.04, green: 0.56, blue: 0.45)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    /// Yellow accent.
    static var accent: LinearGradient {
        LinearGradient(
            colors: [Color.sgYellow, Color(red: 0.96, green: 0.68, blue: 0.04)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    /// Pastel hero — soft cyan-teal → sky blue → lavender.
    /// Derived directly from the reference's iridescent card.
    static var pastelHero: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.18, green: 0.76, blue: 0.88), location: 0.0),
                .init(color: Color(red: 0.44, green: 0.68, blue: 0.96), location: 0.45),
                .init(color: Color(red: 0.66, green: 0.58, blue: 0.94), location: 1.0),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    /// Legacy alias — kept so existing call sites compile.
    static var hero: LinearGradient { pastelHero }
    /// Immersive dark — onboarding / unlock screens.
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
    static var pageTint: LinearGradient {
        LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
    }
    static func cardSheen(opacity: Double = 0.06) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.sgTeal.opacity(opacity), location: 0),
                .init(color: Color.clear, location: 0.65),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - GradientBackground
//
// Layered pastel environment — derived from reference image analysis:
//
//   LIGHT: near-white base (#F6F6FA), then:
//     • Warm peach/cream ellipse  — top-right (reference's large organic warm shape)
//     • Soft sky-blue circle      — bottom-left  (reference's cool accent blob)
//     • Soft lavender hint        — centre       (adds pastel depth)
//
//   DARK: deep neutral base with low-opacity versions of the same blobs.
//
// Teal/green is intentionally absent from the background — it only appears
// as an accent colour on interactive elements.

struct GradientBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Color(UIColor { t in
                t.userInterfaceStyle == .dark
                    ? UIColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 1)
                    : UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
            })
            .ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    if scheme == .light {
                        // Warm peach/cream blob — top-right
                        Ellipse()
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.72).opacity(0.70))
                            .frame(width: 360, height: 430)
                            .rotationEffect(.degrees(18))
                            .offset(x: w - 65, y: -115)
                            .blur(radius: 105)

                        // Soft sky-blue blob — bottom-left
                        Circle()
                            .fill(Color(red: 0.50, green: 0.73, blue: 0.98).opacity(0.14))
                            .frame(width: 320)
                            .offset(x: -55, y: h - 55)
                            .blur(radius: 92)

                        // Soft lavender hint — centre
                        Circle()
                            .fill(Color(red: 0.72, green: 0.66, blue: 0.96).opacity(0.09))
                            .frame(width: 260)
                            .offset(x: w * 0.38, y: h * 0.38)
                            .blur(radius: 84)
                    } else {
                        // Dark: muted blue blob top-right
                        Circle()
                            .fill(Color(red: 0.32, green: 0.52, blue: 0.80).opacity(0.10))
                            .frame(width: 300)
                            .offset(x: w - 70, y: -100)
                            .blur(radius: 88)
                        // Dark: teal accent bottom-left
                        Circle()
                            .fill(Color.sgTeal.opacity(0.09))
                            .frame(width: 280)
                            .offset(x: -55, y: h - 50)
                            .blur(radius: 80)
                        // Dark: lavender centre
                        Circle()
                            .fill(Color(red: 0.50, green: 0.44, blue: 0.78).opacity(0.06))
                            .frame(width: 230)
                            .offset(x: w * 0.44, y: h * 0.42)
                            .blur(radius: 72)
                    }
                }
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}

// Legacy alias so existing call sites compile.
typealias SGAmbientBackground = GradientBackground

// MARK: - GlassSurface
//
// The core glass panel primitive. Four layers stacked:
//
//   1. ultraThinMaterial  — iOS frosted blur, adapts to light/dark
//   2. White veil         — makes the panel read as "floating white" not just blurry
//   3. Optional tint      — tiny accent tint (active: 5% teal, locked: 5% blue)
//   4. Inner shimmer      — bright wash at the very top, fades by 50% height
//                           This is the "lit from above" glass characteristic.

struct GlassSurface: View {
    var cornerRadius: CGFloat = 20
    var tint: Color = .clear
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(scheme == .dark ? 0.04 : 0.52))

            if tint != .clear {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(tint.opacity(scheme == .dark ? 0.10 : 0.05))
            }

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(scheme == .dark ? 0.11 : 0.76),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.50)
                    )
                )
        }
    }
}

// MARK: - Pastel Hero Card Surface
//
// Full iridescent gradient card — used only for the dashboard hero card.
// All other cards use GlassSurface (translucent, not filled).

struct SGHeroCardSurface: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(SGGradient.pastelHero)

            // Inner shimmer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.28), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.52)
                ))

            // White accent circles — partial depth shapes
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: geo.size.height * 2.2)
                        .offset(x: geo.size.width  - geo.size.height * 0.85,
                                y: -geo.size.height * 0.55)
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: geo.size.height * 1.40)
                        .offset(x: geo.size.width  - geo.size.height * 0.16,
                                y:  geo.size.height * 0.28)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Top-edge glass stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.42), .white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Reusable Supporting Views

struct SGImmersiveBackground: View {
    var body: some View { SGGradient.immersiveDark.ignoresSafeArea() }
}

struct SGMascotGlow: View {
    var size: CGFloat = 200
    var body: some View {
        Circle()
            .fill(RadialGradient(
                colors: [Color.sgTeal.opacity(0.24), Color.sgTeal.opacity(0.05), Color.clear],
                center: .center, startRadius: 0, endRadius: size / 2
            ))
            .frame(width: size, height: size)
            .blur(radius: 20)
    }
}

/// Glass coin ring that frames mascot images — makes them feel part of the surface.
struct SGMascotFrame: View {
    var size: CGFloat = 80
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: size, height: size)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: size, height: size)
        }
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}

// MARK: - Surface Background

struct SurfaceBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack { GradientBackground(); content }
    }
}

struct SGPageBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(SurfaceBackgroundModifier()) }
}

extension View {
    func sgSurfaceBackground() -> some View { modifier(SurfaceBackgroundModifier()) }
    func sgPageBackground()    -> some View { modifier(SurfaceBackgroundModifier()) }
}

// MARK: - Glass Card Modifier
//
// Wraps any view in a GlassSurface and adds:
//   • Top-edge white highlight stroke (the glass signature)
//   • Active/locked accent border   (teal glow when active — accent only, not fill)
//   • Layered depth shadows         (stronger + teal-tinted when active)
//
// Cards are NEVER filled with solid colour — GlassSurface keeps them translucent.
// The active state is communicated through the border glow and shadow, not the fill.

struct SGCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var isActive: Bool = false
    var isLocked: Bool = false
    var cornerRadius: CGFloat = 20

    private var accentTint: Color {
        isActive ? Color.sgTeal : isLocked ? Color(red: 0.50, green: 0.58, blue: 0.84) : .clear
    }

    func body(content: Content) -> some View {
        content
            .background(GlassSurface(cornerRadius: cornerRadius, tint: accentTint))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Inner glass top-edge highlight
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(scheme == .dark ? 0.20 : 0.88),
                                .white.opacity(0.02),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Accent border ring (teal when active, muted blue when locked, invisible otherwise)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accentTint.opacity(isActive || isLocked ? 0.42 : 0), lineWidth: 1.5)
            )
            // Coloured glow shadow when active
            .shadow(color: accentTint.opacity(isActive ? 0.22 : isLocked ? 0.12 : 0), radius: 20, y: 8)
            // Main depth shadow
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.30 : (isActive ? 0.09 : 0.06)),
                radius: isActive ? 18 : 10,
                y: isActive ? 6 : 3
            )
            .shadow(color: .black.opacity(0.025), radius: 1, y: 1)
    }
}

extension View {
    func sgCard(active: Bool = false, locked: Bool = false, cornerRadius: CGFloat = 20) -> some View {
        modifier(SGCardModifier(isActive: active, isLocked: locked, cornerRadius: cornerRadius))
    }
}

// Convenience alias for explicit usage
typealias GlassCard = GlassSurface

// MARK: - Typography

extension View {
    func scrollGremlinTitle() -> some View {
        self.font(.title2).fontWeight(.semibold).foregroundStyle(.white)
    }
    func scrollGremlinSubtitle() -> some View {
        self.font(.subheadline).foregroundStyle(.white.opacity(0.5))
    }
}

// MARK: - Button Styles
//
// All buttons are pill (Capsule) shaped.
// Primary uses teal gradient — the brand's intentional accent colour.
// Secondary/Glass use ultraThinMaterial for the glass look.

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? AnyView(SGGradient.brand) : AnyView(Color.white.opacity(0.12)))
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [.white.opacity(isEnabled ? 0.30 : 0.08), .white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .foregroundStyle(isEnabled ? Color.sgBackground : Color.white.opacity(0.35))
            .clipShape(Capsule())
            .shadow(
                color: isEnabled ? Color.sgTeal.opacity(configuration.isPressed ? 0.18 : 0.34) : .clear,
                radius: configuration.isPressed ? 4 : 14, y: configuration.isPressed ? 2 : 6
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
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.42), .white.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .foregroundStyle(.white.opacity(0.88))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SGGradient.accent)
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.34), .white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .foregroundStyle(Color.sgBackground)
            .clipShape(Capsule())
            .shadow(
                color: Color.sgYellow.opacity(configuration.isPressed ? 0.22 : 0.50),
                radius: configuration.isPressed ? 4 : 15, y: configuration.isPressed ? 2 : 7
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.44), .white.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.80 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Interactive Press

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
    func interactivePress() -> some View { modifier(InteractivePressModifier()) }
}

// MARK: - Legacy CardView

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content.padding().sgCard() }
}

// MARK: - Status Badge

struct StatusBadgeView: View {
    let badge: RuleStatusBadge
    /// Set true when this badge sits on a vivid coloured surface (e.g. hero card).
    var onColoredSurface: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(onColoredSurface ? Color.white : badge.color)
                .frame(width: 6, height: 6)
            Text(badge.label)
                .font(.caption2).fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(onColoredSurface ? Color.white.opacity(0.22) : badge.color.opacity(0.13))
        .foregroundStyle(onColoredSurface ? .white : badge.color)
        .clipShape(Capsule())
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: badge)
    }
}

// MARK: - AppColorScheme

extension AppColorScheme {
    var swiftUIColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
