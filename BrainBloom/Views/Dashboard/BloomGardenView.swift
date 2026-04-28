import SwiftUI

struct BloomGardenView: View {
    /// 0 = fully withered, 1 = fully blooming
    let progress: Double

    @State private var animateBloom = false
    @State private var triggerWilt = false
    @State private var droppedPetals: Set<Int> = []

    private let maxPetals = 14

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    /// 0 = healthy flower, 1 = fully withered
    private var witherAmount: Double {
        1 - clampedProgress
    }

    private var petalsToDrop: Int {
        Int(round(Double(maxPetals) * witherAmount))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundGlow

            VStack(spacing: 0) {
                Spacer(minLength: 10)

                ZStack(alignment: .bottom) {
                    soilLayer
                    fallenPetalsLayer
                    flowerLayer
                }
                .frame(width: 260, height: 300)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: clampedProgress) { _ in
            startAnimations(reset: true)
        }
    }
}

// MARK: - Detox Recovery Flower
struct BloomRecoveryView: View {
    /// 0 = fully withered, 1 = fully blooming
    let progress: Double

    private let maxPetals = 14

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    // Fast start, slow finish so early recovery feels immediate.
    private var easedProgress: Double {
        1 - pow(1 - clampedProgress, 2.2)
    }

    /// 0 = healthy flower, 1 = fully withered
    private var witherAmount: Double {
        1 - clampedProgress
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            recoveryGlow

            VStack(spacing: 0) {
                Spacer(minLength: 10)

                ZStack(alignment: .bottom) {
                    soilLayer
                    flowerLayer
                }
                .frame(width: 260, height: 300)
            }
        }
    }
}

// MARK: - Detox Layers
private extension BloomRecoveryView {
    var recoveryGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.sgTeal.opacity(0.12 * clampedProgress + 0.03),
                        Color.sgTealDark.opacity(0.06 * clampedProgress + 0.02),
                        .clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 140
                )
            )
            .scaleEffect(clampedProgress > 0.9 ? 1.03 : 0.95)
            .animation(.easeInOut(duration: 1.6), value: clampedProgress)
    }

    var flowerLayer: some View {
        ZStack {
            stem

            ForEach(0..<maxPetals, id: \.self) { index in
                petalView(index: index)
            }

            flowerCenter
        }
        .rotationEffect(.degrees(clampedProgress > 0.9 ? 4 : 0))
        .animation(
            clampedProgress > 0.9
            ? .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
            : .easeOut(duration: 0.6),
            value: clampedProgress
        )
        .scaleEffect(clampedProgress > 0.98 ? 1.02 : 1.0)
        .animation(
            clampedProgress > 0.98
            ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
            : .easeOut(duration: 0.4),
            value: clampedProgress
        )
        .offset(y: -68)
    }

    var stem: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.green.opacity(max(0.25, 0.9 - witherAmount * 0.45)),
                        Color.mint.opacity(max(0.20, 0.72 - witherAmount * 0.42))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 12, height: 112)
            .scaleEffect(x: 1, y: 1 - witherAmount * 0.12, anchor: .bottom)
            .rotationEffect(.degrees((clampedProgress > 0.9 ? 2 : 0) - witherAmount * 8))
            .offset(y: 48)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            .animation(.easeOut(duration: 0.6), value: clampedProgress)
    }

    var flowerCenter: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.sgTeal.opacity(max(0.25, 0.9 - witherAmount * 0.45)),
                        Color.sgTealDark.opacity(max(0.18, 0.72 - witherAmount * 0.35))
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 22
                )
            )
            .frame(width: 36, height: 36)
            .scaleEffect(clampedProgress > 0.9 ? 1.06 : 1 - witherAmount * 0.08)
            .shadow(
                color: Color.sgTeal.opacity(clampedProgress > 0.9 ? 0.35 : 0.16),
                radius: clampedProgress > 0.9 ? 14 : 6,
                y: 2
            )
            .animation(
                clampedProgress > 0.9
                ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                : .easeOut(duration: 0.6),
                value: clampedProgress
            )
    }

    var soilLayer: some View {
        ZStack(alignment: .top) {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.31, green: 0.20, blue: 0.13),
                            Color(red: 0.18, green: 0.11, blue: 0.07)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 220, height: 44)

            Ellipse()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180, height: 10)
                .offset(y: 6)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 12, y: 7)
    }
}

