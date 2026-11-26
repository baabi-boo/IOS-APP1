import SwiftUI

private func fract(_ value: Double) -> Double {
    value - floor(value)
}

/// A cheap deterministic pseudo-random number in 0..<1.
private func noise(_ seed: Double, _ salt: Double) -> Double {
    fract(sin(seed * 12.9898 + salt * 78.233) * 43758.5453)
}

// MARK: - Confetti

private struct ConfettiPiece {
    let angle: Double
    let speed: Double
    let spin: Double
    let drift: Double
    let color: Color
    let shade: Color
    let size: CGFloat
    /// The piece's outline, centered on the origin so it can be rotated in place.
    let path: Path

    init(seed: Int) {
        func random(_ salt: Double) -> Double {
            noise(Double(seed), salt)
        }
        angle = -Double.pi * (0.08 + 0.84 * random(1))
        speed = 420 + 560 * random(2)
        spin = (random(3) - 0.5) * 12
        drift = (random(5) - 0.5) * 60
        let s = CGFloat(10 + 9 * random(4))
        size = s
        color = Palette.confetti[seed % Palette.confetti.count]
        shade = color.blended(with: Color(hex: 0x6B3F5A), by: 0.22)
        switch seed % 5 {
        case 0:
            path = Path(roundedRect: CGRect(x: -s / 2, y: -s * 0.32, width: s, height: s * 0.64), cornerRadius: s * 0.3)
        case 1:
            path = Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s))
        case 2:
            path = HeartShape().path(in: CGRect(x: -s * 0.6, y: -s * 0.6, width: s * 1.2, height: s * 1.1))
        case 3:
            path = DewyShape().path(in: CGRect(x: -s * 0.5, y: -s * 0.65, width: s, height: s * 1.3))
        default:
            path = SparkleShape().path(in: CGRect(x: -s * 0.75, y: -s * 0.75, width: s * 1.5, height: s * 1.5))
        }
    }
}

/// A joyful burst of clay confetti: chunky hearts, droplets, sparkles and pills, each with
/// a little shadow side and a highlight so they read as tiny toys. Fires whenever `trigger` changes.
struct ConfettiView: View {
    var trigger: Int
    var origin: UnitPoint = UnitPoint(x: 0.5, y: 0.32)

    @State private var start: Date?
    private let pieces = (0..<70).map(ConfettiPiece.init(seed:))
    private let duration: Double = 3.2

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                draw(in: &context, size: size, time: timeline.date.timeIntervalSince(start))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            start = .now
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                start = nil
            }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        guard t >= 0, t < duration else { return }
        let gravity: Double = 980
        let ox = Double(size.width) * Double(origin.x)
        let oy = Double(size.height) * Double(origin.y)
        context.opacity = max(0, min(1, (duration - t) / 0.8))
        for piece in pieces {
            let vx = cos(piece.angle) * piece.speed * 0.75
            let vy = sin(piece.angle) * piece.speed
            // Air drag makes the pieces float down instead of dropping like stones.
            let drag = 1 - min(t * 0.25, 0.6)
            let px = ox + vx * t * 0.9 * drag + piece.drift * sin(t * 3)
            let py = oy + vy * t * drag + 0.5 * gravity * t * t * 0.7
            let transform = CGAffineTransform(translationX: CGFloat(px), y: CGFloat(py)).rotated(by: CGFloat(piece.spin * t))
            let shaped = piece.path.applying(transform)
            context.fill(shaped.applying(CGAffineTransform(translationX: 0, y: 1.5)), with: .color(piece.shade))
            context.fill(shaped, with: .color(piece.color))
            let r = piece.size * 0.14
            let glint = Path(ellipseIn: CGRect(x: -piece.size * 0.22 - r, y: -piece.size * 0.18 - r, width: r * 2, height: r * 1.6)).applying(transform)
            context.fill(glint, with: .color(.white.opacity(0.8)))
        }
    }
}

// MARK: - Bubbles

/// Soap-bubble spheres that rise and wobble, used behind celebrations.
struct BubbleField: View {
    var count = 14
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated || reduceMotion)) { timeline in
            let t = animated && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : 10
            Canvas { context, size in
                for index in 0..<count {
                    let seed = Double(index)
                    let r = CGFloat(8 + noise(seed, 1) * 22)
                    let speed = 18 + noise(seed, 2) * 30
                    let span = Double(size.height + r * 4)
                    let y = size.height + r * 2 - CGFloat((t * speed + noise(seed, 3) * span).truncatingRemainder(dividingBy: span))
                    let x = CGFloat(noise(seed, 4)) * size.width + CGFloat(sin(t * 1.2 + seed)) * 10
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.05), Palette.aquaLight.opacity(0.25), .white.opacity(0.6)]),
                        center: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endRadius: r
                    ))
                    context.fill(Path(ellipseIn: CGRect(x: x - r * 0.55, y: y - r * 0.6, width: r * 0.45, height: r * 0.32)), with: .color(.white.opacity(0.85)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Rolling number

/// A number that counts up digit by digit, with a tiny tick for each step.
struct RollingNumber: View {
    var value: Int
    var font: Font = .display(34, .bold)
    var color: Color = Ink.primary
    /// Start counting after this delay.
    var delay: Double = 0.4

    @State private var shown = 0

    var body: some View {
        Text("+\(shown)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(shown)))
            .monospacedDigit()
            .task(id: value) {
                await roll()
            }
    }

    @MainActor
    private func roll() async {
        shown = 0
        guard value > 0 else { return }
        try? await Task.sleep(for: .seconds(delay))
        let steps = min(value, 18)
        for step in 1...steps {
            try? await Task.sleep(for: .milliseconds(55))
            let next = Int((Double(value) * Double(step) / Double(steps)).rounded())
            withAnimation(.snappy(duration: 0.12)) {
                shown = next
            }
            if step.isMultiple(of: 2) { Haptics.tick() }
        }
    }
}
