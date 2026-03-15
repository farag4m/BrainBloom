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
            ? UIColor(red: 0.12, green: 0.09, blue: 0.23, alpha: 1)
            : UIColor(red: 0.84, green: 0.91, blue: 0.97, alpha: 1)
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
    /// Hero + page blobs: soft blue → lavender → pink
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
// Full-screen background. Placed OUTSIDE NavigationStack with ignoresSafeArea.
//
// LIGHT MODE
//   Base gradient: clearly-blue #DAEEFF → clearly-lavender #E5DEFF → clearly-pink #FFDFF0
//   Blob 1: sky blue    top-left        opacity 0.55  blur 80
//   Blob 2: lavender    center-right    opacity 0.48  blur 95
//   Blob 3: rose-pink   bottom          opacity 0.44  blur 105
//
// DARK MODE
//   Base gradient: deep navy #120D2A → deep indigo #0E0B22 → very dark purple #150E24
//   Blob 1: bright teal    top-right    opacity 0.38  blur 80
//   Blob 2: violet         center-left  opacity 0.32  blur 95
//   Blob 3: royal blue     bottom-right opacity 0.28  blur 105

struct GradientBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // ── Base gradient ─────────────────────────────────────────────────
            if scheme == .light {
                LinearGradient(
                    colors: [
                        Color(red: 0.855, green: 0.933, blue: 1.000),  // clearly sky-blue
                        Color(red: 0.898, green: 0.871, blue: 1.000),  // clearly lavender
                        Color(red: 1.000, green: 0.875, blue: 0.941),  // clearly soft pink
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.071, green: 0.051, blue: 0.165),  // deep navy-indigo
                        Color(red: 0.055, green: 0.043, blue: 0.122),
                        Color(red: 0.082, green: 0.055, blue: 0.141),  // deep purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                            .fill(Color(red: 0.549, green: 0.839, blue: 1.000).opacity(0.55))
                            .frame(width: 360)
                            .offset(x: -w * 0.18, y: -h * 0.02)
                            .blur(radius: 80)

                        // Lavender — center-right
                        Circle()
                            .fill(Color(red: 0.722, green: 0.647, blue: 1.000).opacity(0.48))
                            .frame(width: 320)
                            .offset(x: w * 0.42, y: h * 0.28)
                            .blur(radius: 95)

                        // Rose-pink — bottom
                        Circle()
                            .fill(Color(red: 1.000, green: 0.671, blue: 0.831).opacity(0.44))
                            .frame(width: 340)
                            .offset(x: w * 0.06, y: h * 0.66)
                            .blur(radius: 105)

                    } else {
                        // Bright teal — top-right
                        Circle()
                            .fill(Color(red: 0.059, green: 0.780, blue: 0.780).opacity(0.38))
                            .frame(width: 340)
                            .offset(x: w * 0.50, y: -h * 0.04)
                            .blur(radius: 80)

                        // Violet — center-left
                        Circle()
                            .fill(Color(red: 0.561, green: 0.318, blue: 0.961).opacity(0.32))
                            .frame(width: 320)
                            .offset(x: -w * 0.08, y: h * 0.33)
                            .blur(radius: 95)

                        // Royal blue — bottom-right
                        Circle()
                            .fill(Color(red: 0.200, green: 0.400, blue: 0.961).opacity(0.28))
                            .frame(width: 300)
                            .offset(x: w * 0.48, y: h * 0.68)
                            .blur(radius: 105)
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
// Explicitly tinted glass surface. Does NOT use white fill.
//
// Light: soft periwinkle-blue tint  rgb(0.82, 0.90, 0.97) at 88% — clearly blue-tinted
// Dark:  deep indigo-purple tint    rgb(0.12, 0.09, 0.23) at 92% — clearly purple

struct GlassCard: View {
    var cornerRadius: CGFloat = 24
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Explicit tinted base — what makes it NOT white/black
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(scheme == .dark
                    ? Color(red: 0.118, green: 0.090, blue: 0.227)
                    : Color(red: 0.820, green: 0.902, blue: 0.969)
                )

            // ultraThinMaterial as a softening layer only
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .opacity(0.40)

            // Top shimmer — lit from above
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: [
                        Color.white.opacity(scheme == .dark ? 0.14 : 0.55),
                        Color.clear,
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.50)
                ))

            // Stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(scheme == .dark ? 0.16 : 0.55), lineWidth: 1)
        }
    }
}

