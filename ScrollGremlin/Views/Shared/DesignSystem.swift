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
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.12, blue: 0.24, alpha: 1)
            : UIColor(white: 1, alpha: 1)
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
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color.sgTeal, Color(red: 0.04, green: 0.56, blue: 0.45)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static var accent: LinearGradient {
        LinearGradient(
            colors: [Color.sgYellow, Color(red: 0.96, green: 0.68, blue: 0.04)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    /// Hero card: soft blue → lavender → pink
    static var pastelHero: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.60, green: 0.83, blue: 0.95),
                Color(red: 0.74, green: 0.69, blue: 0.95),
                Color(red: 0.95, green: 0.76, blue: 0.88),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static var hero: LinearGradient { pastelHero }
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
// Full-screen layered background. Must be placed OUTSIDE NavigationStack so it
// bleeds behind the nav bar and tab bar.
//
// LIGHT MODE
//   Base: pastel linear gradient  #EAF6FF → #F3ECFF → #FFEFF6
//   Blob 1: sky blue  (#A8E6FF) top-left      — opacity 0.42, blur 90
//   Blob 2: lavender  (#C7B8FF) center-right  — opacity 0.36, blur 100
//   Blob 3: soft pink (#FFC7E5) bottom        — opacity 0.34, blur 110
//
// DARK MODE
//   Base: deep indigo  #0D0C1E
//   Blob 1: teal-cyan  top-right              — opacity 0.28, blur 90
//   Blob 2: violet     center-left            — opacity 0.24, blur 100
//   Blob 3: indigo-blue bottom-right          — opacity 0.20, blur 110

struct GradientBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // ── Base gradient ─────────────────────────────────────────────────
            if scheme == .light {
                LinearGradient(
                    colors: [
                        Color(red: 0.918, green: 0.965, blue: 1.000),  // #EAF6FF
                        Color(red: 0.953, green: 0.925, blue: 1.000),  // #F3ECFF
                        Color(red: 1.000, green: 0.937, blue: 0.965),  // #FFEFF6
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                Color(red: 0.051, green: 0.047, blue: 0.118) // deep indigo #0D0C1E
                    .ignoresSafeArea()
            }

            // ── Blurred radial blobs ──────────────────────────────────────────
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    if scheme == .light {
                        // Sky blue — top-left
                        Circle()
                            .fill(Color(red: 0.659, green: 0.902, blue: 1.000).opacity(0.42))
                            .frame(width: 380)
                            .offset(x: -w * 0.15, y: -h * 0.04)
                            .blur(radius: 90)

                        // Lavender — center-right
                        Circle()
                            .fill(Color(red: 0.780, green: 0.722, blue: 1.000).opacity(0.36))
                            .frame(width: 340)
                            .offset(x: w * 0.40, y: h * 0.30)
                            .blur(radius: 100)

                        // Soft pink — bottom
                        Circle()
                            .fill(Color(red: 1.000, green: 0.780, blue: 0.898).opacity(0.34))
                            .frame(width: 360)
                            .offset(x: w * 0.08, y: h * 0.65)
                            .blur(radius: 110)

                    } else {
                        // Teal-cyan — top-right
                        Circle()
                            .fill(Color(red: 0.10, green: 0.72, blue: 0.82).opacity(0.28))
                            .frame(width: 360)
                            .offset(x: w * 0.55, y: -h * 0.06)
                            .blur(radius: 90)

                        // Violet — center-left
                        Circle()
                            .fill(Color(red: 0.52, green: 0.36, blue: 0.90).opacity(0.24))
                            .frame(width: 340)
                            .offset(x: -w * 0.10, y: h * 0.35)
                            .blur(radius: 100)

                        // Indigo-blue — bottom-right
                        Circle()
                            .fill(Color(red: 0.28, green: 0.44, blue: 0.90).opacity(0.20))
                            .frame(width: 320)
                            .offset(x: w * 0.45, y: h * 0.70)
                            .blur(radius: 110)
                    }
                }
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}

// Legacy alias
typealias SGAmbientBackground = GradientBackground

// MARK: - GlassCard
//
// Adaptive translucent card. Looks designed in both light and dark mode.
//
// Light: bright white-glass (white 0.72) + top shimmer + white stroke
// Dark:  deep indigo-glass (#231F3D at 0.78) + top shimmer + soft white stroke
//
// ultraThinMaterial is added as an additional blur layer so any background
// colour bleeds through softly.

struct GlassCard: View {
    var cornerRadius: CGFloat = 24
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Base adaptive fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(scheme == .dark
                    ? Color(red: 0.137, green: 0.122, blue: 0.239) // #231F3D
                    : Color.white.opacity(0.72)
                )

            // Material blur layer (picks up background colour)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .opacity(scheme == .dark ? 0.55 : 0.45)

            // Top shimmer — the "lit from above" signature
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: [
                        Color.white.opacity(scheme == .dark ? 0.12 : 0.68),
                        Color.clear,
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.52)
                ))

            // Stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.22), lineWidth: 1)
        }
    }
}

