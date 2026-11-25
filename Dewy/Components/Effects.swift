import SwiftUI

// MARK: - Dreamy animated background

/// Pastel gradient with soft glowing blobs that drift slowly.
struct DreamyBackground: View {
    @Environment(\.dewyTheme) private var theme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                let x1 = CGFloat(0.15 + 0.1 * sin(t * 0.13))
                let y1 = CGFloat(0.12 + 0.05 * cos(t * 0.11))
                let x2 = CGFloat(0.9 + 0.08 * cos(t * 0.09))
                let y2 = CGFloat(0.42 + 0.06 * sin(t * 0.12))
                let x3 = CGFloat(0.3 + 0.12 * sin(t * 0.07 + 2))
                let y3 = CGFloat(0.88 + 0.04 * cos(t * 0.1))
                ZStack {
                    theme.backgroundGradient
                    blob(theme.blobs[0], diameter: w * 1.1, x: w * x1, y: h * y1)
                    blob(theme.blobs[1], diameter: w * 1.0, x: w * x2, y: h * y2)
                    blob(theme.blobs[2], diameter: w * 1.2, x: w * x3, y: h * y3)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func blob(_ color: Color, diameter: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(theme.isDark ? 0.55 : 0.75), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .position(x: x, y: y)
    }
}

// MARK: - Confetti

private struct ConfettiPiece {
    let angle: Double
    let speed: Double
    let spin: Double
    let size: CGFloat
    let color: Color
    let kind: Int
    let drift: Double

    init(seed: Int) {
        func random(_ salt: Double) -> Double {
            let value = sin(Double(seed) * 12.9898 + salt * 78.233) * 43758.5453
            return value - floor(value)
        }
        angle = -Double.pi * (0.1 + 0.8 * random(1))
        speed = 420 + 520 * random(2)
        spin = (random(3) - 0.5) * 14
        size = CGFloat(7 + 7 * random(4))
        color = Palette.confetti[seed % Palette.confetti.count]
        kind = seed % 4
        drift = (random(5) - 0.5) * 60
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
                for piece in pieces {
                    let vx = cos(piece.angle) * piece.speed * 0.75
                    let vy = sin(piece.angle) * piece.speed
                    let x = CGFloat(ox + vx * t * 0.9 + piece.drift * sin(t * 3))
                    let y = CGFloat(oy + vy * t + 0.5 * gravity * t * t)
                    let fade = max(0, min(1, (duration - t) / 0.8))
                    context.drawLayer { layer in
                        layer.opacity = fade
                        layer.translateBy(x: x, y: y)
                        layer.rotate(by: .radians(piece.spin * t))
                        let s = piece.size
                        switch piece.kind {
                        case 0:
                            let rect = CGRect(x: -s / 2, y: -s * 0.35, width: s, height: s * 0.7)
                            layer.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(piece.color))
                        case 1:
                            layer.fill(Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s)), with: .color(piece.color))
                        case 2:
                            let rect = CGRect(x: -s * 0.6, y: -s * 0.6, width: s * 1.2, height: s * 1.1)
                            layer.fill(HeartShape().path(in: rect), with: .color(Palette.blush))
                        default:
                            let rect = CGRect(x: -s * 0.5, y: -s * 0.65, width: s, height: s * 1.3)
                            layer.fill(DropletShape().path(in: rect), with: .color(theme.waterTop))
                        }
                    }
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
                .fill(Palette.leaf)
                .frame(width: size * 0.09, height: size * 0.5)
                .offset(y: size * 0.27)
            Ellipse()
                .fill(Palette.leaf.opacity(0.9))
                .frame(width: size * 0.26, height: size * 0.13)
                .rotationEffect(.degrees(-30))
                .offset(x: size * 0.13, y: size * 0.33)

            // Bloom
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Ellipse()
                        .fill(LinearGradient(colors: [color.opacity(0.75), color], startPoint: .top, endPoint: .bottom))
                        .frame(width: size * 0.3, height: size * 0.42)
                        .offset(y: -size * 0.17)
                        .rotationEffect(.degrees(Double(index) * 72))
                }
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFFF1A8), Palette.sunshine], center: .center, startRadius: 0, endRadius: size * 0.14))
                    .frame(width: size * 0.26, height: size * 0.26)
                Circle()
                    .fill(Color.white.opacity(0.7))
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
                .fill(Palette.leaf)
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

// MARK: - Shimmer

/// A soft moving highlight, great on premium labels.
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.65), .clear],
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