// MARK: - Detox Petals
private extension BloomRecoveryView {
    func petalView(index: Int) -> some View {
        let angle = Double(index) / Double(maxPetals) * 360
        let petalProgress = petalRecovery(for: index)
        let wiltAmount = 1 - petalProgress
        let wiltOffset = wiltAmount * 10
        let wiltScale = max(0.84, 1 - wiltAmount * 0.18)
        let wiltRotation = witherRotation(for: index, amount: wiltAmount)
        let healthyPulse = clampedProgress > 0.9

        return RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(
                LinearGradient(
                    colors: petalColors(witherAmount: wiltAmount),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.white.opacity(0.18 * petalProgress), lineWidth: 0.8)
            )
            .frame(width: 22, height: 48)
            .scaleEffect(healthyPulse ? 1.03 : wiltScale)
            .offset(y: -28 + wiltOffset)
            .rotationEffect(.degrees(angle))
            .rotationEffect(.degrees(wiltRotation))
            .opacity(max(0.15, petalProgress))
            .shadow(
                color: Color.sgTeal.opacity(max(0.05, 0.22 - wiltAmount * 0.12)),
                radius: healthyPulse ? 8 : 4,
                y: 2
            )
            .animation(.easeInOut(duration: 0.6), value: petalProgress)
    }

    func petalRecovery(for index: Int) -> Double {
        let step = 1.0 / Double(maxPetals)
        let start = Double(index) * step
        let end = start + step
        let raw = (easedProgress - start) / (end - start)
        if index == 0 {
            return min(max(raw + 0.12, 0), 1)
        }
        return min(max(raw, 0), 1)
    }

    func petalColors(witherAmount: Double) -> [Color] {
        [
            Color.sgTeal.opacity(max(0.38, 0.96 - witherAmount * 0.50)),
            Color(red: 0.55, green: 0.65, blue: 1.0).opacity(max(0.30, 0.82 - witherAmount * 0.36)),
            Color(red: 0.88, green: 0.55, blue: 0.95).opacity(max(0.24, 0.82 - witherAmount * 0.48))
        ]
    }

    func witherRotation(for index: Int, amount: Double) -> Double {
        let sideBias = index.isMultiple(of: 2) ? -1.0 : 1.0
        return sideBias * amount * Double(8 + (index % 4) * 4)
    }
}

// MARK: - Layers
private extension BloomGardenView {
    var backgroundGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.sgTeal.opacity(0.14 * clampedProgress + 0.03),
                        Color.sgTealDark.opacity(0.08 * clampedProgress + 0.02),
                        .clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 140
                )
            )
            .scaleEffect(animateBloom && clampedProgress > 0.9 ? 1.05 : 0.95)
            .animation(
                clampedProgress > 0.9
                ? .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
                : .easeOut(duration: 0.4),
                value: animateBloom
            )
    }

    var flowerLayer: some View {
        ZStack {
            stem

            ForEach(0..<maxPetals, id: \.self) { index in
                petalView(index: index)
            }

            flowerCenter
        }
        .rotationEffect(.degrees(animateBloom && clampedProgress > 0.9 ? 6 : 0))
        .animation(
            clampedProgress > 0.9
            ? .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
            : .easeOut(duration: 0.45),
            value: animateBloom
        )
        .offset(y: -68)
    }

    var stem: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.green.opacity(max(0.25, 0.9 - witherAmount * 0.45)),
                        Color.mint.opacity(max(0.20, 0.72 - witherAmount * 0.42))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 12, height: 112)
            .scaleEffect(x: 1, y: 1 - witherAmount * 0.12, anchor: .bottom)
            .rotationEffect(.degrees((animateBloom && clampedProgress > 0.9 ? 2 : 0) - witherAmount * 8))
            .offset(y: 48)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }

    var flowerCenter: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.sgTeal.opacity(max(0.25, 0.9 - witherAmount * 0.45)),
                        Color.sgTealDark.opacity(max(0.18, 0.72 - witherAmount * 0.35))
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 22
                )
            )
            .frame(width: 36, height: 36)
            .scaleEffect(animateBloom && clampedProgress > 0.9 ? 1.06 : 1 - witherAmount * 0.08)
            .shadow(
                color: Color.sgTeal.opacity(clampedProgress > 0.9 ? 0.35 : 0.16),
                radius: clampedProgress > 0.9 ? 14 : 6,
                y: 2
            )
            .animation(
                clampedProgress > 0.9
                ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                : .easeOut(duration: 0.35),
                value: animateBloom
            )
    }

    var soilLayer: some View {
        ZStack(alignment: .top) {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.31, green: 0.20, blue: 0.13),
                            Color(red: 0.18, green: 0.11, blue: 0.07)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 220, height: 44)

            Ellipse()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180, height: 10)
                .offset(y: 6)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 12, y: 7)
    }

    var fallenPetalsLayer: some View {
        ZStack {
            ForEach(0..<maxPetals, id: \.self) { index in
                if droppedPetals.contains(index) {
                    fallenPetal(index: index)
                }
            }
        }
        .offset(y: -6)
    }
}