// Legacy alias
typealias GlassSurface = GlassCard

// MARK: - SGHeroCardSurface
//
// Pastel iridescent gradient — blue → lavender → pink.
// Used only for the dashboard hero banner.

struct SGHeroCardSurface: View {
    var cornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(SGGradient.pastelHero)

            // Inner shimmer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.32), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.55)
                ))

            // Highlight stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }
}

// MARK: - SGMascotFrame (STEP 9)

struct SGMascotFrame: View {
    var size: CGFloat = 80
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Circle()
                .fill(scheme == .dark
                    ? Color(red: 0.20, green: 0.18, blue: 0.34).opacity(0.90)
                    : Color.white.opacity(0.55)
                )
                .frame(width: size, height: size)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .opacity(0.6)
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                .frame(width: size, height: size)
        }
        .shadow(radius: 10)
    }
}

// MARK: - SGCardModifier
//
// Wraps content in the GlassCard visual system.
// Active state = teal border glow + teal shadow. Never a fill colour change.
// Both light and dark mode look like premium glass panels.

struct SGCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var isActive: Bool = false
    var isLocked: Bool = false
    var cornerRadius: CGFloat = 24

    private var glowColor: Color {
        isActive ? Color.sgTeal : isLocked ? Color(red: 0.50, green: 0.58, blue: 0.92) : .clear
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Adaptive base fill
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(scheme == .dark
                            ? Color(red: 0.137, green: 0.122, blue: 0.239)
                            : Color.white.opacity(0.72)
                        )
                    // Material blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(scheme == .dark ? 0.55 : 0.45)
                    // Active tint — just 6% max, no heavy fill
                    if isActive || isLocked {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(glowColor.opacity(scheme == .dark ? 0.08 : 0.04))
                    }
                    // Top shimmer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(scheme == .dark ? 0.12 : 0.68),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.52)
                        ))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Inner highlight stroke
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(scheme == .dark ? 0.18 : 0.72),
                                Color.white.opacity(0.02),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Active/locked accent border ring
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(isActive || isLocked ? 0.50 : 0), lineWidth: 1.5)
            )
            // Glow shadow when active/locked
            .shadow(
                color: glowColor.opacity(isActive ? 0.22 : isLocked ? 0.14 : 0),
                radius: 18, y: 7
            )
            // Base depth shadow
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.35 : 0.08),
                radius: isActive ? 18 : 14,
                y: isActive ? 7 : 5
            )
    }
}

extension View {
    func sgCard(active: Bool = false, locked: Bool = false, cornerRadius: CGFloat = 24) -> some View {
        modifier(SGCardModifier(isActive: active, isLocked: locked, cornerRadius: cornerRadius))
    }
}

// MARK: - Surface Background

struct SurfaceBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack { GradientBackground(); content }
    }
}

extension View {
    func sgSurfaceBackground() -> some View { modifier(SurfaceBackgroundModifier()) }
    func sgPageBackground()    -> some View { modifier(SurfaceBackgroundModifier()) }
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

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(scheme == .dark ? Color.white.opacity(0.55) : Color.primary.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(.ultraThinMaterial.opacity(0.90))
    }
}

// MARK: - Typography

extension View {
    func scrollGremlinTitle() -> some View {
        self.font(.title2).fontWeight(.semibold).foregroundStyle(.white)
    }
    func scrollGremlinSubtitle() -> some View {
        self.font(.subheadline).foregroundStyle(.white.opacity(0.5))
    }
}

// MARK: - Status Badge (STEP 3)
//
// Glass-style badge — no plain solid pill.
// Light: white-tinted glass with coloured text.
// Dark: dark glass with coloured text.

struct StatusBadgeView: View {
    let badge: RuleStatusBadge
    var onColoredSurface: Bool = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(onColoredSurface ? Color.white : badge.color)
                .frame(width: 6, height: 6)
            Text(badge.label)
                .font(.caption2).fontWeight(.semibold)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            ZStack {
                Capsule()
                    .fill(onColoredSurface
                        ? Color.white.opacity(0.22)
                        : (scheme == .dark
                            ? badge.color.opacity(0.18)
                            : badge.color.opacity(0.12))
                    )
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
                Capsule()
                    .stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.30), lineWidth: 0.5)
            }
        )
        .foregroundStyle(onColoredSurface ? .white : badge.color)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: badge)
    }
}

// MARK: - Button Styles

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

// GlassButtonStyle — white gradient capsule (STEP 6)
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.70), Color.white.opacity(0.40)],
                        startPoint: .top, endPoint: .bottom
                    ))
            )
            .foregroundStyle(Color.primary)
            .clipShape(Capsule())
            .shadow(radius: 6)
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
