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
    let isDroplet: Bool
    let color: Color
    /// The piece's outline, centered on the origin so it can be rotated in place.
    let path: Path

    init(seed: Int) {
        func random(_ salt: Double) -> Double {
            noise(Double(seed), salt)
        }
        angle = -Double.pi * (0.1 + 0.8 * random(1))
        speed = 420 + 520 * random(2)
        spin = (random(3) - 0.5) * 14
        drift = (random(5) - 0.5) * 60
        let s = CGFloat(8 + 8 * random(4))
        let kind = seed % 5
        isDroplet = kind == 3
        color = Palette.confetti[seed % Palette.confetti.count]
        switch kind {
        case 0:
            path = Path(roundedRect: CGRect(x: -s / 2, y: -s * 0.3, width: s, height: s * 0.6), cornerRadius: 2)
        case 1:
            path = Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s))
        case 2:
            path = HeartShape().path(in: CGRect(x: -s * 0.6, y: -s * 0.6, width: s * 1.2, height: s * 1.1))
        case 3:
            path = DewyShape().path(in: CGRect(x: -s * 0.5, y: -s * 0.65, width: s, height: s * 1.3))
        default:
            path = SparkleShape().path(in: CGRect(x: -s * 0.7, y: -s * 0.7, width: s * 1.4, height: s * 1.4))
        }
    }
}

/// A joyful burst of confetti, hearts and droplets. Fires whenever `trigger` changes.
struct ConfettiView: View {
    var trigger: Int
    var origin: UnitPoint = UnitPoint(x: 0.5, y: 0.32)

    @Environment(\.dewyTheme) private var theme
    @State private var start: Date?
    private let pieces = (0..<80).map(ConfettiPiece.init(seed:))
    private let duration: Double = 3.2

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                guard t >= 0, t < duration else { return }
                let gravity = 980.0
                let ox = Double(size.width) * Double(origin.x)
                let oy = Double(size.height) * Double(origin.y)
                // Every piece fades together, so set opacity once and draw plain
                // transformed paths (no per-piece layers — much cheaper to render).
                context.opacity = max(0, min(1, (duration - t) / 0.8))
                for piece in pieces {
                    let vx = cos(piece.angle) * piece.speed * 0.75
                    let vy = sin(piece.angle) * piece.speed
                    let x = CGFloat(ox + vx * t * 0.9 + piece.drift * sin(t * 3))
                    let y = CGFloat(oy + vy * t + 0.5 * gravity * t * t)
                    let transform = CGAffineTransform(translationX: x, y: y).rotated(by: CGFloat(piece.spin * t))
                    context.fill(piece.path.applying(transform), with: .color(piece.isDroplet ? theme.water : piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            start = .now
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                start = nil
            }
        }
    }
}

// MARK: - Garden flora

/// A five-petal flower in the house style: two-tone petals, a glossy center, a leafy stem.
struct FlowerView: View {
    var color: Color
    var size: CGFloat
    var sway: Double = 0

    var body: some View {
        ZStack {
            // Stem and leaves
            Capsule()
                .fill(Palette.leafDeep)
                .frame(width: size * 0.09, height: size * 0.52)
                .offset(y: size * 0.27)
            Ellipse()
                .fill(Palette.leaf)
                .frame(width: size * 0.3, height: size * 0.15)
                .rotationEffect(.degrees(-30))
                .offset(x: size * 0.15, y: size * 0.34)
            Ellipse()
                .fill(Color(hex: 0x7ED46F))
                .frame(width: size * 0.24, height: size * 0.12)
                .rotationEffect(.degrees(28))
                .offset(x: -size * 0.12, y: size * 0.42)

            // Bloom
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Ellipse()
                        .fill(color)
                        .frame(width: size * 0.34, height: size * 0.46)
                        .overlay(alignment: .top) {
                            Ellipse()
                                .fill(Color.white.opacity(0.28))
                                .frame(width: size * 0.16, height: size * 0.2)
                                .padding(.top, size * 0.04)
                        }
                        .offset(y: -size * 0.17)
                        .rotationEffect(.degrees(Double(index) * 72))
                }
                Circle()
                    .fill(Palette.sunshine)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(Circle().strokeBorder(Color(hex: 0xFFA41F), lineWidth: size * 0.03))
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: -size * 0.045, y: -size * 0.045)
            }
            .offset(y: -size * 0.08)
        }
        .frame(width: size, height: size * 1.2)
        .rotationEffect(.degrees(sway), anchor: .bottom)
    }
}

/// A freshly sprouted seedling.
struct SproutView: View {
    var size: CGFloat
    var sway: Double = 0

    var body: some View {
        ZStack {
            Capsule()
                .fill(Palette.leafDeep)
                .frame(width: size * 0.08, height: size * 0.36)
                .offset(y: size * 0.32)
            Ellipse()
                .fill(Palette.leaf)
                .frame(width: size * 0.32, height: size * 0.17)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.13, y: size * 0.1)
            Ellipse()
                .fill(Color(hex: 0x8EDB6E))
                .frame(width: size * 0.32, height: size * 0.17)
                .rotationEffect(.degrees(28))
                .offset(x: size * 0.13, y: size * 0.06)
        }
        .frame(width: size, height: size * 1.2)
        .rotationEffect(.degrees(sway), anchor: .bottom)
    }
}
