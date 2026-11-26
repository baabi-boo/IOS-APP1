import SwiftUI

private func fract(_ value: Double) -> Double {
    value - floor(value)
}

/// A cheap deterministic pseudo-random number in 0..<1.
private func noise(_ seed: Double, _ salt: Double) -> Double {
    fract(sin(seed * 12.9898 + salt * 78.233) * 43758.5453)
}

// MARK: - Hero backdrop

/// The bold color field behind hero areas: a saturated gradient with slowly rising
/// bubbles, twinkles and (optionally) a turning sunburst.
struct HeroBackdrop: View {
    @Environment(\.dewyTheme) private var theme
    var top: Color?
    var bottom: Color?
    var rays = false
    var rayCenter = UnitPoint(x: 0.5, y: 0.3)
    var bubbles = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [top ?? theme.hero, bottom ?? theme.heroDeep], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    if rays {
                        HeroBackdrop.drawRays(context, size: size, center: rayCenter, time: t)
                    }
                    if bubbles {
                        HeroBackdrop.drawBubbles(context, size: size, time: t)
                    }
                    HeroBackdrop.drawTwinkles(context, size: size, time: t)
                }
            }
        }
        .ignoresSafeArea()
    }

    static func drawRays(_ context: GraphicsContext, size: CGSize, center unit: UnitPoint, time t: Double) {
        let center = CGPoint(x: size.width * unit.x, y: size.height * unit.y)
        let radius = max(size.width, size.height) * 1.3
        let count = 14
        let spin = t * 0.06
        for index in 0..<count {
            let a0 = spin + Double(index) * 2 * .pi / Double(count)
            let a1 = a0 + .pi / Double(count)
            var wedge = Path()
            wedge.move(to: center)
            wedge.addLine(to: CGPoint(x: center.x + radius * CGFloat(cos(a0)), y: center.y + radius * CGFloat(sin(a0))))
            wedge.addLine(to: CGPoint(x: center.x + radius * CGFloat(cos(a1)), y: center.y + radius * CGFloat(sin(a1))))
            wedge.closeSubpath()
            context.fill(wedge, with: .color(.white.opacity(0.07)))
        }
    }

    static func drawBubbles(_ context: GraphicsContext, size: CGSize, time t: Double) {
        let span = Double(size.height) + 60
        for index in 0..<12 {
            let seed = Double(index)
            let radius = CGFloat(3 + 11 * noise(seed, 1))
            let speed = 12 + 22 * noise(seed, 2)
            let travel = (t * speed + seed * 137).truncatingRemainder(dividingBy: span)
            let y = size.height + 30 - CGFloat(travel)
            let x = size.width * CGFloat(noise(seed, 3)) + CGFloat(sin(t * 0.7 + seed)) * 12
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.07)))
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.2)), lineWidth: 1.5)
        }
    }

    static func drawTwinkles(_ context: GraphicsContext, size: CGSize, time t: Double) {
        // Kept near the edges, clear of headlines and numbers.
        let spots: [(Double, Double, Double)] = [
            (0.05, 0.36, 14), (0.94, 0.25, 12), (0.96, 0.56, 10), (0.07, 0.8, 12)
        ]
        for (index, spot) in spots.enumerated() {
            let pulse = 0.5 + 0.5 * sin(t * 1.6 + Double(index) * 1.3)
            let side = CGFloat(spot.2 * (0.6 + 0.4 * pulse))
            let rect = CGRect(
                x: size.width * CGFloat(spot.0) - side / 2,
                y: size.height * CGFloat(spot.1) - side / 2,
                width: side,
                height: side
            )
            context.fill(SparkleShape().path(in: rect), with: .color(.white.opacity(0.25 + 0.5 * pulse)))
        }
    }
}

// MARK: - Halo

