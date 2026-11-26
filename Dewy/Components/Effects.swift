import SwiftUI

// MARK: - Deterministic Noise Helpers

private func effectFract(_ value: Double) -> Double {
    value - floor(value)
}

private func effectNoise(_ seed: Double, _ salt: Double) -> Double {
    effectFract(sin(seed * 12.9898 + salt * 78.233) * 43_758.5453)
}

// MARK: - Botanical Gouache Confetti & Floating Petals

private enum BotanicalKind: CaseIterable {
    case sakuraPetal
    case sageLeaf
    case waterBead
    case goldStarlet
    case paperHeart
}

private struct BotanicalPiece {
    let kind: BotanicalKind
    let angle: Double
    let speed: Double
    let spin: Double
    let tumbleSpeed: Double
    let tumblePhase: Double
    let flutterAmp: Double
    let flutterFreq: Double
    let dragRate: Double
    let frontColor: Color
    let backColor: Color
    let shadowColor: Color
    let size: CGFloat
    let path: Path

    init(seed: Int) {
        let sDouble = Double(seed)
        func rnd(_ salt: Double) -> Double { effectNoise(sDouble, salt) }

        angle = -Double.pi * (0.08 + 0.84 * rnd(1.1))
        speed = 380 + 520 * rnd(2.2)
        spin = (rnd(3.3) - 0.5) * 6.5
        tumbleSpeed = 4.2 + rnd(4.4) * 5.8
        tumblePhase = rnd(5.5) * Double.pi * 2.0
        flutterAmp = 18 + rnd(6.6) * 38
        flutterFreq = 2.2 + rnd(7.7) * 2.4
        dragRate = 0.72 + rnd(8.8) * 0.58

        let baseSize = CGFloat(10.5 + 8.5 * rnd(9.9))
        size = baseSize

        let kinds = BotanicalKind.allCases
        let picked = kinds[seed % kinds.count]
        kind = picked

        let palette: (Color, Color) = Self.colors(for: picked, variant: seed % 3)
        frontColor = palette.0
        backColor = palette.1
        shadowColor = Color(hex: 0x3D2E46).opacity(0.22)
        path = Self.shapePath(for: picked, size: baseSize)
    }

    private static func colors(for kind: BotanicalKind, variant: Int) -> (Color, Color) {
        switch kind {
        case .sakuraPetal:
            let front = variant == 0 ? Color(hex: 0xFFAEC9) : (variant == 1 ? Color(hex: 0xFFC9DC) : Color(hex: 0xF79BB8))
            return (front, front.blended(with: Color(hex: 0xC96C8C), by: 0.24))
        case .sageLeaf:
            let front = variant == 0 ? Color(hex: 0x89CFA2) : (variant == 1 ? Color(hex: 0xA4DCAB) : Color(hex: 0x6BB98E))
            return (front, front.blended(with: Color(hex: 0x3D7A5E), by: 0.26))
        case .waterBead:
            let front = variant == 0 ? Color(hex: 0x82D6F5) : (variant == 1 ? Color(hex: 0xBCEEFF) : Color(hex: 0x62C4E8))
            return (front, front.blended(with: Color(hex: 0x2F84AD), by: 0.22))
        case .goldStarlet:
            let front = variant == 0 ? Color(hex: 0xFFD468) : (variant == 1 ? Color(hex: 0xFFE699) : Color(hex: 0xF0BA4A))
            return (front, front.blended(with: Color(hex: 0xC28624), by: 0.26))
        case .paperHeart:
            let front = variant == 0 ? Color(hex: 0xFF9684) : (variant == 1 ? Color(hex: 0xFFB8A6) : Color(hex: 0xED7C72))
            return (front, front.blended(with: Color(hex: 0xB54C4B), by: 0.24))
        }
    }

    private static func shapePath(for kind: BotanicalKind, size s: CGFloat) -> Path {
        switch kind {
        case .sakuraPetal:
            return BlossomPetalShape().path(in: CGRect(x: -s * 0.56, y: -s * 0.64, width: s * 1.12, height: s * 1.28))
        case .sageLeaf:
            return BotanicalLeafShape().path(in: CGRect(x: -s * 0.44, y: -s * 0.72, width: s * 0.88, height: s * 1.44))
        case .waterBead:
            return TeardropBeadShape().path(in: CGRect(x: -s * 0.42, y: -s * 0.56, width: s * 0.84, height: s * 1.12))
        case .goldStarlet:
            return StarletShape().path(in: CGRect(x: -s * 0.70, y: -s * 0.70, width: s * 1.40, height: s * 1.40))
        case .paperHeart:
            return HeartShape().path(in: CGRect(x: -s * 0.55, y: -s * 0.52, width: s * 1.10, height: s * 1.04))
        }
    }
}

