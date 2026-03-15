import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary accent — soft periwinkle/lavender matching the liquid glass palette
    static let sgTeal       = Color(red: 0.55, green: 0.58, blue: 0.98)
    static let sgTealDark   = Color(red: 0.38, green: 0.40, blue: 0.80)
    static let sgYellow     = Color(red: 1.00, green: 0.82, blue: 0.13)
    // Background — deep indigo matching the new GradientBackground dark base
    static let sgBackground = Color(red: 0.06, green: 0.038, blue: 0.150)

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
    static let scrollGremlinPrimary    = UIColor(red: 0.55, green: 0.58, blue: 0.98, alpha: 1)
    static let scrollGremlinBackground = UIColor(red: 0.06, green: 0.038, blue: 0.150, alpha: 0.95)
}

// MARK: - Gradient Library

enum SGGradient {
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color.sgTeal, Color(red: 0.40, green: 0.42, blue: 0.88)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static var accent: LinearGradient {
        LinearGradient(
            colors: [Color.sgYellow, Color(red: 0.96, green: 0.68, blue: 0.04)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    /// Hero + page blobs: vivid sky blue → lavender → pink
    static var pastelHero: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.72, blue: 0.98),  // vivid sky blue
                Color(red: 0.62, green: 0.55, blue: 0.98),  // medium lavender
                Color(red: 0.92, green: 0.65, blue: 0.88),  // warm pink
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
                .init(color: Color(red: 0.62, green: 0.65, blue: 1.00).opacity(opacity), location: 0),
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
            // ── Layer 1: base gradient — CardDesignReference inspired ───────────
            if scheme == .light {
                // Vibrant sky blue → lavender → blush — richer than before
                LinearGradient(
                    colors: [
                        Color(red: 0.580, green: 0.780, blue: 0.980),  // vibrant sky blue
                        Color(red: 0.720, green: 0.640, blue: 0.980),  // medium lavender
                        Color(red: 0.940, green: 0.740, blue: 0.920),  // blush pink
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                // Deep violet-purple → indigo — inspired by CardDesignReference header
                LinearGradient(
                    colors: [
                        Color(red: 0.220, green: 0.090, blue: 0.420),  // rich violet top
                        Color(red: 0.110, green: 0.055, blue: 0.260),  // deep purple mid
                        Color(red: 0.060, green: 0.038, blue: 0.150),  // near-black indigo bottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            // ── Layer 2: large blurred blobs ─────────────────────────────────────
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    if scheme == .light {
                        // Bright sky blue — top-left
                        Circle()
                            .fill(Color(red: 0.350, green: 0.680, blue: 1.000).opacity(0.38))
                            .frame(width: 460)
                            .offset(x: -w * 0.20, y: -h * 0.05)
                            .blur(radius: 120)

                        // Vivid purple — center-right
                        Circle()
                            .fill(Color(red: 0.580, green: 0.400, blue: 1.000).opacity(0.32))
                            .frame(width: 420)
                            .offset(x: w * 0.44, y: h * 0.26)
                            .blur(radius: 140)

                        // Hot pink — bottom-left
                        Circle()
                            .fill(Color(red: 1.000, green: 0.420, blue: 0.700).opacity(0.28))
                            .frame(width: 400)
                            .offset(x: w * 0.02, y: h * 0.65)
                            .blur(radius: 130)

                    } else {
                        // Bright magenta-violet — top, bleeds into the header area
                        Circle()
                            .fill(Color(red: 0.650, green: 0.200, blue: 0.900).opacity(0.45))
                            .frame(width: 420)
                            .offset(x: w * 0.30, y: -h * 0.08)
                            .blur(radius: 110)

                        // Deep indigo-blue — center-left
                        Circle()
                            .fill(Color(red: 0.220, green: 0.150, blue: 0.780).opacity(0.38))
                            .frame(width: 380)
                            .offset(x: -w * 0.10, y: h * 0.32)
                            .blur(radius: 140)

                        // Soft teal accent — bottom-right (keeps depth)
                        Circle()
                            .fill(Color(red: 0.080, green: 0.480, blue: 0.780).opacity(0.28))
                            .frame(width: 340)
                            .offset(x: w * 0.46, y: h * 0.68)
                            .blur(radius: 120)
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
// ultraThinMaterial base + blue→purple gradient overlay = visible color tone.
// The overlay provides the tint; ultraThinMaterial provides the frosted depth.
// Works in both light and dark mode without relying on what's behind it.

struct GlassCard: View {
    var cornerRadius: CGFloat = 24
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Base blur/frost
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

            // Color tint overlay — this is what makes it NOT white
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: scheme == .dark ? [
                        Color(red: 0.20, green: 0.12, blue: 0.45).opacity(0.55),
                        Color(red: 0.12, green: 0.08, blue: 0.30).opacity(0.45),
                        Color.clear,
                    ] : [
                        Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.18),
                        Color(red: 0.60, green: 0.45, blue: 0.95).opacity(0.12),
                        Color.clear,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            // Top shimmer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(scheme == .dark ? 0.12 : 0.50), Color.clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.45)
                ))

            // Stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(scheme == .dark ? 0.16 : 0.50), lineWidth: 1)
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
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
            Circle()
                .fill(LinearGradient(
                    colors: scheme == .dark ? [
                        Color(red: 0.20, green: 0.12, blue: 0.45).opacity(0.60),
                        Color(red: 0.12, green: 0.08, blue: 0.30).opacity(0.40),
                    ] : [
                        Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.22),
                        Color(red: 0.60, green: 0.45, blue: 0.95).opacity(0.14),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            Circle()
                .stroke(Color.white.opacity(0.40), lineWidth: 1)
                .frame(width: size, height: size)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
}

// MARK: - SGCardModifier
//
// The card surface. Explicitly tinted — does NOT use white fill.
//
// Light: periwinkle-blue rgb(0.82, 0.90, 0.97) base. Reads as soft blue glass.
// Dark:  indigo-purple   rgb(0.12, 0.09, 0.22) base. Reads as deep purple glass.
//
// Active: iridescent prismatic shimmer border + brighter top shimmer. No fill colour change, no neon glow.

struct SGCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var isActive: Bool = false
    var isLocked: Bool = false
    var cornerRadius: CGFloat = 24

    // Iridescent prismatic stroke colors — used for active & locked, no neon
    private var shimmerStrokeColors: [Color] {
        if isActive {
            return scheme == .dark ? [
                Color.white.opacity(0.55),
                Color(red: 0.72, green: 0.68, blue: 1.00).opacity(0.60),
                Color(red: 0.85, green: 0.60, blue: 0.90).opacity(0.45),
                Color.white.opacity(0.30),
            ] : [
                Color.white.opacity(0.90),
                Color(red: 0.62, green: 0.72, blue: 1.00).opacity(0.70),
                Color(red: 0.88, green: 0.68, blue: 0.95).opacity(0.55),
                Color.white.opacity(0.60),
            ]
        } else if isLocked {
            return [
                Color.white.opacity(scheme == .dark ? 0.30 : 0.60),
                Color(red: 0.50, green: 0.58, blue: 0.92).opacity(0.45),
                Color.white.opacity(0.08),
            ]
        } else {
            return [
                Color.white.opacity(scheme == .dark ? 0.20 : 0.60),
                Color.white.opacity(0.02),
            ]
        }
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // ultraThinMaterial base
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Color tint overlay — makes card visibly tinted, NOT white
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(
                            colors: scheme == .dark ? [
                                Color(red: 0.20, green: 0.12, blue: 0.45).opacity(0.55),
                                Color(red: 0.12, green: 0.08, blue: 0.30).opacity(0.45),
                                Color.clear,
                            ] : [
                                Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.18),
                                Color(red: 0.60, green: 0.45, blue: 0.95).opacity(0.12),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    // Active: soft iridescent wash — same palette as the border, no neon
                    if isActive {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(LinearGradient(
                                colors: scheme == .dark ? [
                                    Color(red: 0.55, green: 0.50, blue: 0.90).opacity(0.12),
                                    Color(red: 0.70, green: 0.45, blue: 0.85).opacity(0.08),
                                    Color.clear,
                                ] : [
                                    Color(red: 0.68, green: 0.75, blue: 1.00).opacity(0.18),
                                    Color(red: 0.82, green: 0.68, blue: 0.98).opacity(0.10),
                                    Color.clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }

                    // Top shimmer — brighter when active to signal life
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(isActive
                                    ? (scheme == .dark ? 0.22 : 0.70)
                                    : (scheme == .dark ? 0.14 : 0.55)),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.50)
                        ))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Iridescent shimmer border — prismatic gradient, no neon color
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: shimmerStrokeColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isActive ? 1.5 : 1.0
                    )
            )
            // Depth shadow only — no colored glow bloom
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.40 : 0.10),
                radius: isActive ? 20 : 14,
                y: isActive ? 8 : 5
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

// MARK: - AddRuleButton
//
// Layered gradient circle: teal gradient fill + top shimmer + highlight ring + glow shadow.
// Never plain white with a green icon.

struct AddRuleButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)

                Circle()
                    .fill(LinearGradient(
                        colors: scheme == .dark
                            ? [Color.white.opacity(0.20), Color.clear]
                            : [Color.white.opacity(0.45), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.6)
                    ))
                    .frame(width: 36, height: 36)

                Circle()
                    .stroke(Color.white.opacity(scheme == .dark ? 0.22 : 0.50), lineWidth: 1)
                    .frame(width: 36, height: 36)

                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.90))
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header
//
// Glass pill label — ultraThinMaterial + blue tint overlay + soft shadow.
// Sits as a floating label, not a flat full-width bar.

struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(scheme == .dark
                ? Color.white.opacity(0.75)
                : Color(red: 0.18, green: 0.26, blue: 0.48)
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: scheme == .dark ? [
                                Color(red: 0.20, green: 0.12, blue: 0.45).opacity(0.50),
                                Color.clear,
                            ] : [
                                Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.18),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.45), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(scheme == .dark ? 0.30 : 0.08), radius: 8, y: 3)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
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
                colors: [
                    Color(red: 0.62, green: 0.55, blue: 0.98).opacity(0.28),
                    Color(red: 0.85, green: 0.60, blue: 0.90).opacity(0.10),
                    Color.clear,
                ],
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
            .background(
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
            )
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

// MARK: - Glass Form Row

struct GlassFormRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(GlassCard(cornerRadius: 14))
            .listRowSeparator(.hidden)
    }
}

extension View {
    func glassFormRow() -> some View { modifier(GlassFormRowModifier()) }
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