/// Soft discs and expanding ripples behind Dewy, like rings on a pond.
struct HaloRings: View {
    var diameter: CGFloat
    var color: Color = .white

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.1)
            ZStack {
                Circle()
                    .fill(color.opacity(0.07))
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(breathe)
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: diameter * 0.76, height: diameter * 0.76)
                    .scaleEffect(2 - breathe)
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: diameter * 0.52, height: diameter * 0.52)
                ForEach(0..<3, id: \.self) { index in
                    let phase = fract(t / 4.5 + Double(index) / 3)
                    Circle()
                        .stroke(color.opacity(0.35 * (1 - phase)), lineWidth: 2)
                        .frame(width: diameter * 0.5, height: diameter * 0.5)
                        .scaleEffect(1 + phase * 1.15)
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .allowsHitTesting(false)
    }
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
            path = DropletShape().path(in: CGRect(x: -s * 0.5, y: -s * 0.65, width: s, height: s * 1.3))
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

/// A little five-petal flower that sways in the breeze.
struct FlowerView: View {
    var color: Color
    var size: CGFloat
    var sway: Double = 0

    var body: some View {
        ZStack {
            // Stem and leaf
            Capsule()
                .fill(Palette.leafDeep)
                .frame(width: size * 0.09, height: size * 0.5)
                .offset(y: size * 0.27)
            Ellipse()
                .fill(Palette.leaf)
                .frame(width: size * 0.28, height: size * 0.14)
                .rotationEffect(.degrees(-30))
                .offset(x: size * 0.14, y: size * 0.33)

            // Bloom
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Ellipse()
                        .fill(color)
                        .frame(width: size * 0.32, height: size * 0.44)
                        .offset(y: -size * 0.17)
                        .rotationEffect(.degrees(Double(index) * 72))
                }
                Circle()
                    .fill(Palette.sunshine)
                    .frame(width: size * 0.27, height: size * 0.27)
                    .overlay(Circle().strokeBorder(Color(hex: 0xFF9F1C), lineWidth: size * 0.03))
                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(x: -size * 0.04, y: -size * 0.04)
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
                .frame(width: size * 0.3, height: size * 0.16)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.13, y: size * 0.1)
            Ellipse()
                .fill(Palette.mint)
                .frame(width: size * 0.3, height: size * 0.16)
                .rotationEffect(.degrees(28))
                .offset(x: size * 0.13, y: size * 0.06)
        }
        .frame(width: size, height: size * 1.2)
        .rotationEffect(.degrees(sway), anchor: .bottom)
    }
}

/// A puffy flat cloud.
struct CloudView: View {
    var width: CGFloat
    var color: Color = .white

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(color)
                .frame(width: width, height: width * 0.3)
            Circle()
                .fill(color)
                .frame(width: width * 0.42, height: width * 0.42)
                .offset(x: -width * 0.16, y: -width * 0.1)
            Circle()
                .fill(color)
                .frame(width: width * 0.5, height: width * 0.5)
                .offset(x: width * 0.12, y: -width * 0.14)
        }
        .frame(width: width, height: width * 0.62, alignment: .bottom)
    }
}

/// The Dew Garden: rolling hills under a theme-colored sky, with a flower
/// for every day you reached your goal.
struct GardenLandscape: View {
    @Environment(\.dewyTheme) private var theme
    var flowers: Int

    static let petals: [Color] = [
        Color(hex: 0xFF5C93), Color(hex: 0x8C6BFF), Color(hex: 0xFF8A3D),
        Color(hex: 0x2FB4FF), Color(hex: 0xFF4F6D), Color(hex: 0xFFC83D)
    ]

    private let far = HillShape(left: 0.56, peakX: 0.24, peakY: 0.44, right: 0.62)
    private let mid = HillShape(left: 0.74, peakX: 0.74, peakY: 0.54, right: 0.62)
    private let near = HillShape(left: 0.78, peakX: 0.3, peakY: 0.7, right: 0.84)