/// Hand-cut botanical gouache confetti: sakura petals, sage pressed leaves, glistening
/// water beads, antique gold starlets and paper hearts with 3D fluttering tumble physics.
struct ConfettiView: View {
    var trigger: Int
    var origin: UnitPoint = UnitPoint(x: 0.5, y: 0.32)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?

    private let pieces = (0..<76).map(BotanicalPiece.init(seed:))
    private let duration: Double = 3.4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let elapsed = timeline.date.timeIntervalSince(start)
                if reduceMotion {
                    drawReducedBloom(in: &context, size: size, time: elapsed)
                } else {
                    drawFlutter(in: &context, size: size, time: elapsed)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            start = .now
            let sleepDuration = reduceMotion ? 1.4 : duration + 0.1
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(sleepDuration))
                start = nil
            }
        }
    }

    private func drawFlutter(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        guard t >= 0, t < duration else { return }
        let ox = Double(size.width) * Double(origin.x)
        let oy = Double(size.height) * Double(origin.y)
        let fadeOut = max(0.0, min(1.0, (duration - t) / 0.85))
        let fadeIn = min(1.0, t / 0.08)
        context.opacity = fadeIn * fadeOut

        for piece in pieces {
            // Papery aerodynamic drag transitions brisk launch into gentle drifting descent.
            let decay = (1.0 - exp(-t * piece.dragRate)) / piece.dragRate
            let vx = cos(piece.angle) * piece.speed * 0.72
            let vy = sin(piece.angle) * piece.speed * 0.88
            let terminalFall = 195.0 * t + 115.0 * max(t - 0.35, 0) * max(t - 0.35, 0)
            let flutterX = piece.flutterAmp * sin(t * piece.flutterFreq + piece.tumblePhase) * min(t * 1.4, 1.0)

            let px = CGFloat(ox + vx * decay + flutterX)
            let py = CGFloat(oy + vy * decay + terminalFall * 0.65)
            if py > size.height + 40 { continue }

            let rawFlip = cos(piece.tumbleSpeed * t + piece.tumblePhase)
            let flipSign: CGFloat = rawFlip >= 0 ? 1 : -1
            let scaleX = flipSign * CGFloat(max(abs(rawFlip), 0.16))
            let rot = CGFloat(piece.spin * t)

            let transform = CGAffineTransform(translationX: px, y: py)
                .rotated(by: rot)
                .scaledBy(x: scaleX, y: 1.0)
            let shaped = piece.path.applying(transform)

            // Warm ink paper shadow underside.
            let shadowPath = shaped.applying(CGAffineTransform(translationX: 0.6, y: 1.9))
            context.fill(shadowPath, with: .color(piece.shadowColor))

            let fillCol = rawFlip >= 0 ? piece.frontColor : piece.backColor
            context.fill(shaped, with: .color(fillCol))

            // Subtle matte paper highlight glint on front face.
            if rawFlip > 0.25 {
                let r = piece.size * 0.14
                let glintRect = CGRect(x: -piece.size * 0.18 - r, y: -piece.size * 0.16 - r, width: r * 2, height: r * 1.5)
                let glint = Path(ellipseIn: glintRect).applying(transform)
                context.fill(glint, with: .color(Color(hex: 0xFFFDF8).opacity(0.68)))
            }
        }
    }

    private func drawReducedBloom(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        guard t >= 0, t < 1.3 else { return }
        let p = t / 1.3
        let alpha = sin(p * Double.pi)
        let ox = Double(size.width) * Double(origin.x)
        let oy = Double(size.height) * Double(origin.y)
        context.opacity = alpha

        for piece in pieces.prefix(28) {
            let dist = 28.0 + 72.0 * (1.0 - pow(1.0 - p, 2.0)) * (0.4 + piece.speed / 950.0)
            let px = CGFloat(ox + cos(piece.angle) * dist)
            let py = CGFloat(oy + sin(piece.angle) * dist * 0.8)
            let transform = CGAffineTransform(translationX: px, y: py).rotated(by: CGFloat(piece.tumblePhase))
            context.fill(piece.path.applying(transform), with: .color(piece.frontColor))
        }
    }
}