// Legacy alias
typealias GlassSurface = GlassCard

// MARK: - Hero Card Surface
//
// Pastel iridescent gradient — blue → lavender → pink.

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
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        }
    }
}

// MARK: - SGMascotFrame

struct SGMascotFrame: View {
    var size: CGFloat = 80
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Circle()
                .fill(scheme == .dark
                    ? Color(red: 0.20, green: 0.15, blue: 0.36)
                    : Color(red: 0.78, green: 0.88, blue: 0.97)
                )
                .frame(width: size, height: size)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .opacity(0.5)
            Circle()
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
                .frame(width: size, height: size)
        }
        .shadow(radius: 10)
    }
}

// MARK: - SGCardModifier
//
// The card surface. Explicitly tinted — does NOT use white fill.
//
// Light: periwinkle-blue rgb(0.82, 0.90, 0.97) base. Reads as soft blue glass.
// Dark:  indigo-purple   rgb(0.12, 0.09, 0.22) base. Reads as deep purple glass.
//
// Active: teal glow border + shadow. No fill colour change.

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
                    // Explicitly tinted base
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(scheme == .dark
                            ? Color(red: 0.118, green: 0.090, blue: 0.220)
                            : Color(red: 0.820, green: 0.902, blue: 0.969)
                        )
                    // ultraThinMaterial softening layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.40)
                    // Active/locked accent wash — very subtle
                    if isActive || isLocked {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(glowColor.opacity(scheme == .dark ? 0.10 : 0.06))
                    }
                    // Top shimmer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(scheme == .dark ? 0.14 : 0.55),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.50)
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
                                Color.white.opacity(scheme == .dark ? 0.20 : 0.60),
                                Color.white.opacity(0.02),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Active border ring
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(isActive || isLocked ? 0.55 : 0), lineWidth: 1.5)
            )
            // Glow shadow
            .shadow(color: glowColor.opacity(isActive ? 0.25 : isLocked ? 0.16 : 0), radius: 18, y: 7)
            // Depth shadow
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.40 : 0.10),
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

// MARK: - AddRuleButton
//
// Teal gradient circle — replaces the plain white system button in toolbars.

struct AddRuleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Teal gradient fill
                Circle()
                    .fill(SGGradient.brand)
                    .frame(width: 34, height: 34)
                // Inner shimmer
                Circle()
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.30), .clear],
                        startPoint: .top, endPoint: .center
                    ))
                    .frame(width: 34, height: 34)
                // Icon
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.sgTeal.opacity(0.45), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header
//
// Explicitly tinted glass strip — NOT plain white/clear.
// Light: soft blue-tinted frosted band
// Dark:  deep indigo-tinted frosted band

struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(scheme == .dark
                ? Color.white.opacity(0.70)
                : Color(red: 0.20, green: 0.28, blue: 0.45)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                ZStack {
                    scheme == .dark
                        ? Color(red: 0.10, green: 0.08, blue: 0.20).opacity(0.92)
                        : Color(red: 0.82, green: 0.90, blue: 0.97).opacity(0.88)
                    Color.clear.background(.ultraThinMaterial).opacity(0.50)
                }
            )
    }
}

// MARK: - Status Badge
//
// Tinted glass capsule — no plain solid pill.

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
                        ? Color.white.opacity(0.25)
                        : (scheme == .dark
                            ? badge.color.opacity(0.22)
                            : badge.color.opacity(0.15))
                    )
                Capsule()
                    .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.40), lineWidth: 0.5)
            }
        )
        .foregroundStyle(onColoredSurface ? .white : badge.color)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: badge)
    }
}

// MARK: - Surface Background

struct SurfaceBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack { GradientBackground().ignoresSafeArea(); content }
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
