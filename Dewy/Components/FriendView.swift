import SwiftUI

/// One of Dewy's 12 collectible storybook pond friends, hand-drawn natively in SwiftUI Canvas.
///
/// Each species has a distinct silhouette, gouache palette, warm botanical ink contour,
/// grounded contact shadow, 60 Hz idle personality, and celebratory hop animation.
struct FriendView: View {
    var friend: Friend
    var size: CGFloat = 76
    var animated: Bool = true
    var celebrateTrigger: Int = 0
    var isNight: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrateStart: Date?

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
                    let now = timeline.date
                    let t = isLive ? now.timeIntervalSinceReferenceDate : 0.7
                    let joy = isLive ? joyAmount(at: now) : 0
                    friendCanvas(time: t, joy: joy)
                }
            } else {
                friendCanvas(time: 0.7, joy: 0)
            }
        }
        .frame(width: size, height: size)
        .modifier(FriendHopEffect(trigger: celebrateTrigger, size: size, enabled: animated && !reduceMotion))
        .onChange(of: celebrateTrigger) {
            celebrateStart = .now
        }
        .accessibilityElement()
        .accessibilityLabel("\(friend.name), \(friend.species)")
    }

    private func joyAmount(at now: Date) -> Double {
        guard let celebrateStart else { return 0 }
        let elapsed = now.timeIntervalSince(celebrateStart)
        guard elapsed >= 0, elapsed < 1.45 else { return 0 }
        let rise = min(elapsed / 0.14, 1)
        let fall = min(max((1.45 - elapsed) / 0.35, 0), 1)
        return rise * fall
    }

    private func friendCanvas(time rawTime: Double, joy: Double) -> some View {
        let phase = FriendArt.phaseOffset(for: friend)
        let t = rawTime + phase
        return Canvas { context, canvasSize in
            let u = min(canvasSize.width, canvasSize.height) / 100.0
            let ox = (canvasSize.width - 100 * u) * 0.5
            let oy = (canvasSize.height - 100 * u) * 0.5
            let p: (CGFloat, CGFloat) -> CGPoint = { x, y in
                CGPoint(x: ox + x * u, y: oy + y * u)
            }

            // Grounded soft watercolor contact shadow (richer & warmer-cozy under Starlight night).
            let breath = sin(t * 2.4)
            let shadowW: CGFloat = FriendArt.shadowWidth(for: friend) - CGFloat(breath) * 2.2
            let shadowTone = isNight ? Color(hex: 0x111536) : Color(hex: 0x3A4E59)
            context.drawLayer { shadowCtx in
                shadowCtx.addFilter(.blur(radius: (isNight ? 3.0 : 2.2) * u))
                let origin = p(50 - shadowW * 0.5, 84.5)
                let oval = Path(ellipseIn: CGRect(x: origin.x, y: origin.y, width: shadowW * u, height: 8.8 * u))
                shadowCtx.fill(oval, with: .color(shadowTone.opacity(isNight ? 0.42 : 0.20)))
            }

            // Soft moonlit atmospheric halo behind character in Starlight night.
            if isNight {
                context.drawLayer { haloCtx in
                    haloCtx.addFilter(.blur(radius: 7.5 * u))
                    let origin = p(22, 18)
                    let halo = Path(ellipseIn: CGRect(x: origin.x, y: origin.y, width: 56 * u, height: 54 * u))
                    haloCtx.fill(halo, with: .color(Color(hex: 0x9FB4F5).opacity(0.16)))
                }
            }

            // Species-specific gentle breathing & rhythm transform.
            let blink = FriendArt.blinkOpenness(time: t, live: isLive)
            let state = FriendAnim(time: t, breath: breath, blink: blink, joy: joy, isNight: isNight)

            context.drawLayer { charCtx in
                FriendArt.draw(friend, in: &charCtx, p: p, u: u, anim: state)

                if isNight {
                    // Authentic moonlit harmony: clipped indigo-twilight color wash + cool silver upper rim.
                    let fullRect = Path(CGRect(origin: .zero, size: canvasSize))
                    charCtx.blendMode = .sourceAtop
                    charCtx.fill(
                        fullRect,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(hex: 0x4E5B9E).opacity(0.16),
                                Color(hex: 0x22285E).opacity(0.32)
                            ]),
                            startPoint: p(24, 16),
                            endPoint: p(76, 86)
                        )
                    )
                    // Cool silver-moonlight upper-left rim sheen.
                    charCtx.fill(
                        fullRect,
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(hex: 0xDCE7FF).opacity(0.26),
                                Color(hex: 0xDCE7FF).opacity(0.0)
                            ]),
                            center: p(34, 22),
                            startRadius: 2 * u,
                            endRadius: 42 * u
                        )
                    )
                }
            }

            // Celebratory golden storybook glints when sipping/cheering!
            if joy > 0.12 {
                FriendArt.drawJoyGlints(in: &context, p: p, u: u, time: t, joy: joy)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Celebratory Hop Keyframe Animation

private struct FriendHop {
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var lift: CGFloat = 0
    var angle: Double = 0
}

private struct FriendHopEffect: ViewModifier {
    var trigger: Int
    var size: CGFloat
    var enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.keyframeAnimator(initialValue: FriendHop(), trigger: trigger) { view, value in
                view
                    .scaleEffect(x: value.scaleX, y: value.scaleY, anchor: .bottom)
                    .rotationEffect(.degrees(value.angle), anchor: .bottom)
                    .offset(y: value.lift)
            } keyframes: { _ in
                KeyframeTrack(\.scaleX) {
                    CubicKeyframe(1.12, duration: 0.10)
                    SpringKeyframe(0.92, duration: 0.22)
                    SpringKeyframe(1.0, duration: 0.52, spring: .bouncy)
                }
                KeyframeTrack(\.scaleY) {
                    CubicKeyframe(0.88, duration: 0.10)
                    SpringKeyframe(1.10, duration: 0.22)
                    SpringKeyframe(1.0, duration: 0.52, spring: .bouncy)
                }
                KeyframeTrack(\.lift) {
                    CubicKeyframe(0, duration: 0.10)
                    SpringKeyframe(-size * 0.16, duration: 0.22)
                    SpringKeyframe(0, duration: 0.52, spring: .bouncy)
                }
                KeyframeTrack(\.angle) {
                    CubicKeyframe(-4, duration: 0.14)
                    SpringKeyframe(5, duration: 0.22)
                    SpringKeyframe(0, duration: 0.48, spring: .bouncy)
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Animation State & Shared Storybook Helpers

private struct FriendAnim {
    var time: Double
    var breath: Double
    var blink: CGFloat
    var joy: Double
    var isNight: Bool

    var isBeaming: Bool { joy > 0.22 }
}

private enum FriendArt {
    static let ink = Color(hex: 0x251E2B)
    static let cream = Color(hex: 0xFFFBF3)
    static let blush = Color(hex: 0xF58FA3)

    static func phaseOffset(for friend: Friend) -> Double {
        switch friend {
        case .cat: 0.2
        case .bunny: 1.5
        case .frog: 2.7
        case .axolotl: 0.9
        case .bear: 3.4
        case .penguin: 2.1
        case .fox: 4.0
        case .chick: 1.1
        case .panda: 3.8
        case .unicorn: 0.5
        case .dino: 2.9
        case .octopus: 1.8
        }
    }

    static func shadowWidth(for friend: Friend) -> CGFloat {
        switch friend {
        case .frog: 66
        case .fox: 64
        case .dino, .unicorn, .octopus: 60
        case .chick: 40
        case .bunny: 48
        default: 56
        }
    }

    static func blinkOpenness(time: Double, live: Bool) -> CGFloat {
        guard live else { return 1 }
        let cycle = time.truncatingRemainder(dividingBy: 4.2)
        guard cycle < 0.17 else { return 1 }
        let shut = sin((cycle / 0.17) * .pi)
        return max(0.06, CGFloat(1 - shut))
    }

    static func draw(
        _ friend: Friend,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        switch friend {
        case .cat: drawCat(in: &context, p: p, u: u, anim: anim)
        case .bunny: drawBunny(in: &context, p: p, u: u, anim: anim)
        case .frog: drawFrog(in: &context, p: p, u: u, anim: anim)
        case .axolotl: drawAxolotl(in: &context, p: p, u: u, anim: anim)
        case .bear: drawBear(in: &context, p: p, u: u, anim: anim)
        case .penguin: drawPenguin(in: &context, p: p, u: u, anim: anim)
        case .fox: drawFox(in: &context, p: p, u: u, anim: anim)
        case .chick: drawChick(in: &context, p: p, u: u, anim: anim)
        case .panda: drawPanda(in: &context, p: p, u: u, anim: anim)
        case .unicorn: drawUnicorn(in: &context, p: p, u: u, anim: anim)
        case .dino: drawDino(in: &context, p: p, u: u, anim: anim)
        case .octopus: drawOctopus(in: &context, p: p, u: u, anim: anim)
        }
    }

    static func drawJoyGlints(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        time: Double,
        joy: Double
    ) {
        let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (22, 20, 9.0, 0),
            (78, 16, 8.2, 1.4),
            (50, 10, 4.6, 2.5)
        ]
        for (idx, spot) in spots.enumerated() {
            let rise = CGFloat((1 - joy) * 5 + sin(time * 5 + spot.3) * 2)
            let r = (spot.2 * 0.5) * u * CGFloat(0.65 + joy * 0.45)
            let c = p(spot.0, spot.1 - rise)
            let tint = idx.isMultiple(of: 2) ? Color(hex: 0xE8B442) : cream
            context.opacity = min(1, joy * 1.25)
            if idx < 2 {
                let rayStyle = StrokeStyle(lineWidth: 1.3 * u, lineCap: .round)
                for a in [0.0, .pi / 3, 2 * .pi / 3] {
                    let dx = CGFloat(cos(a)) * r
                    let dy = CGFloat(sin(a)) * r
                    var ray = Path()
                    ray.move(to: CGPoint(x: c.x - dx, y: c.y - dy))
                    ray.addLine(to: CGPoint(x: c.x + dx, y: c.y + dy))
                    context.stroke(ray, with: .color(tint), style: rayStyle)
                }
            } else {
                let bead = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                context.fill(bead, with: .color(tint))
                context.stroke(bead, with: .color(ink.opacity(0.32)), lineWidth: 0.8 * u)
            }
            context.opacity = 1
        }
    }

    private static func stroke(_ u: CGFloat, width: CGFloat = 1.9) -> StrokeStyle {
        StrokeStyle(lineWidth: width * u, lineCap: .round, lineJoin: .round)
    }

    private static func oval(
        _ cx: CGFloat,
        _ cy: CGFloat,
        _ rx: CGFloat,
        _ ry: CGFloat,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) -> Path {
        let topLeft = p(cx - rx, cy - ry)
        return Path(ellipseIn: CGRect(x: topLeft.x, y: topLeft.y, width: rx * 2 * u, height: ry * 2 * u))
    }

    /// Soulful storybook eye: warm dark ink dot/oval with single quiet catchlight,
    /// smooth closed blink curve, or joyful beaming arc during celebrations.
    private static func drawEye(
        cx: CGFloat,
        cy: CGFloat,
        rx: CGFloat = 3.1,
        ry: CGFloat = 3.6,
        anim: FriendAnim,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        if anim.isBeaming {
            var arc = Path()
            arc.move(to: p(cx - rx * 1.3, cy + 1.2))
            arc.addQuadCurve(to: p(cx + rx * 1.3, cy + 1.2), control: p(cx, cy - ry * 1.4))
            context.stroke(arc, with: .color(ink), style: stroke(u, width: 2.3))
            return
        }
        if anim.blink < 0.25 {
            var shut = Path()
            shut.move(to: p(cx - rx * 1.15, cy + 0.5))
            shut.addQuadCurve(to: p(cx + rx * 1.15, cy + 0.5), control: p(cx, cy + 2.4))
            context.stroke(shut, with: .color(ink), style: stroke(u, width: 2.0))
            return
        }
        let h = ry * anim.blink
        context.fill(oval(cx, cy, rx, h, p: p, u: u), with: .color(ink))
        if h > 1.8 {
            context.fill(oval(cx - rx * 0.28, cy - h * 0.30, rx * 0.34, rx * 0.32, p: p, u: u), with: .color(cream))
        }
    }

    private static func drawCheeks(
        lx: CGFloat,
        rx: CGFloat,
        y: CGFloat,
        radius: CGFloat = 4.5,
        color: Color = blush,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        context.fill(oval(lx, y, radius, radius * 0.65, p: p, u: u), with: .color(color.opacity(0.55)))
        context.fill(oval(rx, y, radius, radius * 0.65, p: p, u: u), with: .color(color.opacity(0.55)))
    }

    // MARK: 1. Mochi — Curled Ginger-Cream Tabby Cat

    private static func drawCat(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let gingerLight = Color(hex: 0xFBC390)
        let gingerMid = Color(hex: 0xEE9B62)
        let gingerDeep = Color(hex: 0xC86B3B)
        let bibCream = Color(hex: 0xFFF4E4)
        let tailWag = CGFloat(sin(anim.time * (2.6 + anim.joy * 6)) * (5.5 + anim.joy * 4))
        let earFlick = CGFloat(max(0, sin(anim.time * 1.7)) > 0.94 ? 2.5 : 0)
        let bob = CGFloat(anim.breath * 1.1)

        // Curled striped tail sweeping up on the right.
        var tail = Path()
        tail.move(to: p(69, 76))
        tail.addCurve(
            to: p(85 + tailWag * 0.4, 48 + bob),
            control1: p(86, 76),
            control2: p(92 + tailWag * 0.3, 60)
        )
        tail.addCurve(
            to: p(77 + tailWag * 0.3, 45 + bob),
            control1: p(83 + tailWag * 0.4, 42 + bob),
            control2: p(78 + tailWag * 0.3, 42 + bob)
        )
        tail.addCurve(
            to: p(65, 69),
            control1: p(82 + tailWag * 0.2, 57),
            control2: p(76, 68)
        )
        tail.closeSubpath()
        context.fill(tail, with: .linearGradient(Gradient(colors: [gingerLight, gingerMid]), startPoint: p(82, 44), endPoint: p(68, 76)))
        context.stroke(tail, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.85))
        // Tail stripe rings.
        for ty in [CGFloat(56), 64] {
            var ring = Path()
            ring.move(to: p(78 + tailWag * 0.2, ty))
            ring.addLine(to: p(85 + tailWag * 0.25, ty + 2))
            context.stroke(ring, with: .color(gingerDeep.opacity(0.75)), style: stroke(u, width: 2.2))
        }

        // Sitting pear-cat body.
        var body = Path()
        body.move(to: p(26, 78))
        body.addCurve(to: p(28, 48 + bob), control1: p(21, 66), control2: p(22, 56 + bob))
        body.addCurve(to: p(50, 32 + bob), control1: p(32, 36 + bob), control2: p(40, 32 + bob))
        body.addCurve(to: p(72, 48 + bob), control1: p(60, 32 + bob), control2: p(68, 36 + bob))
        body.addCurve(to: p(74, 78), control1: p(78, 56 + bob), control2: p(79, 66))
        body.addQuadCurve(to: p(26, 78), control: p(50, 88))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [gingerLight, gingerMid]), startPoint: p(36, 32), endPoint: p(68, 84)))

        // Cream chest bib.
        context.drawLayer { clipped in
            clipped.clip(to: body)
            clipped.fill(oval(50, 74, 16, 15, p: p, u: u), with: .color(bibCream))
            // Forehead tabby "M" markings.
            for dx in [CGFloat(-5), 0, 5] {
                var stripe = Path()
                stripe.move(to: p(50 + dx, 31 + bob))
                stripe.addLine(to: p(50 + dx * 0.85, 39 + bob))
                clipped.stroke(stripe, with: .color(gingerDeep.opacity(0.75)), style: stroke(u, width: 2.2))
            }
        }
        context.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u))

        // Upright triangular tufted ears.
        var leftEar = Path()
        leftEar.move(to: p(29, 43 + bob))
        leftEar.addLine(to: p(25, 19 + bob))
        leftEar.addLine(to: p(43, 33 + bob))
        leftEar.closeSubpath()

        var rightEar = Path()
        rightEar.move(to: p(71, 43 + bob))
        rightEar.addLine(to: p(75 + earFlick, 19 + bob + earFlick * 0.5))
        rightEar.addLine(to: p(57, 33 + bob))
        rightEar.closeSubpath()

        let earPairs: [(Path, CGPoint, CGPoint, CGPoint)] = [
            (leftEar, p(30, 38 + bob), p(28, 25 + bob), p(39, 34 + bob)),
            (rightEar, p(70, 38 + bob), p(72 + earFlick * 0.7, 25 + bob + earFlick * 0.4), p(61, 34 + bob))
        ]
        for (ear, a, b, c) in earPairs {
            context.fill(ear, with: .color(gingerMid))
            context.stroke(ear, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.85))
            var earIn = Path()
            earIn.move(to: a)
            earIn.addLine(to: b)
            earIn.addLine(to: c)
            earIn.closeSubpath()
            context.fill(earIn, with: .color(Color(hex: 0xF8B8BE)))
        }

        // Tucked little cream front paws.
        for px in [CGFloat(41), 59] {
            let paw = oval(px, 82, 7.2, 4.8, p: p, u: u)
            context.fill(paw, with: .color(bibCream))
            context.stroke(paw, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.65))
        }

        // Whiskers, soulful eyes, triangle nose, and :3 mouth.
        let whisk = CGFloat(sin(anim.time * 3.1) * 1.0)
        for side in [CGFloat(-1), 1] {
            for dy in [CGFloat(-2), 2.5] {
                var w = Path()
                w.move(to: p(50 + side * 16, 54 + dy + bob))
                w.addLine(to: p(50 + side * 27, 52.5 + dy * 1.4 + bob + whisk * side))
                context.stroke(w, with: .color(ink.opacity(0.68)), style: stroke(u, width: 1.3))
            }
        }
        drawCheeks(lx: 34, rx: 66, y: 57 + bob, in: &context, p: p, u: u)
        drawEye(cx: 40, cy: 50 + bob, anim: anim, in: &context, p: p, u: u)
        drawEye(cx: 60, cy: 50 + bob, anim: anim, in: &context, p: p, u: u)

        var nose = Path()
        nose.move(to: p(47.5, 53.5 + bob))
        nose.addLine(to: p(52.5, 53.5 + bob))
        nose.addLine(to: p(50, 56.5 + bob))
        nose.closeSubpath()
        context.fill(nose, with: .color(Color(hex: 0xE87A82)))

        var mouth = Path()
        mouth.move(to: p(44.5, 58.5 + bob))
        mouth.addQuadCurve(to: p(50, 58 + bob), control: p(47.5, 61.5 + bob))
        mouth.addQuadCurve(to: p(55.5, 58.5 + bob), control: p(52.5, 61.5 + bob))
        context.stroke(mouth, with: .color(ink), style: stroke(u, width: 1.7))
    }

    // MARK: 2. Lulu — Tall Slender Lavender-Cream Meadow Hare

    private static func drawBunny(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let lavLight = Color(hex: 0xEFE6FB)
        let lavMid = Color(hex: 0xD2C0F0)
        let earPink = Color(hex: 0xF7B8CC)
        let bob = CGFloat(anim.breath * 1.2)
        let earSwing = CGFloat(sin(anim.time * (2.5 + anim.joy * 6) - 0.5) * (3.2 + anim.joy * 3))
        let noseTwitch = CGFloat(sin(anim.time * 7.5) > 0.72 ? -0.9 : 0)

        // Fluffy cotton tail peeking behind left hip.
        let tail = oval(28, 76, 8.5, 8.0, p: p, u: u)
        context.fill(tail, with: .color(cream))
        context.stroke(tail, with: .color(ink.opacity(0.8)), style: stroke(u, width: 1.75))

        // Tall upright left hare ear.
        var leftEar = Path()
        leftEar.move(to: p(39, 40 + bob))
        leftEar.addCurve(to: p(34 - earSwing * 0.4, 8 + bob), control1: p(33, 28 + bob), control2: p(30 - earSwing * 0.3, 14 + bob))
        leftEar.addCurve(to: p(46, 38 + bob), control1: p(41 - earSwing * 0.2, 7 + bob), control2: p(45, 22 + bob))
        leftEar.closeSubpath()
        context.fill(leftEar, with: .linearGradient(Gradient(colors: [lavLight, lavMid]), startPoint: p(34, 8), endPoint: p(46, 40)))
        context.stroke(leftEar, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.85))
        var leftIn = Path()
        leftIn.move(to: p(39, 36 + bob))
        leftIn.addQuadCurve(to: p(36 - earSwing * 0.3, 15 + bob), control: p(35 - earSwing * 0.2, 24 + bob))
        leftIn.addQuadCurve(to: p(43, 35 + bob), control: p(41, 22 + bob))
        leftIn.closeSubpath()
        context.fill(leftIn, with: .color(earPink))

        // Charmingly bent/tipped right hare ear!
        var rightEar = Path()
        rightEar.move(to: p(54, 38 + bob))
        rightEar.addCurve(to: p(65, 13 + bob), control1: p(55, 23 + bob), control2: p(60, 12 + bob))
        rightEar.addCurve(to: p(76 + earSwing * 0.5, 29 + bob + earSwing * 0.4), control1: p(72, 13 + bob), control2: p(79 + earSwing * 0.5, 20 + bob))
        rightEar.addCurve(to: p(61, 41 + bob), control1: p(71 + earSwing * 0.3, 30 + bob), control2: p(64, 24 + bob))
        rightEar.closeSubpath()
        context.fill(rightEar, with: .linearGradient(Gradient(colors: [lavLight, lavMid]), startPoint: p(64, 12), endPoint: p(62, 42)))
        context.stroke(rightEar, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.85))

        // Slender upright meadow hare body + head.
        var body = Path()
        body.move(to: p(33, 81))
        body.addCurve(to: p(34, 52 + bob), control1: p(29, 71), control2: p(30, 60 + bob))
        body.addCurve(to: p(50, 36 + bob), control1: p(35, 41 + bob), control2: p(42, 36 + bob))
        body.addCurve(to: p(66, 52 + bob), control1: p(58, 36 + bob), control2: p(65, 41 + bob))
        body.addCurve(to: p(67, 81), control1: p(70, 60 + bob), control2: p(71, 71))
        body.addQuadCurve(to: p(33, 81), control: p(50, 88))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [lavLight, lavMid]), startPoint: p(40, 36), endPoint: p(64, 86)))
        context.drawLayer { clipped in
            clipped.clip(to: body)
            clipped.fill(oval(50, 74, 12, 14, p: p, u: u), with: .color(cream))
        }
        context.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u))

        // Neat folded little front paws + grounded feet.
        for px in [CGFloat(42), 58] {
            let foot = oval(px, 83.5, 6.5, 4.0, p: p, u: u)
            context.fill(foot, with: .color(cream))
            context.stroke(foot, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.6))
        }
        for side in [CGFloat(-1), 1] {
            let paw = oval(50 + side * 6.5, 69 + bob * 0.6, 4.8, 3.6, p: p, u: u)
            context.fill(paw, with: .color(lavLight))
            context.stroke(paw, with: .color(ink.opacity(0.75)), style: stroke(u, width: 1.5))
        }

        // Tiny meadow clover sprig behind right ear base.
        for offset in [(CGFloat(60), CGFloat(36 + bob)), (64, 38 + bob), (61, 41 + bob)] {
            context.fill(oval(offset.0, offset.1, 2.7, 2.5, p: p, u: u), with: .color(Color(hex: 0x82C482)))
        }

        // Sweet hare face.
        drawCheeks(lx: 38, rx: 62, y: 56 + bob, radius: 4.0, in: &context, p: p, u: u)
        drawEye(cx: 42.5, cy: 50 + bob, rx: 2.9, ry: 3.4, anim: anim, in: &context, p: p, u: u)
        drawEye(cx: 57.5, cy: 50 + bob, rx: 2.9, ry: 3.4, anim: anim, in: &context, p: p, u: u)

        let nose = oval(50, 54.5 + bob + noseTwitch, 2.6, 1.9, p: p, u: u)
        context.fill(nose, with: .color(Color(hex: 0xF08EA4)))
        var mouth = Path()
        mouth.move(to: p(50, 56.5 + bob))
        mouth.addLine(to: p(50, 58.8 + bob))
        mouth.move(to: p(46.5, 59.5 + bob))
        mouth.addQuadCurve(to: p(50, 58.8 + bob), control: p(48.5, 61.2 + bob))
        mouth.addQuadCurve(to: p(53.5, 59.5 + bob), control: p(51.5, 61.2 + bob))
        context.stroke(mouth, with: .color(ink), style: stroke(u, width: 1.55))
    }

    // MARK: 3. Pip — Wide Perched Moss-Green Pond Frog

    private static func drawFrog(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let mossLight = Color(hex: 0xB3E499)
        let mossMid = Color(hex: 0x76BF73)
        let mossDeep = Color(hex: 0x4E8E54)
        let throatCream = Color(hex: 0xF2F7D6)
        let puff = CGFloat(max(0, sin(anim.time * 2.2)) * 2.8)
        let bob = CGFloat(anim.breath * 0.9)

        // Wide tucked hind haunches on left and right.
        for side in [CGFloat(-1), 1] {
            let haunch = oval(50 + side * 26, 73, 13, 10, p: p, u: u)
            context.fill(haunch, with: .color(mossDeep))
            context.stroke(haunch, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.85))

            // Splayed webbed toes.
            let foot = oval(50 + side * 31, 82.5, 9, 4, p: p, u: u)
            context.fill(foot, with: .color(mossMid))
            context.stroke(foot, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.6))
        }

        // Broad, squat perched pond frog body!
        var body = Path()
        body.move(to: p(20, 72))
        body.addCurve(to: p(50, 44 + bob), control1: p(18, 52 + bob), control2: p(32, 44 + bob))
        body.addCurve(to: p(80, 72), control1: p(68, 44 + bob), control2: p(82, 52 + bob))
        body.addQuadCurve(to: p(20, 72), control: p(50, 88 + puff * 0.4))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [mossLight, mossMid, mossDeep]), startPoint: p(50, 44), endPoint: p(50, 86)))
        context.drawLayer { clipped in
            clipped.clip(to: body)
            // Puffing pale pistachio vocal throat pouch & belly.
            clipped.fill(oval(50, 74 + puff * 0.3, 21 + puff * 0.8, 12 + puff * 0.7, p: p, u: u), with: .color(throatCream))
        }
        context.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u))

        // Two big prominent top-set frog eye domes!
        for ex in [CGFloat(34), 66] {
            let dome = oval(ex, 44 + bob, 11.5, 11.5, p: p, u: u)
            context.fill(dome, with: .linearGradient(Gradient(colors: [mossLight, mossMid]), startPoint: p(ex, 32), endPoint: p(ex, 55)))
            context.stroke(dome, with: .color(ink.opacity(0.85)), style: stroke(u, width: 1.9))

            let sclera = oval(ex, 44 + bob, 7.6, 7.6, p: p, u: u)
            context.fill(sclera, with: .color(cream))
            context.stroke(sclera, with: .color(ink.opacity(0.45)), style: stroke(u, width: 1.1))
            drawEye(cx: ex, cy: 44 + bob, rx: 4.1, ry: 4.4, anim: anim, in: &context, p: p, u: u)
        }

        // Little front perched paws.
        for px in [CGFloat(38), 62] {
            let paw = oval(px, 82, 6.2, 4.2, p: p, u: u)
            context.fill(paw, with: .color(mossLight))
            context.stroke(paw, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.6))
        }

        // Wide joyful pond-frog smile & rosy cheeks.
        drawCheeks(lx: 28, rx: 72, y: 63 + bob, radius: 5.0, in: &context, p: p, u: u)
        var smile = Path()
        smile.move(to: p(35, 61 + bob))
        smile.addQuadCurve(to: p(65, 61 + bob), control: p(50, 69.5 + bob))
        context.stroke(smile, with: .color(ink), style: stroke(u, width: 2.0))

        // Miniature tilted emerald lotus-leaf cap between the eyes with sunlit cream vein & dewdrop!
        context.drawLayer { leafCtx in
            let pivot = p(50, 41 + bob)
            leafCtx.translateBy(x: pivot.x, y: pivot.y)
            leafCtx.rotate(by: .degrees(-6 + sin(anim.time * 2.4) * 3))
            leafCtx.translateBy(x: -pivot.x, y: -pivot.y)
            let cap = oval(50, 40 + bob, 11.8, 4.4, p: p, u: u)
            leafCtx.fill(cap, with: .linearGradient(
                Gradient(colors: [Color(hex: 0x8CD687), Color(hex: 0x4E9C5C)]),
                startPoint: p(40, 36 + bob),
                endPoint: p(60, 44 + bob)
            ))
            leafCtx.stroke(cap, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.5))

            // Sunlit-cream central vein + tiny branching ribs so the leaf reads clearly on dark Starlight ponds!
            var vein = Path()
            vein.move(to: p(41, 40.5 + bob))
            vein.addQuadCurve(to: p(59, 40.2 + bob), control: p(50, 38.6 + bob))
            leafCtx.stroke(vein, with: .color(Color(hex: 0xF5FAD9).opacity(0.92)), style: stroke(u, width: 1.25))

            var stem = Path()
            stem.move(to: p(50, 39 + bob))
            stem.addQuadCurve(to: p(54, 31 + bob), control: p(50, 33 + bob))
            leafCtx.stroke(stem, with: .color(ink.opacity(0.75)), style: stroke(u, width: 2.6))
            leafCtx.stroke(stem, with: .color(Color(hex: 0x6BB86D)), style: stroke(u, width: 1.4))

            // Glistening miniature dewdrop highlight bead perched on the left slope of the lotus leaf.
            let drop = oval(44.5, 38.2 + bob, 2.3, 1.8, p: p, u: u)
            leafCtx.fill(drop, with: .color(Color(hex: 0xDDF9FF)))
            leafCtx.stroke(drop, with: .color(ink.opacity(0.55)), style: stroke(u, width: 0.9))
            leafCtx.fill(oval(43.9, 37.7 + bob, 0.85, 0.7, p: p, u: u), with: .color(.white))
        }
    }

    // MARK: 4. Coral — Peach-Pink Axolotl Water Sprite

    private static func drawAxolotl(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let peachLight = Color(hex: 0xFFE0E8)
        let peachMid = Color(hex: 0xF9B3C7)
        let gillCoral = Color(hex: 0xEE6C7F)
        let gillTip = Color(hex: 0xFF93A5)
        let bob = CGFloat(anim.breath * 1.1)

        // Curving translucent finned tail sweeping left.
        let tailSwish = CGFloat(sin(anim.time * (2.6 + anim.joy * 6)) * (4.5 + anim.joy * 3))
        var tail = Path()
        tail.move(to: p(34, 76))
        tail.addCurve(to: p(12, 60 + tailSwish), control1: p(18, 79), control2: p(10, 70 + tailSwish * 0.5))
        tail.addCurve(to: p(27, 63 + tailSwish * 0.3), control1: p(15, 53 + tailSwish), control2: p(22, 57 + tailSwish * 0.4))
        tail.addQuadCurve(to: p(37, 69), control: p(31, 67))
        tail.closeSubpath()
        context.fill(tail, with: .color(Color(hex: 0xFFC7D8).opacity(0.92)))
        context.stroke(tail, with: .color(ink.opacity(0.78)), style: stroke(u, width: 1.7))

        // Six feathery external coral gill fronds (3 left, 3 right) waving like underwater currents!
        let angles: [Double] = [-38, -8, 22]
        for side in [CGFloat(-1), 1] {
            for (i, baseDeg) in angles.enumerated() {
                let wave = sin(anim.time * (3.0 + anim.joy * 7) + Double(i) * 0.9 + Double(side)) * (7 + anim.joy * 6)
                context.drawLayer { gillCtx in
                    let root = p(50 + side * 20, 44 + CGFloat(i) * 4.5 + bob)
                    gillCtx.translateBy(x: root.x, y: root.y)
                    gillCtx.rotate(by: .degrees(Double(side) * baseDeg + wave))
                    var stalk = Path()
                    stalk.move(to: .zero)
                    stalk.addQuadCurve(to: CGPoint(x: side * 16 * u, y: -2 * u), control: CGPoint(x: side * 8 * u, y: -5 * u))
                    gillCtx.stroke(stalk, with: .color(gillCoral), style: stroke(u, width: 4.4))
                    // Feathery gill frills.
                    for step in [CGFloat(6), 11, 15] {
                        let frill = Path(ellipseIn: CGRect(x: (side * step - 2.4) * u, y: -5.5 * u, width: 4.8 * u, height: 7.5 * u))
                        gillCtx.fill(frill, with: .color(gillTip))
                        gillCtx.stroke(frill, with: .color(ink.opacity(0.65)), style: stroke(u, width: 1.1))
                    }
                    gillCtx.stroke(stalk, with: .color(ink.opacity(0.72)), style: stroke(u, width: 1.3))
                }
            }
        }

        // Soft oblong upright axolotl body & broad rounded head.
        var body = Path()
        body.move(to: p(30, 80))
        body.addCurve(to: p(27, 50 + bob), control1: p(24, 70), control2: p(24, 60 + bob))
        body.addCurve(to: p(50, 32 + bob), control1: p(28, 37 + bob), control2: p(38, 32 + bob))
        body.addCurve(to: p(73, 50 + bob), control1: p(62, 32 + bob), control2: p(72, 37 + bob))
        body.addCurve(to: p(70, 80), control1: p(76, 60 + bob), control2: p(76, 70))
        body.addQuadCurve(to: p(30, 80), control: p(50, 88))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [peachLight, peachMid]), startPoint: p(40, 32), endPoint: p(65, 86)))
        context.drawLayer { clipped in
            clipped.clip(to: body)
            clipped.fill(oval(50, 74, 15, 13, p: p, u: u), with: .color(Color(hex: 0xFFF3F7)))
        }
        context.stroke(body, with: .color(ink.opacity(0.84)), style: stroke(u))

        // Outstretched stubby aquatic paws.
        for side in [CGFloat(-1), 1] {
            let paw = oval(50 + side * 21, 69 + bob * 0.5, 6.0, 4.0, p: p, u: u)
            context.fill(paw, with: .color(peachLight))
            context.stroke(paw, with: .color(ink.opacity(0.78)), style: stroke(u, width: 1.55))
        }

        // Wide serene axolotl smile & wide-set sweet ink eyes.
        drawCheeks(lx: 33, rx: 67, y: 55 + bob, color: gillCoral, in: &context, p: p, u: u)
        drawEye(cx: 37.5, cy: 48.5 + bob, rx: 3.0, ry: 3.3, anim: anim, in: &context, p: p, u: u)
        drawEye(cx: 62.5, cy: 48.5 + bob, rx: 3.0, ry: 3.3, anim: anim, in: &context, p: p, u: u)
        var smile = Path()
        smile.move(to: p(42, 54.5 + bob))
        smile.addQuadCurve(to: p(58, 54.5 + bob), control: p(50, 60.5 + bob))
        context.stroke(smile, with: .color(ink), style: stroke(u, width: 1.85))
    }

    // MARK: 5. Honey — Cozy Plump Cinnamon-Ochre Bear Cub

    private static func drawBear(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let cinLight = Color(hex: 0xEAB178)
        let cinMid = Color(hex: 0xCC894E)
        let cinDeep = Color(hex: 0xA46331)
        let muzzleCream = Color(hex: 0xFCECD4)
        let bob = CGFloat(anim.breath * 1.0)
        let swayDeg = sin(anim.time * 1.9) * 2.2

        context.drawLayer { ctx in
            let base = p(50, 84)
            ctx.translateBy(x: base.x, y: base.y)
            ctx.rotate(by: .degrees(swayDeg))
            ctx.translateBy(x: -base.x, y: -base.y)

            // Wide round scalloped cub ears.
            for ex in [CGFloat(29), 71] {
                let ear = oval(ex, 31 + bob, 10.5, 10.5, p: p, u: u)
                ctx.fill(ear, with: .color(cinMid))
                ctx.stroke(ear, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.9))
                ctx.fill(oval(ex, 31.5 + bob, 5.5, 5.5, p: p, u: u), with: .color(muzzleCream))
            }

            // Cozy broad round-shouldered sitting bear body + head.
            var body = Path()
            body.move(to: p(22, 77))
            body.addCurve(to: p(24, 48 + bob), control1: p(18, 65), control2: p(20, 56 + bob))
            body.addCurve(to: p(50, 27 + bob), control1: p(26, 33 + bob), control2: p(37, 27 + bob))
            body.addCurve(to: p(76, 48 + bob), control1: p(63, 27 + bob), control2: p(74, 33 + bob))
            body.addCurve(to: p(78, 77), control1: p(80, 56 + bob), control2: p(82, 65))
            body.addQuadCurve(to: p(22, 77), control: p(50, 87))
            body.closeSubpath()

            ctx.fill(body, with: .linearGradient(Gradient(colors: [cinLight, cinMid, cinDeep]), startPoint: p(38, 28), endPoint: p(68, 86)))
            ctx.drawLayer { clipped in
                clipped.clip(to: body)
                clipped.fill(oval(50, 74, 16, 13, p: p, u: u), with: .color(muzzleCream))
            }
            ctx.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u))

            // Golden honey neck ribbon + tiny drop charm!
            var ribbon = Path()
            ribbon.move(to: p(30, 62 + bob * 0.5))
            ribbon.addQuadCurve(to: p(70, 62 + bob * 0.5), control: p(50, 68.5 + bob * 0.5))
            ctx.stroke(ribbon, with: .color(Color(hex: 0xF5BE41)), style: stroke(u, width: 4.5))
            ctx.stroke(ribbon, with: .color(ink.opacity(0.68)), style: stroke(u, width: 1.3))
            let charm = oval(50, 68 + bob * 0.5, 3.6, 4.3, p: p, u: u)
            ctx.fill(charm, with: .color(Color(hex: 0xFFD966)))
            ctx.stroke(charm, with: .color(ink.opacity(0.75)), style: stroke(u, width: 1.3))

            // Chunky seated bear feet with cream paw pads.
            for px in [CGFloat(34), 66] {
                let foot = oval(px, 80.5, 9.0, 6.2, p: p, u: u)
                ctx.fill(foot, with: .color(cinMid))
                ctx.stroke(foot, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.75))
                ctx.fill(oval(px, 81, 4.6, 3.2, p: p, u: u), with: .color(muzzleCream))
            }

            // Prominent cream oval snout + cocoa button nose.
            let snout = oval(50, 52.5 + bob, 11.5, 8.2, p: p, u: u)
            ctx.fill(snout, with: .color(muzzleCream))
            ctx.stroke(snout, with: .color(ink.opacity(0.55)), style: stroke(u, width: 1.3))

            let nose = oval(50, 49.5 + bob, 4.4, 3.1, p: p, u: u)
            ctx.fill(nose, with: .color(Color(hex: 0x3D2620)))
            ctx.fill(oval(48.7, 48.5 + bob, 1.3, 0.9, p: p, u: u), with: .color(cream.opacity(0.8)))

            var mouth = Path()
            mouth.move(to: p(50, 52.5 + bob))
            mouth.addLine(to: p(50, 55.2 + bob))
            mouth.move(to: p(46, 55.6 + bob))
            mouth.addQuadCurve(to: p(50, 55.2 + bob), control: p(48, 57.5 + bob))
            mouth.addQuadCurve(to: p(54, 55.6 + bob), control: p(52, 57.5 + bob))
            ctx.stroke(mouth, with: .color(ink), style: stroke(u, width: 1.65))

            drawCheeks(lx: 32, rx: 68, y: 52 + bob, in: &ctx, p: p, u: u)
            drawEye(cx: 38.5, cy: 44 + bob, rx: 2.8, ry: 3.1, anim: anim, in: &ctx, p: p, u: u)
            drawEye(cx: 61.5, cy: 44 + bob, rx: 2.8, ry: 3.1, anim: anim, in: &ctx, p: p, u: u)
        }
    }

    // MARK: 6. Pebble — Dapper Slate-Indigo Penguin Chick

    private static func drawPenguin(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let slateLight = Color(hex: 0x62759E)
        let slateMid = Color(hex: 0x3E4E75)
        let slateDeep = Color(hex: 0x293452)
        let marigold = Color(hex: 0xF7A83B)
        let waddle = sin(anim.time * (2.6 + anim.joy * 6)) * (3.2 + anim.joy * 3.5)
        let flap = sin(anim.time * (3.4 + anim.joy * 9)) * (10 + anim.joy * 14)

        // Flat marigold webbed feet planted solidly.
        for fx in [CGFloat(39), 61] {
            let foot = oval(fx, 83.5, 9.5, 4.2, p: p, u: u)
            context.fill(foot, with: .color(marigold))
            context.stroke(foot, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.75))
        }

        context.drawLayer { ctx in
            let pivot = p(50, 82)
            ctx.translateBy(x: pivot.x, y: pivot.y)
            ctx.rotate(by: .degrees(waddle))
            ctx.translateBy(x: -pivot.x, y: -pivot.y)

            // Stubby flapping side flippers!
            for side in [CGFloat(-1), 1] {
                ctx.drawLayer { wingCtx in
                    let joint = p(50 + side * 24, 54)
                    wingCtx.translateBy(x: joint.x, y: joint.y)
                    wingCtx.rotate(by: .degrees(Double(side) * (24 + flap)))
                    let flipper = Path(ellipseIn: CGRect(x: -5.5 * u, y: -2 * u, width: 11 * u, height: 24 * u))
                    wingCtx.fill(flipper, with: .color(slateMid))
                    wingCtx.stroke(flipper, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.85))
                }
            }

            // Plump upright teardrop penguin body.
            var body = Path()
            body.move(to: p(24, 73))
            body.addCurve(to: p(27, 42), control1: p(20, 62), control2: p(21, 51))
            body.addCurve(to: p(50, 22), control1: p(31, 28), control2: p(40, 22))
            body.addCurve(to: p(73, 42), control1: p(60, 22), control2: p(69, 28))
            body.addCurve(to: p(76, 73), control1: p(79, 51), control2: p(80, 62))
            body.addQuadCurve(to: p(24, 73), control: p(50, 87))
            body.closeSubpath()

            ctx.fill(body, with: .linearGradient(Gradient(colors: [slateLight, slateMid, slateDeep]), startPoint: p(36, 22), endPoint: p(68, 84)))

            // Iconic heart-shaped porcelain-cream face & belly mask!
            var mask = Path()
            mask.move(to: p(50, 41))
            mask.addCurve(to: p(31, 46), control1: p(44, 33), control2: p(33, 35))
            mask.addCurve(to: p(30, 74), control1: p(27, 56), control2: p(26, 67))
            mask.addQuadCurve(to: p(70, 74), control: p(50, 86))
            mask.addCurve(to: p(69, 46), control1: p(74, 67), control2: p(73, 56))
            mask.addCurve(to: p(50, 41), control1: p(67, 35), control2: p(56, 33))
            mask.closeSubpath()

            ctx.drawLayer { clipped in
                clipped.clip(to: body)
                clipped.fill(mask, with: .color(cream))
            }
            ctx.stroke(body, with: .color(ink.opacity(0.88)), style: stroke(u))

            // Dapper downy crown feather tuft.
            var tuft = Path()
            tuft.move(to: p(50, 22))
            tuft.addQuadCurve(to: p(55, 14), control: p(49, 16))
            ctx.stroke(tuft, with: .color(slateMid), style: stroke(u, width: 2.8))

            // Rosy cheeks, expressive eyes, and sunny marigold diamond beak.
            drawCheeks(lx: 36, rx: 64, y: 50, radius: 4.0, in: &ctx, p: p, u: u)
            drawEye(cx: 40, cy: 44.5, rx: 2.9, ry: 3.3, anim: anim, in: &ctx, p: p, u: u)
            drawEye(cx: 60, cy: 44.5, rx: 2.9, ry: 3.3, anim: anim, in: &ctx, p: p, u: u)

            var beak = Path()
            beak.move(to: p(44.5, 48.5))
            beak.addQuadCurve(to: p(55.5, 48.5), control: p(50, 45))
            beak.addQuadCurve(to: p(50, 55.5), control: p(54, 53))
            beak.addQuadCurve(to: p(44.5, 48.5), control: p(46, 53))
            beak.closeSubpath()
            ctx.fill(beak, with: .color(marigold))
            ctx.stroke(beak, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.55))
        }
    }

    // MARK: 7. Clem — Nimble Rust-Vermilion Woodland Fox

    private static func drawFox(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let rustLight = Color(hex: 0xF79A63)
        let rustMid = Color(hex: 0xE26D3B)
        let rustDeep = Color(hex: 0xBA4B25)
        let sockDark = Color(hex: 0x35283B)
        let bob = CGFloat(anim.breath * 1.1)
        let brushSway = CGFloat(sin(anim.time * (2.2 + anim.joy * 6)) * (5 + anim.joy * 4))

        // Oversized plush brush tail curling behind & around the right flank!
        var tail = Path()
        tail.move(to: p(58, 78))
        tail.addCurve(to: p(88 + brushSway * 0.35, 50 + bob), control1: p(78, 82), control2: p(94 + brushSway * 0.3, 66))
        tail.addCurve(to: p(69 + brushSway * 0.25, 43 + bob), control1: p(84 + brushSway * 0.3, 41 + bob), control2: p(75 + brushSway * 0.25, 39 + bob))
        tail.addCurve(to: p(57, 68), control1: p(71, 54), control2: p(68, 66))
        tail.closeSubpath()
        context.fill(tail, with: .linearGradient(Gradient(colors: [rustLight, rustMid]), startPoint: p(86, 44), endPoint: p(60, 80)))
        // Fluffy cream-white tail tip!
        context.drawLayer { clipped in
            clipped.clip(to: tail)
            clipped.fill(oval(80 + brushSway * 0.3, 46 + bob, 13, 12, p: p, u: u), with: .color(cream))
        }
        context.stroke(tail, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.9))

        // Slim seated woodland fox torso.
        var torso = Path()
        torso.move(to: p(31, 82))
        torso.addCurve(to: p(35, 58 + bob), control1: p(29, 72), control2: p(31, 64 + bob))
        torso.addLine(to: p(61, 58 + bob))
        torso.addCurve(to: p(65, 82), control1: p(65, 64 + bob), control2: p(67, 72))
        torso.addQuadCurve(to: p(31, 82), control: p(48, 88))
        torso.closeSubpath()
        context.fill(torso, with: .linearGradient(Gradient(colors: [rustMid, rustDeep]), startPoint: p(48, 56), endPoint: p(48, 86)))
        context.drawLayer { clipped in
            clipped.clip(to: torso)
            clipped.fill(oval(48, 72, 10, 14, p: p, u: u), with: .color(cream))
        }
        context.stroke(torso, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.85))

        // Dark-stocking slender fox paws.
        for px in [CGFloat(41), 55] {
            let paw = Path(roundedRect: CGRect(x: p(px - 3.6, 73).x, y: p(px - 3.6, 73).y, width: 7.2 * u, height: 12 * u), cornerRadius: 3.5 * u)
            context.fill(paw, with: .color(sockDark))
            context.stroke(paw, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.5))
        }

        // Tall dramatic triangular fox ears with charcoal tips.
        var earL = Path()
        earL.move(to: p(28, 43 + bob))
        earL.addLine(to: p(22, 15 + bob))
        earL.addLine(to: p(43, 32 + bob))
        earL.closeSubpath()

        var earR = Path()
        earR.move(to: p(68, 43 + bob))
        earR.addLine(to: p(74, 15 + bob))
        earR.addLine(to: p(53, 32 + bob))
        earR.closeSubpath()

        for (ear, tipX) in [(earL, CGFloat(22)), (earR, CGFloat(74))] {
            context.fill(ear, with: .color(rustMid))
            context.drawLayer { clipped in
                clipped.clip(to: ear)
                clipped.fill(oval(tipX, 18 + bob, 9.5, 9.5, p: p, u: u), with: .color(sockDark))
            }
            context.stroke(ear, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.85))
        }

        // Distinct angular-fluffy fox head with flaring cream cheek ruffs!
        var head = Path()
        head.move(to: p(48, 29 + bob))
        head.addCurve(to: p(73, 47 + bob), control1: p(60, 29 + bob), control2: p(68, 38 + bob))
        head.addLine(to: p(68, 53 + bob))
        head.addQuadCurve(to: p(48, 63 + bob), control: p(60, 62 + bob))
        head.addQuadCurve(to: p(28, 53 + bob), control: p(36, 62 + bob))
        head.addLine(to: p(23, 47 + bob))
        head.addCurve(to: p(48, 29 + bob), control1: p(28, 38 + bob), control2: p(36, 29 + bob))
        head.closeSubpath()

        context.fill(head, with: .linearGradient(Gradient(colors: [rustLight, rustMid]), startPoint: p(48, 29), endPoint: p(48, 62)))
        context.drawLayer { clipped in
            clipped.clip(to: head)
            var cheekMask = Path()
            cheekMask.move(to: p(20, 48 + bob))
            cheekMask.addQuadCurve(to: p(48, 53 + bob), control: p(36, 46 + bob))
            cheekMask.addQuadCurve(to: p(76, 48 + bob), control: p(60, 46 + bob))
            cheekMask.addLine(to: p(76, 68 + bob))
            cheekMask.addLine(to: p(20, 68 + bob))
            cheekMask.closeSubpath()
            clipped.fill(cheekMask, with: .color(cream))
        }
        context.stroke(head, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.9))

        // Clever eyes, pointed dark nose & gentle fox smile.
        drawEye(cx: 38, cy: 46 + bob, rx: 2.8, ry: 3.1, anim: anim, in: &context, p: p, u: u)
        drawEye(cx: 58, cy: 46 + bob, rx: 2.8, ry: 3.1, anim: anim, in: &context, p: p, u: u)
        drawCheeks(lx: 33, rx: 63, y: 52 + bob, radius: 3.5, in: &context, p: p, u: u)
        let nose = oval(48, 55.5 + bob, 3.2, 2.3, p: p, u: u)
        context.fill(nose, with: .color(sockDark))
        var smile = Path()
        smile.move(to: p(43.5, 58.2 + bob))
        smile.addQuadCurve(to: p(52.5, 58.2 + bob), control: p(48, 61.2 + bob))
        context.stroke(smile, with: .color(ink), style: stroke(u, width: 1.55))
    }

    // MARK: 8. Sunny — Petite Butter-Ochre Songbird Chick

    private static func drawChick(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let butterLight = Color(hex: 0xFFF099)
        let butterMid = Color(hex: 0xFBD252)
        let butterDeep = Color(hex: 0xE5AA2E)
        let tangerine = Color(hex: 0xF2843A)
        let bounce = CGFloat(abs(sin(anim.time * (3.2 + anim.joy * 6))) * (2.6 + anim.joy * 3))
        let flutter = sin(anim.time * (4.6 + anim.joy * 12)) * (12 + anim.joy * 18)

        // Dainty slender stick-ink bird legs & tiny 3-toed feet!
        for lx in [CGFloat(43), 57] {
            var leg = Path()
            leg.move(to: p(lx, 72 - bounce * 0.5))
            leg.addLine(to: p(lx, 83.5))
            leg.move(to: p(lx - 4.5, 84.5))
            leg.addLine(to: p(lx, 83.5))
            leg.addLine(to: p(lx + 4.5, 84.5))
            leg.move(to: p(lx, 83.5))
            leg.addLine(to: p(lx, 86))
            context.stroke(leg, with: .color(tangerine), style: stroke(u, width: 2.6))
            context.stroke(leg, with: .color(ink.opacity(0.68)), style: stroke(u, width: 1.0))
        }

        // Perky scalloped fluttering mini wings on both sides!
        for side in [CGFloat(-1), 1] {
            context.drawLayer { wingCtx in
                let joint = p(50 + side * 21, 56 - bounce)
                wingCtx.translateBy(x: joint.x, y: joint.y)
                wingCtx.rotate(by: .degrees(Double(side) * (-18 + flutter)))
                var wing = Path()
                wing.move(to: .zero)
                wing.addCurve(
                    to: CGPoint(x: side * 12 * u, y: 7 * u),
                    control1: CGPoint(x: side * 11 * u, y: -5 * u),
                    control2: CGPoint(x: side * 15 * u, y: 2 * u)
                )
                wing.addQuadCurve(to: .zero, control: CGPoint(x: side * 5 * u, y: 11 * u))
                wing.closeSubpath()
                wingCtx.fill(wing, with: .color(butterMid))
                wingCtx.stroke(wing, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.75))
            }
        }

        // Wispy 3-feather songbird crown tuft!
        var tuft = Path()
        tuft.move(to: p(50, 32 - bounce))
        tuft.addQuadCurve(to: p(45, 20 - bounce), control: p(44, 26 - bounce))
        tuft.move(to: p(50, 32 - bounce))
        tuft.addQuadCurve(to: p(52, 18 - bounce), control: p(50, 23 - bounce))
        tuft.move(to: p(50, 32 - bounce))
        tuft.addQuadCurve(to: p(58, 22 - bounce), control: p(56, 26 - bounce))
        context.stroke(tuft, with: .color(butterDeep), style: stroke(u, width: 3.0))
        context.stroke(tuft, with: .color(ink.opacity(0.75)), style: stroke(u, width: 1.3))

        // Petite plump round songbird body.
        let body = oval(50, 54 - bounce, 22.5, 21.5, p: p, u: u)
        context.fill(body, with: .radialGradient(
            Gradient(colors: [butterLight, butterMid, butterDeep]),
            center: p(44, 46 - bounce),
            startRadius: 2 * u,
            endRadius: 26 * u
        ))
        context.drawLayer { clipped in
            clipped.clip(to: body)
            clipped.fill(oval(50, 64 - bounce, 14, 10, p: p, u: u), with: .color(Color(hex: 0xFFF8D6).opacity(0.72)))
        }
        context.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.9))

        // Rosy peach cheeks, bright eyes & tiny tangerine diamond beak.
        drawCheeks(lx: 35.5, rx: 64.5, y: 55.5 - bounce, radius: 3.8, color: Color(hex: 0xF78D78), in: &context, p: p, u: u)
        drawEye(cx: 40.5, cy: 49.5 - bounce, rx: 2.9, ry: 3.2, anim: anim, in: &context, p: p, u: u)
        drawEye(cx: 59.5, cy: 49.5 - bounce, rx: 2.9, ry: 3.2, anim: anim, in: &context, p: p, u: u)

        var beak = Path()
        beak.move(to: p(46, 53.5 - bounce))
        beak.addLine(to: p(50, 50.5 - bounce))
        beak.addLine(to: p(54, 53.5 - bounce))
        beak.addLine(to: p(50, 58 - bounce))
        beak.closeSubpath()
        context.fill(beak, with: .color(tangerine))
        context.stroke(beak, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.5))
    }

    // MARK: 9. Bao — Watercolor Ink-and-Cream Panda Cub with Bamboo Sprig

    private static func drawPanda(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let paper = Color(hex: 0xFAF5EC)
        let paperShade = Color(hex: 0xE9DFD0)
        let charcoal = Color(hex: 0x352C3E)
        let bamboo = Color(hex: 0x6DB578)
        let bambooLight = Color(hex: 0x9CD99C)
        let bob = CGFloat(anim.breath * 1.0)
        let munch = CGFloat(sin(anim.time * (3.5 + anim.joy * 6)) * 1.8)

        // Round smoky-charcoal panda ears.
        for ex in [CGFloat(29), 71] {
            let ear = oval(ex, 31 + bob, 9.5, 9.5, p: p, u: u)
            context.fill(ear, with: .color(charcoal))
            context.stroke(ear, with: .color(ink), style: stroke(u, width: 1.6))
        }

        // Chubby seated rice-paper panda body + head.
        var body = Path()
        body.move(to: p(24, 79))
        body.addCurve(to: p(25, 49 + bob), control1: p(19, 68), control2: p(21, 58 + bob))
        body.addCurve(to: p(50, 28 + bob), control1: p(27, 34 + bob), control2: p(37, 28 + bob))
        body.addCurve(to: p(75, 49 + bob), control1: p(63, 28 + bob), control2: p(73, 34 + bob))
        body.addCurve(to: p(76, 79), control1: p(79, 58 + bob), control2: p(81, 68))
        body.addQuadCurve(to: p(24, 79), control: p(50, 88))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [paper, paperShade]), startPoint: p(40, 28), endPoint: p(65, 86)))
        // Signature dark charcoal shoulder saddle band.
        context.drawLayer { clipped in
            clipped.clip(to: body)
            var saddle = Path()
            saddle.move(to: p(20, 62 + bob * 0.5))
            saddle.addQuadCurve(to: p(80, 62 + bob * 0.5), control: p(50, 69 + bob * 0.5))
            saddle.addLine(to: p(80, 74))
            saddle.addQuadCurve(to: p(20, 74), control: p(50, 79))
            saddle.closeSubpath()
            clipped.fill(saddle, with: .color(charcoal))
        }
        context.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u))

        // Chunky seated charcoal feet.
        for fx in [CGFloat(35), 65] {
            let foot = oval(fx, 81.5, 8.8, 5.8, p: p, u: u)
            context.fill(foot, with: .color(charcoal))
            context.stroke(foot, with: .color(ink), style: stroke(u, width: 1.6))
        }

        // Tilted charcoal eye patches with bright soulful eyes inside!
        for side in [CGFloat(-1), 1] {
            context.drawLayer { patchCtx in
                let c = p(50 + side * 12, 47.5 + bob)
                patchCtx.translateBy(x: c.x, y: c.y)
                patchCtx.rotate(by: .degrees(Double(side) * 18))
                let patch = Path(ellipseIn: CGRect(x: -7.5 * u, y: -5.8 * u, width: 15 * u, height: 11.6 * u))
                patchCtx.fill(patch, with: .color(charcoal))
            }
            if anim.isBeaming {
                var arc = Path()
                arc.move(to: p(50 + side * 12 - 3.6, 48 + bob))
                arc.addQuadCurve(to: p(50 + side * 12 + 3.6, 48 + bob), control: p(50 + side * 12, 43.5 + bob))
                context.stroke(arc, with: .color(cream), style: stroke(u, width: 2.0))
            } else if anim.blink >= 0.25 {
                let cx = 50 + side * 11.5
                let cy = 47 + bob
                context.fill(oval(cx, cy, 2.4, 2.7 * anim.blink, p: p, u: u), with: .color(cream))
                context.fill(oval(cx, cy, 1.3, 1.5 * anim.blink, p: p, u: u), with: .color(ink))
                context.fill(oval(cx - 0.6, cy - 0.8, 0.7, 0.7, p: p, u: u), with: .color(cream))
            }
        }

        drawCheeks(lx: 31, rx: 69, y: 54 + bob, radius: 4.0, in: &context, p: p, u: u)
        context.fill(oval(50, 52.5 + bob, 3.8, 2.6, p: p, u: u), with: .color(charcoal))
        var mouth = Path()
        mouth.move(to: p(46, 57 + bob))
        mouth.addQuadCurve(to: p(54, 57 + bob), control: p(50, 60.5 + bob))
        context.stroke(mouth, with: .color(ink), style: stroke(u, width: 1.6))

        // Slender fresh sage bamboo sprig with crisp warm-ink contour & veined leaves popping on parchment!
        var stalk = Path()
        stalk.move(to: p(56, 72 + munch * 0.4))
        stalk.addLine(to: p(79, 51 + munch))
        context.stroke(stalk, with: .color(ink.opacity(0.86)), style: stroke(u, width: 5.4))
        context.stroke(stalk, with: .color(bamboo), style: stroke(u, width: 3.1))
        // Crisp bamboo culm node joint ring.
        var node = Path()
        node.move(to: p(65.5, 60.5 + munch * 0.7))
        node.addLine(to: p(69.5, 64.5 + munch * 0.7))
        context.stroke(node, with: .color(ink.opacity(0.8)), style: stroke(u, width: 1.5))

        let bambooLeaves: [(CGFloat, CGFloat, Double)] = [
            (75, 54.5 + munch, -28.0),
            (80, 57.5 + munch, 18.0)
        ]
        for (lx, ly, ang) in bambooLeaves {
            context.drawLayer { leafCtx in
                let pt = p(lx, ly)
                leafCtx.translateBy(x: pt.x, y: pt.y)
                leafCtx.rotate(by: .degrees(ang))
                var leaf = Path()
                leaf.move(to: .zero)
                leaf.addQuadCurve(to: CGPoint(x: 11.5 * u, y: 0), control: CGPoint(x: 5.8 * u, y: -4.4 * u))
                leaf.addQuadCurve(to: .zero, control: CGPoint(x: 5.8 * u, y: 4.4 * u))
                leaf.closeSubpath()
                leafCtx.fill(leaf, with: .color(bambooLight))
                var midVein = Path()
                midVein.move(to: CGPoint(x: 1.6 * u, y: 0))
                midVein.addLine(to: CGPoint(x: 9.2 * u, y: 0))
                leafCtx.stroke(midVein, with: .color(Color(hex: 0x3D784B).opacity(0.75)), style: stroke(u, width: 1.0))
                leafCtx.stroke(leaf, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.65))
            }
        }

        // Little charcoal paw clutching the bamboo stalk.
        let paw = oval(61, 69 + munch * 0.4, 6.0, 4.6, p: p, u: u)
        context.fill(paw, with: .color(charcoal))
        context.stroke(paw, with: .color(ink), style: stroke(u, width: 1.5))
    }

    // MARK: 10. Stella — Graceful Pearl-Cream Miniature Storybook Kirin/Unicorn

    private static func drawUnicorn(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let pearlLight = Color(hex: 0xFFFDFB)
        let pearlMid = Color(hex: 0xF0E6F5)
        let hornGold = Color(hex: 0xF2C254)
        let maneLilac = Color(hex: 0xC6A6F5)
        let maneRose = Color(hex: 0xF7A4C8)
        let maneButter = Color(hex: 0xFCE18C)
        let bob = CGFloat(anim.breath * 1.1)
        let breeze = CGFloat(sin(anim.time * (2.6 + anim.joy * 6)) * (3.5 + anim.joy * 3))

        // Flowing pastel gouache tail sweeping gracefully behind the flank.
        var tail = Path()
        tail.move(to: p(70, 64))
        tail.addCurve(to: p(89 + breeze * 0.5, 58 + bob), control1: p(82, 54), control2: p(90 + breeze * 0.4, 52))
        tail.addCurve(to: p(76 + breeze * 0.4, 78), control1: p(92 + breeze * 0.5, 68), control2: p(84 + breeze * 0.3, 76))
        tail.closeSubpath()
        context.fill(tail, with: .linearGradient(Gradient(colors: [maneLilac, maneRose, maneButter]), startPoint: p(72, 56), endPoint: p(88, 78)))
        context.stroke(tail, with: .color(ink.opacity(0.8)), style: stroke(u, width: 1.75))

        // Delicate 3/4 seated pony legs with tiny brushed-brass hooves.
        for lx in [CGFloat(36), 49, 63] {
            let leg = Path(roundedRect: CGRect(x: p(lx - 3.6, 68).x, y: p(lx - 3.6, 68).y, width: 7.2 * u, height: 17 * u), cornerRadius: 3.4 * u)
            context.fill(leg, with: .color(pearlMid))
            context.stroke(leg, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.6))
            let hoof = Path(roundedRect: CGRect(x: p(lx - 3.6, 80.5).x, y: p(lx - 3.6, 80.5).y, width: 7.2 * u, height: 4.8 * u), cornerRadius: 2.0 * u)
            context.fill(hoof, with: .color(hornGold))
            context.stroke(hoof, with: .color(ink.opacity(0.76)), style: stroke(u, width: 1.3))
        }

        // Slender arched storybook pony body, neck & delicate muzzle!
        var body = Path()
        body.move(to: p(35, 72))
        body.addCurve(to: p(34, 47 + bob), control1: p(32, 62), control2: p(32, 53 + bob))
        // Delicate pony muzzle pointing slightly left-forward.
        body.addCurve(to: p(21, 43 + bob), control1: p(27, 47 + bob), control2: p(21, 47 + bob))
        body.addCurve(to: p(32, 30 + bob), control1: p(20, 36 + bob), control2: p(26, 31 + bob))
        body.addCurve(to: p(52, 34 + bob), control1: p(39, 27 + bob), control2: p(48, 28 + bob))
        body.addCurve(to: p(54, 54), control1: p(55, 41 + bob), control2: p(55, 48))
        body.addCurve(to: p(74, 65), control1: p(64, 54), control2: p(74, 57))
        body.addCurve(to: p(66, 76), control1: p(75, 72), control2: p(72, 76))
        body.addQuadCurve(to: p(35, 72), control: p(50, 78))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [pearlLight, pearlMid]), startPoint: p(28, 30), endPoint: p(72, 76)))
        context.stroke(body, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.85))

        // Flowing pastel gouache mane cascading down the arched neck.
        var mane = Path()
        mane.move(to: p(43, 27 + bob))
        mane.addCurve(to: p(60 + breeze * 0.3, 45 + bob), control1: p(54, 27 + bob), control2: p(62 + breeze * 0.3, 35 + bob))
        mane.addCurve(to: p(52, 54), control1: p(60 + breeze * 0.2, 51), control2: p(56, 54))
        mane.addCurve(to: p(45, 36 + bob), control1: p(50, 46), control2: p(49, 39 + bob))
        mane.closeSubpath()
        context.fill(mane, with: .linearGradient(Gradient(colors: [maneRose, maneLilac]), startPoint: p(44, 27), endPoint: p(58, 54)))
        context.stroke(mane, with: .color(ink.opacity(0.78)), style: stroke(u, width: 1.6))

        // Perky pony ear & spiraled brushed-brass alicorn horn!
        var ear = Path()
        ear.move(to: p(41, 29 + bob))
        ear.addLine(to: p(45, 19 + bob))
        ear.addLine(to: p(49, 29 + bob))
        ear.closeSubpath()
        context.fill(ear, with: .color(pearlLight))
        context.stroke(ear, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.65))

        var horn = Path()
        horn.move(to: p(32, 30 + bob))
        horn.addLine(to: p(24, 11 + bob))
        horn.addLine(to: p(38, 28 + bob))
        horn.closeSubpath()
        context.fill(horn, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE898), hornGold]), startPoint: p(24, 11), endPoint: p(36, 30)))
        context.stroke(horn, with: .color(ink.opacity(0.82)), style: stroke(u, width: 1.65))
        // Spiraled horn grooves.
        for step in [CGFloat(0.35), 0.65] {
            var groove = Path()
            groove.move(to: p(32 - 8 * step, 30 - 19 * step + bob))
            groove.addLine(to: p(38 - 14 * step, 28 - 17 * step + bob))
            context.stroke(groove, with: .color(Color(hex: 0xB8801C).opacity(0.72)), style: stroke(u, width: 1.25))
        }

        // Folded little pearl star-wing fluttering gently on the flank!
        context.drawLayer { wingCtx in
            let anchor = p(53, 59)
            wingCtx.translateBy(x: anchor.x, y: anchor.y)
            wingCtx.rotate(by: .degrees(-10 + sin(anim.time * (3.2 + anim.joy * 8)) * (6 + anim.joy * 10)))
            var wing = Path()
            wing.move(to: .zero)
            wing.addCurve(to: CGPoint(x: 17 * u, y: -6 * u), control1: CGPoint(x: 7 * u, y: -11 * u), control2: CGPoint(x: 15 * u, y: -11 * u))
            wing.addCurve(to: CGPoint(x: 12 * u, y: 5 * u), control1: CGPoint(x: 18 * u, y: 0), control2: CGPoint(x: 15 * u, y: 4 * u))
            wing.addQuadCurve(to: .zero, control: CGPoint(x: 6 * u, y: 6 * u))
            wing.closeSubpath()
            wingCtx.fill(wing, with: .color(cream))
            wingCtx.stroke(wing, with: .color(ink.opacity(0.76)), style: stroke(u, width: 1.5))
        }

        // Gentle pony eye, rosy cheek & tiny smiling muzzle.
        drawEye(cx: 35.5, cy: 38.5 + bob, rx: 2.7, ry: 3.1, anim: anim, in: &context, p: p, u: u)
        context.fill(oval(33, 43.5 + bob, 3.6, 2.3, p: p, u: u), with: .color(blush.opacity(0.58)))
        var smile = Path()
        smile.move(to: p(23, 43.5 + bob))
        smile.addQuadCurve(to: p(28.5, 43.5 + bob), control: p(26, 46 + bob))
        context.stroke(smile, with: .color(ink), style: stroke(u, width: 1.5))
    }

    // MARK: 11. Sprout — Sage-Moss Baby Stegosaurus

    private static func drawDino(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let sageLight = Color(hex: 0xB8E09F)
        let sageMid = Color(hex: 0x7EBA70)
        let sageDeep = Color(hex: 0x558E52)
        let bellyCream = Color(hex: 0xF7F1D5)
        let plateCoral = Color(hex: 0xE87A64)
        let plateLight = Color(hex: 0xF7A68E)
        let bob = CGFloat(anim.breath * 1.1)
        let wag = CGFloat(sin(anim.time * (3.0 + anim.joy * 7)) * (4.5 + anim.joy * 4))

        // Five signature terracotta-coral scalloped dorsal plates marching down crown, back & tail!
        let plates: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (46, 29 + bob, 6.2, -16),
            (55, 36 + bob, 6.8, 12),
            (63, 47 + bob * 0.7, 7.2, 34),
            (70, 58 + wag * 0.25, 6.4, 48),
            (78, 66 + wag * 0.55, 5.2, 26)
        ]
        for plate in plates {
            context.drawLayer { pCtx in
                let c = p(plate.0, plate.1)
                pCtx.translateBy(x: c.x, y: c.y)
                pCtx.rotate(by: .degrees(plate.3))
                var fin = Path()
                let r = plate.2 * u
                fin.move(to: CGPoint(x: -r * 0.8, y: r * 0.5))
                fin.addQuadCurve(to: CGPoint(x: 0, y: -r), control: CGPoint(x: -r * 0.7, y: -r * 0.6))
                fin.addQuadCurve(to: CGPoint(x: r * 0.8, y: r * 0.5), control: CGPoint(x: r * 0.7, y: -r * 0.6))
                fin.closeSubpath()
                pCtx.fill(fin, with: .linearGradient(Gradient(colors: [plateLight, plateCoral]), startPoint: CGPoint(x: 0, y: -r), endPoint: CGPoint(x: 0, y: r)))
                pCtx.stroke(fin, with: .color(ink.opacity(0.8)), style: stroke(u, width: 1.55))
            }
        }

        // Chunky baby stegosaurus silhouette: sweet protruding snout + plump body + wagging tail!
        var body = Path()
        body.move(to: p(28, 79))
        body.addCurve(to: p(28, 53 + bob), control1: p(24, 68), control2: p(25, 60 + bob))
        // Protruding dino snout to the left.
        body.addCurve(to: p(17, 46 + bob), control1: p(21, 52 + bob), control2: p(16, 51 + bob))
        body.addCurve(to: p(34, 31 + bob), control1: p(18, 36 + bob), control2: p(25, 31 + bob))
        body.addCurve(to: p(56, 44 + bob), control1: p(46, 30 + bob), control2: p(54, 36 + bob))
        body.addCurve(to: p(70, 66), control1: p(62, 53), control2: p(66, 61))
        // Wagging curved tail tip on right.
        body.addQuadCurve(to: p(87, 68 + wag), control: p(79, 64 + wag * 0.5))
        body.addQuadCurve(to: p(66, 80), control: p(78, 79 + wag * 0.4))
        body.addQuadCurve(to: p(28, 79), control: p(46, 86))
        body.closeSubpath()

        context.fill(body, with: .linearGradient(Gradient(colors: [sageLight, sageMid, sageDeep]), startPoint: p(34, 30), endPoint: p(72, 84)))

        // Cream ridged belly patch.
        context.drawLayer { clipped in
            clipped.clip(to: body)
            clipped.fill(oval(39, 71, 14, 15, p: p, u: u), with: .color(bellyCream))
            for ry in [CGFloat(64), 70, 76] {
                var ridge = Path()
                ridge.move(to: p(27, ry))
                ridge.addQuadCurve(to: p(51, ry), control: p(39, ry + 2.2))
                clipped.stroke(ridge, with: .color(Color(hex: 0xD8CFA8)), style: stroke(u, width: 1.3))
            }
        }
        context.stroke(body, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.9))

        // Sturdy stubby dino feet + tiny arm.
        for fx in [CGFloat(36), 58] {
            let foot = oval(fx, 81.5, 8.2, 5.2, p: p, u: u)
            context.fill(foot, with: .color(sageMid))
            context.stroke(foot, with: .color(ink.opacity(0.84)), style: stroke(u, width: 1.7))
        }
        let arm = oval(36, 63 + bob * 0.6, 5.2, 3.6, p: p, u: u)
        context.fill(arm, with: .color(sageLight))
        context.stroke(arm, with: .color(ink.opacity(0.78)), style: stroke(u, width: 1.5))

        // Organic sage-olive hip freckles.
        for dot in [(CGFloat(56), CGFloat(64)), (61, 68), (58, 72)] {
            context.fill(oval(dot.0, dot.1, 2.0, 1.8, p: p, u: u), with: .color(sageDeep.opacity(0.55)))
        }

        // Bright dino eye, rosy cheek & happy snout smile.
        drawEye(cx: 35.5, cy: 41.5 + bob, rx: 3.1, ry: 3.4, anim: anim, in: &context, p: p, u: u)
        context.fill(oval(40, 47 + bob, 4.0, 2.6, p: p, u: u), with: .color(blush.opacity(0.55)))
        var smile = Path()
        smile.move(to: p(19.5, 47 + bob))
        smile.addQuadCurve(to: p(31.5, 48 + bob), control: p(25.5, 51 + bob))
        context.stroke(smile, with: .color(ink), style: stroke(u, width: 1.7))
    }

    // MARK: 12. Inky — Whimsical Plum-Indigo Coastal Octopus

    private static func drawOctopus(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        anim: FriendAnim
    ) {
        let plumLight = Color(hex: 0xC4B2F2)
        let plumMid = Color(hex: 0x9174D4)
        let plumDeep = Color(hex: 0x674DA8)
        let suction = Color(hex: 0xEDE4FC)
        let floatY = CGFloat(sin(anim.time * 2.3) * 2.2)

        // Six playfully curling radiating tentacles waving with staggered traveling sine phases!
        let legs: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (32, 13, 74, 0.0),
            (38, 22, 82, 0.9),
            (45, 39, 84, 1.8),
            (55, 61, 84, 2.6),
            (62, 78, 82, 3.4),
            (68, 87, 74, 4.2)
        ]

        for (idx, leg) in legs.enumerated() {
            let wave = CGFloat(sin(anim.time * (3.0 + anim.joy * 7) + leg.3) * (3.6 + anim.joy * 3))
            let start = p(leg.0, 63 + floatY)
            let midX = (leg.0 + leg.1) * 0.5 + (idx < 3 ? -3 : 3)
            let mid = p(midX, 76 + floatY * 0.4 + wave * 0.4)
            let tip = p(leg.1 + wave * 0.4, leg.2 + wave * 0.55)

            var tentacle = Path()
            tentacle.move(to: start)
            tentacle.addQuadCurve(to: tip, control: mid)

            // Outer ink contour, rich plum body, and delicate pale underside suction dots!
            context.stroke(tentacle, with: .color(ink.opacity(0.86)), style: stroke(u, width: 10.6))
            context.stroke(tentacle, with: .color(idx.isMultiple(of: 2) ? plumMid : plumDeep), style: stroke(u, width: 7.2))

            // Pale lavender suction dots near the curling tip.
            let dotPos = CGPoint(x: (mid.x + tip.x) * 0.5, y: (mid.y + tip.y) * 0.5 + 1.2 * u)
            context.fill(
                Path(ellipseIn: CGRect(x: dotPos.x - 1.8 * u, y: dotPos.y - 1.5 * u, width: 3.6 * u, height: 3.0 * u)),
                with: .color(suction.opacity(0.92))
            )
        }

        // High domed scalloped cephalopod mantle!
        var dome = Path()
        dome.move(to: p(26, 56 + floatY))
        dome.addCurve(to: p(50, 19 + floatY), control1: p(22, 35 + floatY), control2: p(34, 19 + floatY))
        dome.addCurve(to: p(74, 56 + floatY), control1: p(66, 19 + floatY), control2: p(78, 35 + floatY))
        dome.addCurve(to: p(50, 68 + floatY), control1: p(72, 65 + floatY), control2: p(62, 68 + floatY))
        dome.addCurve(to: p(26, 56 + floatY), control1: p(38, 68 + floatY), control2: p(28, 65 + floatY))
        dome.closeSubpath()

        context.fill(dome, with: .radialGradient(
            Gradient(colors: [plumLight, plumMid, plumDeep]),
            center: p(42, 33 + floatY),
            startRadius: 3 * u,
            endRadius: 34 * u
        ))

        // Subtle watercolor coastal mantle spots on the crown.
        context.fill(oval(39, 31 + floatY, 4.5, 3.2, p: p, u: u), with: .color(suction.opacity(0.45)))
        context.fill(oval(60, 34 + floatY, 3.2, 2.6, p: p, u: u), with: .color(suction.opacity(0.38)))
        context.stroke(dome, with: .color(ink.opacity(0.86)), style: stroke(u, width: 1.9))

        // Low-set expressive eyes, rosy blush washes & sweet curled 'o' mouth!
        drawCheeks(lx: 33, rx: 67, y: 55 + floatY, radius: 4.2, color: Color(hex: 0xF78BA8), in: &context, p: p, u: u)
        drawEye(cx: 40, cy: 49.5 + floatY, rx: 3.1, ry: 3.6, anim: anim, in: &context, p: p, u: u)
        drawEye(cx: 60, cy: 49.5 + floatY, rx: 3.1, ry: 3.6, anim: anim, in: &context, p: p, u: u)

        if anim.isBeaming {
            var smile = Path()
            smile.move(to: p(45.5, 55.5 + floatY))
            smile.addQuadCurve(to: p(54.5, 55.5 + floatY), control: p(50, 60.5 + floatY))
            context.stroke(smile, with: .color(ink), style: stroke(u, width: 1.9))
        } else {
            let mouth = oval(50, 56.5 + floatY, 2.8, 2.5, p: p, u: u)
            context.fill(mouth, with: .color(Color(hex: 0x5C2C4D)))
            context.stroke(mouth, with: .color(ink), style: stroke(u, width: 1.4))
        }
    }
}