// MARK: - Petals
private extension BloomGardenView {
    func petalView(index: Int) -> some View {
        let angle = Double(index) / Double(maxPetals) * 360
        let hasDropped = droppedPetals.contains(index)
        let wiltOffset = witherAmount * 10
        let wiltScale = max(0.84, 1 - witherAmount * 0.18)
        let wiltRotation = witherRotation(for: index)
        let wiltOpacity = hasDropped ? 0 : max(0.2, 1 - witherAmount * 0.25)
        let healthyPulse = animateBloom && clampedProgress > 0.9

        return RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(
                LinearGradient(
                    colors: petalColors(forDropped: false),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            )
            .frame(width: 22, height: 48)
            .scaleEffect(healthyPulse ? 1.03 : wiltScale)
            .offset(y: hasDropped ? 0 : (-28 + wiltOffset))
            .rotationEffect(.degrees(angle))
            .rotationEffect(.degrees(hasDropped ? 0 : wiltRotation))
            .opacity(wiltOpacity)
            .shadow(
                color: Color.sgTeal.opacity(hasDropped ? 0 : max(0.08, 0.22 - witherAmount * 0.12)),
                radius: healthyPulse ? 8 : 4,
                y: 2
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.78), value: droppedPetals)
            .animation(
                healthyPulse
                ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
                : .easeOut(duration: 0.45),
                value: animateBloom
            )
    }

    func fallenPetal(index: Int) -> some View {
        let xPositions: [CGFloat] = [-74, -52, -28, -8, 16, 36, 58, 78, -62, -18, 8, 44, 68, -40]
        let yPositions: [CGFloat] = [0, 3, -1, 2, 0, 4, 1, 3, 5, 2, 6, 4, 2, 5]
        let rotations: [Double] = [-120, -80, -35, 14, 50, 92, 130, 168, -155, -12, 18, 78, 138, -62]

        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: petalColors(forDropped: true),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
            )
            .frame(width: 18, height: 36)
            .rotationEffect(.degrees(rotations[index % rotations.count]))
            .offset(
                x: xPositions[index % xPositions.count],
                y: yPositions[index % yPositions.count]
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
    }

    func petalColors(forDropped: Bool) -> [Color] {
        if forDropped {
            return [
                Color(red: 0.50, green: 0.57, blue: 0.73).opacity(0.72),
                Color(red: 0.56, green: 0.50, blue: 0.67).opacity(0.58),
                Color(red: 0.46, green: 0.43, blue: 0.50).opacity(0.42)
            ]
        }

        return [
            Color.sgTeal.opacity(max(0.38, 0.96 - witherAmount * 0.50)),
            Color(red: 0.55, green: 0.65, blue: 1.0).opacity(max(0.30, 0.82 - witherAmount * 0.36)),
            Color(red: 0.88, green: 0.55, blue: 0.95).opacity(max(0.24, 0.82 - witherAmount * 0.48))
        ]
    }

    func witherRotation(for index: Int) -> Double {
        let sideBias = index.isMultiple(of: 2) ? -1.0 : 1.0
        return sideBias * witherAmount * Double(8 + (index % 4) * 4)
    }
}

// MARK: - Animation
private extension BloomGardenView {
    func startAnimations(reset: Bool = false) {
        if reset {
            animateBloom = false
            triggerWilt = false
            droppedPetals.removeAll()
        }

        if clampedProgress > 0.9 {
            animateBloom = true
            triggerWilt = false
            droppedPetals.removeAll()
            return
        }

        animateBloom = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            triggerWilt = true
            dropPetalsOneByOne()
        }
    }

    func dropPetalsOneByOne() {
        droppedPetals.removeAll()

        guard petalsToDrop > 0 else { return }

        for step in 0..<petalsToDrop {
            let delay = 0.22 * Double(step)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let index = petalDropOrder[step % petalDropOrder.count]
                _ = withAnimation(.spring(response: 0.72, dampingFraction: 0.82)) {
                    droppedPetals.insert(index)
                }
            }
        }
    }

    var petalDropOrder: [Int] {
        [13, 2, 10, 5, 0, 8, 3, 12, 6, 1, 9, 4, 11, 7]
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.05, green: 0.08, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 28) {
            BloomGardenView(progress: 1.0)
            BloomGardenView(progress: 0.55)
            BloomGardenView(progress: 0.1)
        }
        .padding()
    }
}