// MARK: - Opalescent Dewdrop Bubble Field

/// Delicate opalescent soap-and-dewdrop rings with warm cotton-paper sheen, used behind celebrations.
struct BubbleField: View {
    var count = 14
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isLive)) { timeline in
            let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : 10.0
            Canvas { context, size in
                for index in 0..<count {
                    drawOpalescentBubble(in: &context, index: index, size: size, time: t)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawOpalescentBubble(in context: inout GraphicsContext, index: Int, size: CGSize, time t: Double) {
        let seed = Double(index)
        let r = CGFloat(9 + effectNoise(seed, 1.2) * 20)
        let speed = 16 + effectNoise(seed, 2.3) * 26
        let span = Double(size.height + r * 4)
        let y = size.height + r * 2 - CGFloat((t * speed + effectNoise(seed, 3.4) * span).truncatingRemainder(dividingBy: span))
        let x = CGFloat(effectNoise(seed, 4.5)) * size.width + CGFloat(sin(t * 1.15 + seed)) * 11
        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)

        // Warm cotton-paper translucent core fill.
        let fillGrad = Gradient(stops: [
            .init(color: Color(hex: 0xFFFDF8).opacity(0.06), location: 0.0),
            .init(color: Palette.aquaLight.opacity(0.18), location: 0.68),
            .init(color: Color(hex: 0xFFE6F0).opacity(0.36), location: 0.90),
            .init(color: Color(hex: 0xFFFDF8).opacity(0.68), location: 1.0)
        ])
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(fillGrad, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r)
        )

        // Delicate iridescent rim stroke.
        let rimColors = index.isMultiple(of: 2)
            ? [Color(hex: 0xFFFDF8).opacity(0.75), Color(hex: 0xB8EFFF).opacity(0.65), Color(hex: 0xFFCDE2).opacity(0.62)]
            : [Color(hex: 0xFFFDF8).opacity(0.75), Color(hex: 0xD6C7FF).opacity(0.60), Color(hex: 0xA8E8F8).opacity(0.65)]
        context.stroke(
            Path(ellipseIn: rect),
            with: .linearGradient(Gradient(colors: rimColors), startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)),
            lineWidth: 1.25
        )

        // Soft inner lower caustic crescent.
        var crescent = Path()
        crescent.addArc(center: CGPoint(x: x, y: y), radius: r * 0.78, startAngle: .degrees(24), endAngle: .degrees(106), clockwise: false)
        context.stroke(crescent, with: .color(Color(hex: 0xFFF5D8).opacity(0.45)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        // Crisp pearlescent upper-left specular glint.
        let specRect = CGRect(x: x - r * 0.54, y: y - r * 0.56, width: r * 0.42, height: r * 0.28)
        context.fill(Path(ellipseIn: specRect), with: .color(Color(hex: 0xFFFDF8).opacity(0.90)))
    }
}

// MARK: - Rolling Number

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
        if LaunchOptions.freezesMotion {
            shown = value
            return
        }
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

// MARK: - Handcrafted Gouache Pour-In Stream

/// Animates a joyful handcrafted sip pour over ~0.62s: the drink icon lifts and tilts,
/// launches a parabolic translucent watercolor liquid ribbon + trailing pearlescent
/// droplets into Dewy's crown, tapers cleanly, and fires `onImpact()` at touchdown.
struct GouachePourStream: View {
    var from: CGPoint
    var to: CGPoint
    var color: Color
    var kind: DrinkKind
    var onImpact: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date = .now
    @State private var didImpact = false
    @State private var reducedProgress: Double = 0

    private let totalDuration: Double = 0.62
    private let impactDelay: Double = 0.60

    init(
        from: CGPoint,
        to: CGPoint,
        color: Color,
        kind: DrinkKind,
        onImpact: @escaping () -> Void
    ) {
        self.from = from
        self.to = to
        self.color = color
        self.kind = kind
        self.onImpact = onImpact
    }

    private var prefersReduced: Bool { reduceMotion || LaunchOptions.freezesMotion }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if prefersReduced {
                reducedPourView
            } else {
                livePourView
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            startDate = .now
            if prefersReduced {
                withAnimation(.easeOut(duration: 0.24)) {
                    reducedProgress = 1.0
                }
                try? await Task.sleep(for: .seconds(0.22))
                fireImpactOnce()
            } else {
                try? await Task.sleep(for: .seconds(impactDelay))
                fireImpactOnce()
            }
        }
    }

    @MainActor
    private func fireImpactOnce() {
        guard !didImpact else { return }
        didImpact = true
        onImpact()
    }

    private var reducedPourView: some View {
        let p = CGFloat(reducedProgress)
        let cx = from.x + (to.x - from.x) * p
        let cy = from.y + (to.y - from.y) * p
        return DrinkIcon(kind: kind, size: 54)
            .scaleEffect(1.0 - p * 0.35)
            .opacity(1.0 - Double(p) * 0.9)
            .position(x: cx, y: cy)
    }

    private var livePourView: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(startDate))
            let t = min(elapsed / totalDuration, 1.0)
            let tiltRight = from.x <= to.x
            let liftPt = liftedCupPoint(progress: t)
            let cupAngle = cupTiltDegrees(progress: t, tiltRight: tiltRight)
            let cupScale = cupScaleFactor(progress: t)
            let cupAlpha = cupOpacity(progress: t)

            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    drawLiquidArc(in: &context, start: liftPt, end: to, progress: t)
                }

                DrinkIcon(kind: kind, size: 58)
                    .scaleEffect(cupScale)
                    .rotationEffect(.degrees(cupAngle))
                    .opacity(cupAlpha)
                    .position(liftPt)
            }
        }
    }

    private func liftedCupPoint(progress t: Double) -> CGPoint {
        let drift = CGFloat(min(max((t - 0.06) / 0.50, 0.0), 1.0)) * 0.10
        let x = from.x + (to.x - from.x) * drift
        let y: CGFloat
        if t < 0.12 {
            // Tactile 3pt downward anticipation dip during the first ~0.075s before lifting.
            let dipPhase = t / 0.12
            let dip = CGFloat(sin(dipPhase * Double.pi)) * 3.0
            y = from.y + dip
        } else {
            let liftPhase = min((t - 0.12) / 0.22, 1.0)
            let liftEase = 1.0 - pow(1.0 - liftPhase, 3.0)
            y = from.y - CGFloat(liftEase) * 26.0
        }
        return CGPoint(x: x, y: y)
    }

    private func cupTiltDegrees(progress t: Double, tiltRight: Bool) -> Double {
        let dir = tiltRight ? 1.0 : -1.0
        let ramp = min(max((t - 0.10) / 0.18, 0.0), 1.0)
        let eased = 1.0 - pow(1.0 - ramp, 2.0)
        return dir * 28.0 * eased
    }

    private func cupScaleFactor(progress t: Double) -> CGFloat {
        if t < 0.12 {
            let squash = CGFloat(sin((t / 0.12) * Double.pi)) * 0.035
            return 1.0 - squash
        }
        if t < 0.26 {
            let liftFrac = CGFloat((t - 0.12) / 0.14)
            return 1.0 + liftFrac * 0.10
        }
        let fade = min(max((t - 0.44) / 0.26, 0.0), 1.0)
        return 1.10 - CGFloat(fade) * 0.38
    }

    private func cupOpacity(progress t: Double) -> Double {
        if t < 0.44 { return 1.0 }
        let fade = min((t - 0.44) / 0.24, 1.0)
        return max(0.0, 1.0 - fade)
    }

    private func bezierPoint(_ u: Double, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let f = CGFloat(u)
        let inv = 1.0 - f
        let x = inv * inv * p0.x + 2.0 * inv * f * p1.x + f * f * p2.x
        let y = inv * inv * p0.y + 2.0 * inv * f * p1.y + f * f * p2.y
        return CGPoint(x: x, y: y)
    }

    private func drawLiquidArc(in context: inout GraphicsContext, start: CGPoint, end: CGPoint, progress t: Double) {
        let head = min(max((t - 0.10) / 0.55, 0.0), 1.0)
        let tail = min(max((t - 0.36) / 0.61, 0.0), 1.0)
        guard head > tail + 0.01 else { return }

        let dir: CGFloat = start.x <= end.x ? 1 : -1
        let spout = CGPoint(x: start.x + dir * 18, y: start.y - 8)
        let midX = (spout.x + end.x) * 0.5
        let archLift = max(76.0, abs(spout.y - end.y) * 0.36)
        let apex = CGPoint(x: midX, y: min(spout.y, end.y) - archLift)

        // Build sampled path from tail to head along the parabolic stream.
        let segments = 24
        var points: [CGPoint] = []
        for idx in 0...segments {
            let frac = Double(idx) / Double(segments)
            let u = tail + (head - tail) * frac
            points.append(bezierPoint(u, p0: spout, p1: apex, p2: end))
        }

        let auraTint = color.blended(with: .white, by: 0.45)

        // Render tapered gouache watercolor ribbon in overlapping luminous & core strokes.
        for idx in 0..<(points.count - 1) {
            let frac = Double(idx) / Double(max(points.count - 1, 1))
            let taper = sin(frac * Double.pi)
            let coreW = CGFloat(3.5 + 7.5 * taper)
            let washW = coreW * 1.85
            let pA = points[idx]
            let pB = points[idx + 1]

            var seg = Path()
            seg.move(to: pA)
            seg.addLine(to: pB)

            context.stroke(seg, with: .color(auraTint.opacity(0.24)), style: StrokeStyle(lineWidth: washW, lineCap: .round))
            context.stroke(seg, with: .color(color.opacity(0.88)), style: StrokeStyle(lineWidth: coreW, lineCap: .round))

            if taper > 0.25 {
                var ridge = Path()
                ridge.move(to: CGPoint(x: pA.x, y: pA.y - coreW * 0.22))
                ridge.addLine(to: CGPoint(x: pB.x, y: pB.y - coreW * 0.22))
                context.stroke(ridge, with: .color(Color(hex: 0xFFFDF8).opacity(0.72 * taper)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
        }

        // Trailing pearlescent droplets orbiting gently off the pour ribbon.
        drawTrailingDroplets(in: &context, spout: spout, apex: apex, end: end, head: head, tail: tail)
    }

    private func drawTrailingDroplets(
        in context: inout GraphicsContext,
        spout: CGPoint,
        apex: CGPoint,
        end: CGPoint,
        head: Double,
        tail: Double
    ) {
        let count = 7
        let auraBase = color.blended(with: .white, by: 0.45)
        for i in 0..<count {
            let seed = Double(i) + 17.0
            let rel = 0.14 + 0.78 * (Double(i) / Double(count - 1))
            let u = tail + (head - tail) * rel
            guard u > 0.04, u < 0.98 else { continue }

            let base = bezierPoint(u, p0: spout, p1: apex, p2: end)
            let spread = CGFloat((effectNoise(seed, 1.3) - 0.5) * 26.0)
            let dropY = CGFloat((effectNoise(seed, 2.4) - 0.35) * 20.0)
            let center = CGPoint(x: base.x + spread, y: base.y + dropY)
            let r = CGFloat(2.8 + effectNoise(seed, 3.5) * 3.2)

            // Soft luminous nocturnal outer aura halo so droplets shimmer on Starlight & Dusk ponds.
            let auraR = r * 2.15
            let auraRect = CGRect(x: center.x - auraR, y: center.y - auraR, width: auraR * 2, height: auraR * 2)
            let auraGrad = Gradient(colors: [auraBase.opacity(0.28), auraBase.opacity(0.0)])
            context.fill(
                Path(ellipseIn: auraRect),
                with: .radialGradient(auraGrad, center: center, startRadius: r * 0.3, endRadius: auraR)
            )

            let rect = CGRect(x: center.x - r, y: center.y - r * 1.15, width: r * 2, height: r * 2.3)
            let drop = TeardropBeadShape().path(in: rect)
            context.fill(drop, with: .color(color.opacity(0.90)))
            let spec = CGRect(x: center.x - r * 0.42, y: center.y - r * 0.25, width: r * 0.52, height: r * 0.45)
            context.fill(Path(ellipseIn: spec), with: .color(Color(hex: 0xFFFDF8).opacity(0.92)))
        }
    }
}

// MARK: - Handcrafted Watercolor Splash Burst

/// Fires a crisp 0.75s gouache splash on `trigger`: radial arc of liquid droplets,
/// two expanding hand-inked concentric splash rings, and four blooming botanical starlets.
struct WatercolorSplashBurst: View {
    var trigger: Int
    var color: Color = Palette.aqua

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?

    private let duration: Double = 0.75

    init(trigger: Int, color: Color = Palette.aqua) {
        self.trigger = trigger
        self.color = color
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let elapsed = timeline.date.timeIntervalSince(start)
                drawSplash(in: &context, size: size, elapsed: elapsed)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            start = .now
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.08))
                start = nil
            }
        }
    }

    private func drawSplash(in context: inout GraphicsContext, size: CGSize, elapsed: Double) {
        guard elapsed >= 0, elapsed < duration else { return }
        let p = elapsed / duration
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.56)
        let inkRim = color.blended(with: Ink.primary, by: 0.28)
        let lightTint = color.blended(with: Color(hex: 0xFFFDF8), by: 0.45)

        // 1. Two staggered expanding hand-inked concentric splash rings.
        for ringIdx in 0..<2 {
            let rp = (p - Double(ringIdx) * 0.14) / 0.86
            guard rp > 0, rp < 1 else { continue }
            let eased = 1.0 - pow(1.0 - rp, 2.4)
            let rx = CGFloat(18.0 + eased * (reduceMotion ? 42.0 : 76.0) * (ringIdx == 0 ? 1.0 : 0.78))
            let ry = rx * 0.42
            let rect = CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
            let alpha = (1.0 - rp) * (ringIdx == 0 ? 0.78 : 0.56)

            context.stroke(
                Path(ellipseIn: rect),
                with: .color(lightTint.opacity(alpha)),
                style: StrokeStyle(lineWidth: 3.4 - CGFloat(ringIdx) * 0.8, lineCap: .round)
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(inkRim.opacity(alpha * 0.42)),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [10, 6])
            )
        }

        // 2. Radial crown arc of 11 handcrafted liquid droplets launching outward.
        let dropCount = reduceMotion ? 6 : 11
        let dropEase = 1.0 - pow(1.0 - p, 2.2)
        for i in 0..<dropCount {
            let seed = Double(i) + 5.0
            let span = Double.pi * 0.92
            let angle = -Double.pi * 0.96 + span * (Double(i) / Double(max(dropCount - 1, 1)))
            let maxDist = (reduceMotion ? 38.0 : 62.0) + effectNoise(seed, 1.4) * 34.0
            let gravityY = (reduceMotion ? 10.0 : 34.0) * p * p

            let dx = cos(angle) * maxDist * dropEase
            let dy = sin(angle) * maxDist * dropEase + gravityY
            let pt = CGPoint(x: center.x + CGFloat(dx), y: center.y + CGFloat(dy))

            let sizeScale = CGFloat(1.0 - p * 0.62)
            let dropW = CGFloat(5.5 + effectNoise(seed, 2.4) * 3.8) * sizeScale
            let dropH = dropW * 1.45
            let alpha = max(0.0, 1.0 - pow(p, 1.8))

            let rotAngle = angle + Double.pi / 2.0
            let transform = CGAffineTransform(translationX: pt.x, y: pt.y)
                .rotated(by: CGFloat(rotAngle))
            let bead = TeardropBeadShape().path(in: CGRect(x: -dropW * 0.5, y: -dropH * 0.5, width: dropW, height: dropH)).applying(transform)

            context.fill(bead, with: .color(color.opacity(0.86 * alpha)))
            context.stroke(bead, with: .color(inkRim.opacity(0.32 * alpha)), lineWidth: 0.8)

            let glintR = dropW * 0.22
            let glint = Path(ellipseIn: CGRect(x: pt.x - glintR, y: pt.y - glintR, width: glintR * 2, height: glintR * 1.6))
            context.fill(glint, with: .color(Color(hex: 0xFFFDF8).opacity(0.85 * alpha)))
        }

        // 3. Four blooming antique-gold & pearlescent botanical starlets.
        let starAngles: [Double] = [-2.45, -1.78, -1.24, -0.62]
        for (idx, angle) in starAngles.enumerated() {
            let sp = max(0.0, min(1.0, (p - Double(idx) * 0.05) / 0.78))
            guard sp > 0, sp < 1 else { continue }
            let bloom = sin(sp * Double.pi)
            let dist = (reduceMotion ? 36.0 : 58.0) + Double(idx % 2) * 18.0 * (1.0 - pow(1.0 - sp, 2.0))
            let sx = center.x + CGFloat(cos(angle) * dist)
            let sy = center.y + CGFloat(sin(angle) * dist)
            let r = CGFloat(5.0 + 4.5 * bloom)
            let rect = CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)
            let starCol = idx.isMultiple(of: 2) ? Color(hex: 0xFFD972) : Color(hex: 0xFFFDF4)
            context.fill(StarletShape().path(in: rect), with: .color(starCol.opacity(0.92 * bloom)))
        }
    }
}
