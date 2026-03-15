import SwiftUI

struct GradientBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            if scheme == .light {
                LinearGradient(
                    colors: [
                        Color(red: 0.580, green: 0.780, blue: 0.980),
                        Color(red: 0.720, green: 0.640, blue: 0.980),
                        Color(red: 0.940, green: 0.740, blue: 0.920),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.220, green: 0.090, blue: 0.420),
                        Color(red: 0.110, green: 0.055, blue: 0.260),
                        Color(red: 0.060, green: 0.038, blue: 0.150),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    if scheme == .light {
                        Circle()
                            .fill(Color(red: 0.350, green: 0.680, blue: 1.000).opacity(0.38))
                            .frame(width: 460)
                            .offset(x: -w * 0.20, y: -h * 0.05)
                            .blur(radius: 120)

                        Circle()
                            .fill(Color(red: 0.580, green: 0.400, blue: 1.000).opacity(0.32))
                            .frame(width: 420)
                            .offset(x: w * 0.44, y: h * 0.26)
                            .blur(radius: 140)

                        Circle()
                            .fill(Color(red: 1.000, green: 0.420, blue: 0.700).opacity(0.28))
                            .frame(width: 400)
                            .offset(x: w * 0.02, y: h * 0.65)
                            .blur(radius: 130)
                    } else {
                        Circle()
                            .fill(Color(red: 0.650, green: 0.200, blue: 0.900).opacity(0.45))
                            .frame(width: 420)
                            .offset(x: w * 0.30, y: -h * 0.08)
                            .blur(radius: 110)

                        Circle()
                            .fill(Color(red: 0.220, green: 0.150, blue: 0.780).opacity(0.38))
                            .frame(width: 380)
                            .offset(x: -w * 0.10, y: h * 0.32)
                            .blur(radius: 140)

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

struct GlassCard: View {
    var cornerRadius: CGFloat = 24
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
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
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(scheme == .dark ? 0.12 : 0.50), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.45)
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(scheme == .dark ? 0.16 : 0.50), lineWidth: 1)
        }
    }
}

struct SGHeroCardSurface: View {
    var cornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(SGGradient.pastelHero)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.32), .clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.55)
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        }
    }
}

struct SGMascotFrame: View {
    var size: CGFloat = 80
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)

            Circle()
                .fill(
                    LinearGradient(
                        colors: scheme == .dark ? [
                            Color(red: 0.20, green: 0.12, blue: 0.45).opacity(0.60),
                            Color(red: 0.12, green: 0.08, blue: 0.30).opacity(0.40),
                        ] : [
                            Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.22),
                            Color(red: 0.60, green: 0.45, blue: 0.95).opacity(0.14),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .stroke(Color.white.opacity(0.40), lineWidth: 1)
                .frame(width: size, height: size)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
}

struct SGMascotGlow: View {
    var size: CGFloat = 200

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.62, green: 0.55, blue: 0.98).opacity(0.28),
                        Color(red: 0.85, green: 0.60, blue: 0.90).opacity(0.10),
                        Color.clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 20)
    }
}

struct SGCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var isActive: Bool = false
    var isLocked: Bool = false
    var cornerRadius: CGFloat = 24

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
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
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
                            )
                        )

                    if isActive {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
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
                                )
                            )
                    }

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(
                                        isActive ? (scheme == .dark ? 0.22 : 0.70) : (scheme == .dark ? 0.14 : 0.55)
                                    ),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.50)
                            )
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: shimmerStrokeColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isActive ? 1.5 : 1.0
                    )
            }
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

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content.padding().sgCard()
    }
}
