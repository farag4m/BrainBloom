import SwiftUI
import Combine

@MainActor
final class OrbFieldModel: ObservableObject {
    struct Particle: Identifiable {
        let id: UUID
        var position: CGPoint
        var velocity: CGVector
        var scale: CGFloat
        var opacity: Double
    }

    @Published var particles: [Particle] = []
    @Published var mergingProgress: CGFloat = 0

    private var size: CGSize = .zero
    private var mergeCooldownUntil: Date = .distantPast
    private var isRunning = false
    private var isMerging = false
    private var isSplitting = false
    private var splitCooldownUntil: Date = .distantPast

    func updateSize(_ newSize: CGSize) {
        size = newSize
        if particles.isEmpty {
            let start = CGPoint(x: size.width * 0.35, y: size.height * 0.35)
            particles = [makeParticle(at: start, scale: 1.0, speed: 38)]
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        Task { await runLoop() }
    }

    private func runLoop() async {
        let frameDuration = 1.0 / 60.0
        while !Task.isCancelled {
            step(dt: frameDuration)
            try? await Task.sleep(nanoseconds: UInt64(frameDuration * 1_000_000_000))
        }
    }

    private func step(dt: Double) {
        guard size.width > 0, size.height > 0 else { return }

        for index in particles.indices {
            particles[index].position.x += particles[index].velocity.dx * dt
            particles[index].position.y += particles[index].velocity.dy * dt
        }

        constrainBoundsAndSplitIfNeeded()
        if !isMerging {
            resolveCollisions()
        }
    }

    private func constrainBoundsAndSplitIfNeeded() {
        let minSpeed: CGFloat = 24
        for index in particles.indices {
            let radius = 180 * particles[index].scale
            let minX = radius + 16
            let maxX = max(minX, size.width - radius - 16)
            let minY = radius + 24
            let maxY = max(minY, size.height - radius - 24)

            var pos = particles[index].position
            var vel = particles[index].velocity

            let hitLeft = pos.x < minX
            let hitRight = pos.x > maxX
            let hitTop = pos.y < minY
            let hitBottom = pos.y > maxY

            if hitLeft { pos.x = minX; vel.dx = abs(vel.dx) }
            if hitRight { pos.x = maxX; vel.dx = -abs(vel.dx) }
            if hitTop { pos.y = minY; vel.dy = abs(vel.dy) }
            if hitBottom { pos.y = maxY; vel.dy = -abs(vel.dy) }

            if abs(vel.dx) < minSpeed { vel.dx = vel.dx >= 0 ? minSpeed : -minSpeed }
            if abs(vel.dy) < minSpeed { vel.dy = vel.dy >= 0 ? minSpeed : -minSpeed }

            particles[index].position = pos
            particles[index].velocity = vel

            if (hitLeft || hitRight || hitTop || hitBottom),
               particles[index].scale >= 0.52,
               Date() >= splitCooldownUntil,
               !isMerging,
               !isSplitting {
                Task { await splitParticle(at: index) }
            }
        }
    }

    private func resolveCollisions() {
        guard particles.count > 1 else { return }
        let now = Date()
        var didCollide = false

        for i in 0..<particles.count {
            for j in (i + 1)..<particles.count {
                let a = particles[i]
                let b = particles[j]
                let minDist = (180 * a.scale) + (180 * b.scale) + 24
                let delta = CGVector(dx: b.position.x - a.position.x, dy: b.position.y - a.position.y)
                let dist = hypot(delta.dx, delta.dy)
                if dist < minDist {
                    didCollide = true
                    let separation = (minDist - dist) / 2
                    let norm = normalize(delta)
                    particles[i].position.x -= norm.dx * separation
                    particles[i].position.y -= norm.dy * separation
                    particles[j].position.x += norm.dx * separation
                    particles[j].position.y += norm.dy * separation
                    // Push away so they don't overlap
                    particles[i].velocity = randomVelocity(speed: 44)
                    particles[j].velocity = randomVelocity(speed: 44)
                }
            }
        }

        if didCollide, !isSplitting, now >= mergeCooldownUntil {
            Task { await beginMerge() }
        }
    }

    private func splitParticle(at index: Int) async {
        guard !isMerging, !isSplitting, particles.indices.contains(index) else { return }
        isSplitting = true
        mergeCooldownUntil = Date().addingTimeInterval(30)
        let particle = particles[index]
        let newScale = max(0.42, particle.scale * 0.5)
        guard newScale >= 0.42 else { return }
        let v1 = randomVelocity(speed: 54)
        let v2 = CGVector(dx: -v1.dx, dy: -v1.dy)
        let offset = CGVector(dx: v1.dx * 0.6, dy: v1.dy * 0.6)
        let p1 = Particle(
            id: UUID(),
            position: CGPoint(x: particle.position.x + offset.dx, y: particle.position.y + offset.dy),
            velocity: v1,
            scale: 0.05,
            opacity: 0.0
        )
        let p2 = Particle(
            id: UUID(),
            position: CGPoint(x: particle.position.x - offset.dx, y: particle.position.y - offset.dy),
            velocity: v2,
            scale: 0.05,
            opacity: 0.0
        )

        particles[index].opacity = 0.0
        particles[index].scale = 0.05
        particles.append(contentsOf: [p1, p2])

        withAnimation(.easeInOut(duration: 1.0)) {
            if let i1 = particles.firstIndex(where: { $0.id == p1.id }) {
                particles[i1].scale = newScale
                particles[i1].opacity = 0.55
            }
            if let i2 = particles.firstIndex(where: { $0.id == p2.id }) {
                particles[i2].scale = newScale
                particles[i2].opacity = 0.55
            }
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        particles.removeAll { $0.id == particle.id }
        splitCooldownUntil = Date().addingTimeInterval(4)
        isSplitting = false
    }

    private func mergeAll() {
        guard particles.count > 1 else { return }
        let center = particles.reduce(CGPoint.zero) { acc, p in
            CGPoint(x: acc.x + p.position.x, y: acc.y + p.position.y)
        }
        let avg = CGPoint(x: center.x / CGFloat(particles.count), y: center.y / CGFloat(particles.count))
        let vel = particles.reduce(CGVector.zero) { acc, p in
            CGVector(dx: acc.dx + p.velocity.dx, dy: acc.dy + p.velocity.dy)
        }
        let avgVel = CGVector(dx: vel.dx / CGFloat(particles.count), dy: vel.dy / CGFloat(particles.count))
        let clamped = clampPosition(avg, scale: 0.85)
        particles = [Particle(id: UUID(), position: clamped, velocity: avgVel, scale: 0.85, opacity: 0.55)]
        splitCooldownUntil = Date().addingTimeInterval(30)
    }

    private func beginMerge() async {
        guard !isMerging, particles.count > 1 else { return }
        isMerging = true
        let mergeDuration: Double = 1.4

        let center = particles.reduce(CGPoint.zero) { acc, p in
            CGPoint(x: acc.x + p.position.x, y: acc.y + p.position.y)
        }
        let avg = CGPoint(x: center.x / CGFloat(particles.count), y: center.y / CGFloat(particles.count))

        withAnimation(.easeInOut(duration: mergeDuration)) {
            mergingProgress = 1
            for index in particles.indices {
                particles[index].position = avg
                particles[index].scale = min(0.85, particles[index].scale + 0.20)
                particles[index].opacity = 0.0
            }
        }
        try? await Task.sleep(nanoseconds: UInt64(mergeDuration * 1_000_000_000))

        mergeAll()
        mergingProgress = 0
        isMerging = false
    }

    private func clampPosition(_ position: CGPoint, scale: CGFloat) -> CGPoint {
        let radius = 180 * scale
        let minX = radius + 16
        let maxX = max(minX, size.width - radius - 16)
        let minY = radius + 24
        let maxY = max(minY, size.height - radius - 24)
        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }

    private func makeParticle(at position: CGPoint, scale: CGFloat, speed: CGFloat) -> Particle {
        Particle(
            id: UUID(),
            position: position,
            velocity: randomVelocity(speed: speed),
            scale: scale,
            opacity: 0.55
        )
    }

    private func randomVelocity(speed: CGFloat) -> CGVector {
        let angle = Double.random(in: 0...(Double.pi * 2))
        return CGVector(dx: CGFloat(cos(angle)) * speed, dy: CGFloat(sin(angle)) * speed)
    }

    private func normalize(_ vector: CGVector) -> CGVector {
        let length = max(0.001, hypot(vector.dx, vector.dy))
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }
}

struct FloatingOrbField: View {
    @StateObject private var model = OrbFieldModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(model.particles) { particle in
                    FloatingGlassOrb(position: particle.position, scale: particle.scale)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                model.updateSize(geo.size)
                model.start()
            }
            .onChange(of: geo.size) { newSize in
                model.updateSize(newSize)
            }
        }
        .allowsHitTesting(false)
    }
}

struct FloatingGlassOrb: View {
    @Environment(\.colorScheme) private var scheme
    let position: CGPoint
    let scale: CGFloat

    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(glassTint)
            .overlay(glassHighlight)
            .overlay(glassRim)
            .frame(width: 360, height: 360)
            .blur(radius: 1.5)
            .position(position)
            .scaleEffect(scale)
            .opacity(scheme == .light ? 0.55 : 0.45)
            .allowsHitTesting(false)
    }

    private var glassTint: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: scheme == .light ? [
                        Color(red: 0.78, green: 0.72, blue: 0.98).opacity(0.18),
                        Color(red: 0.70, green: 0.64, blue: 0.95).opacity(0.12),
                        Color.clear
                    ] : [
                        Color(red: 0.62, green: 0.46, blue: 0.90).opacity(0.22),
                        Color(red: 0.48, green: 0.32, blue: 0.78).opacity(0.16),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var glassHighlight: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(scheme == .light ? 0.26 : 0.16),
                        Color.white.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.screen)
    }

    private var glassRim: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(scheme == .light ? 0.18 : 0.12),
                        Color.white.opacity(0.02),
                        Color.white.opacity(scheme == .light ? 0.10 : 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