    /// Flower spots as (hill, x, size): 0 = middle hill, 1 = near hill.
    private let spots: [(Int, CGFloat, CGFloat)] = [
        (0, 0.52, 26), (0, 0.62, 30), (0, 0.72, 32), (0, 0.82, 28), (0, 0.92, 26), (0, 0.44, 24),
        (1, 0.08, 40), (1, 0.18, 46), (1, 0.29, 50), (1, 0.4, 44), (1, 0.5, 40), (1, 0.61, 38),
        (1, 0.72, 42), (1, 0.84, 46), (1, 0.95, 40)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack(alignment: .topLeading) {
                    LinearGradient(colors: theme.sky, startPoint: .top, endPoint: .bottom)

                    if theme.isDark {
                        stars(width: w, height: h, time: t)
                    }

                    celestial(time: t)
                        .position(x: w * 0.8, y: h * 0.27)

                    // Clouds drift below the title area so they never hide white text.
                    CloudView(width: 92, color: Color.white.opacity(theme.isDark ? 0.14 : 0.92))
                        .position(x: wrap(w * 0.2 + CGFloat(t * 6), width: w), y: h * 0.38)
                    CloudView(width: 64, color: Color.white.opacity(theme.isDark ? 0.1 : 0.75))
                        .position(x: wrap(w * 0.62 + CGFloat(t * 4), width: w), y: h * 0.47)

                    far.fill(theme.isDark ? Color(hex: 0x1F4A63) : Color(hex: 0x9BE3A6))
                    mid.fill(theme.isDark ? Color(hex: 0x1C6550) : Color(hex: 0x5ECB7B))

                    ForEach(0..<spots.count, id: \.self) { index in
                        if spots[index].0 == 0 {
                            plant(index: index, width: w, height: h, time: t)
                        }
                    }

                    near.fill(theme.isDark ? Color(hex: 0x15523F) : Color(hex: 0x3BB565))

                    ForEach(0..<spots.count, id: \.self) { index in
                        if spots[index].0 == 1 {
                            plant(index: index, width: w, height: h, time: t)
                        }
                    }
                }
            }
        }
        .clipped()
    }

    private func wrap(_ x: CGFloat, width: CGFloat) -> CGFloat {
        let span = width + 140
        let value = (x + 70).truncatingRemainder(dividingBy: span)
        return value - 70
    }

    @ViewBuilder
    private func plant(index: Int, width w: CGFloat, height h: CGFloat, time t: Double) -> some View {
        let spot = spots[index]
        let hill = spot.0 == 0 ? mid : near
        let x = w * spot.1
        let y = h * hill.surface(spot.1)
        let sway = sin(t * 1.5 + Double(index) * 0.9) * 6
        // Fill the near hill first so even a small garden looks lush up front.
        let order = spot.0 == 1 ? index - 6 : index + 9
        if order < flowers {
            FlowerView(color: Self.petals[index % Self.petals.count], size: spot.2, sway: sway)
                .position(x: x, y: y - spot.2 * 0.5)
        } else {
            SproutView(size: spot.2 * 0.55, sway: sway * 0.6)
                .position(x: x, y: y - spot.2 * 0.26)
        }
    }

    @ViewBuilder
    private func celestial(time t: Double) -> some View {
        if theme.isDark {
            Image(systemName: "moon.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(Color(hex: 0xFFE7A0))
                .shadow(color: Color(hex: 0xFFE7A0).opacity(0.6), radius: 18)
                .rotationEffect(.degrees(-20))
        } else {
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Capsule()
                        .fill(Palette.sunshine.opacity(0.85))
                        .frame(width: 6, height: 14)
                        .offset(y: -44)
                        .rotationEffect(.degrees(Double(index) * 36 + t * 8))
                }
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 74, height: 74)
                Circle()
                    .fill(Palette.sunshine)
                    .frame(width: 58, height: 58)
            }
        }
    }

    private func stars(width w: CGFloat, height h: CGFloat, time t: Double) -> some View {
        Canvas { context, size in
            for index in 0..<22 {
                let seed = Double(index)
                let x = size.width * CGFloat(noise(seed, 7))
                let y = size.height * CGFloat(noise(seed, 8)) * 0.55
                let pulse = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 + seed))
                let side = CGFloat(4 + 6 * noise(seed, 9))
                let rect = CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side)
                context.fill(SparkleShape().path(in: rect), with: .color(.white.opacity(pulse)))
            }
        }
        .frame(width: w, height: h)
    }
}

// MARK: - Shimmer

/// A soft moving highlight, great on premium labels.
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.5)
                    .offset(x: proxy.size.width * phase)
                    .blendMode(.plusLighter)
                }
                .mask(content)
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(0.6)) {
                    phase = 1.6
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}
