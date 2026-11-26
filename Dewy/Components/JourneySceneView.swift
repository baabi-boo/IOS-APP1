import SwiftUI

// MARK: - Deterministic Noise Helper

private func journeyFract(_ value: Double) -> Double {
    value - floor(value)
}

private func journeyNoise(_ seed: Double, _ salt: Double) -> Double {
    journeyFract(sin(seed * 12.9898 + salt * 78.233) * 43_758.5453)
}

// MARK: - Journey Scene View (8 Lush Museum-Grade Storybook Panoramas)

/// Full-bleed animated Monument Valley × Studio Ghibli × Alto's Odyssey panorama
/// for each of Dewy's eight journey chapters, with serene top-sky breathing room
/// for chapter typography and a grounded foreground ledge (`y ~ 0.77`) for Dewy.
struct JourneySceneView: View {
    var chapter: Chapter
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Group {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
                        let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : 14.2
                        composedChapter(size: size, time: t)
                    }
                } else {
                    composedChapter(size: size, time: 14.2)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }

    private func composedChapter(size: CGSize, time t: Double) -> some View {
        let waterBand = chapterWaterBand(chapter, size: size)

        return ZStack(alignment: .topLeading) {
            Canvas { context, s in
                drawChapterBackdrop(in: &context, chapter: chapter, size: s, time: t)
            }
            .gouacheBloom(0.032)

            if let band = waterBand {
                Canvas { context, s in
                    drawChapterWater(
                        in: &context,
                        chapter: chapter,
                        fullSize: size,
                        bandSize: s,
                        time: t
                    )
                }
                .frame(width: size.width, height: band.height)
                .pondCaustics(time: t, tint: band.causticTint, strength: band.causticStrength)
                .offset(y: band.top)
            }

            Canvas { context, s in
                drawChapterForeground(in: &context, chapter: chapter, size: s, time: t)
            }
        }
        .paperGrain(0.026)
    }
}

private struct WaterBandSpec {
    var top: CGFloat
    var height: CGFloat
    var causticTint: Color
    var causticStrength: Double
}

private func chapterWaterBand(_ chapter: Chapter, size: CGSize) -> WaterBandSpec? {
    let h = max(size.height, 1)
    switch chapter {
    case .spring:
        return WaterBandSpec(top: h * 0.555, height: h * 0.215, causticTint: Color(hex: 0xD8FFF5), causticStrength: 0.19)
    case .brook:
        return WaterBandSpec(top: h * 0.515, height: h * 0.265, causticTint: Color(hex: 0xE6FDFF), causticStrength: 0.18)
    case .meadow:
        return WaterBandSpec(top: h * 0.525, height: h * 0.245, causticTint: Color(hex: 0xECFFE6), causticStrength: 0.16)
    case .falls:
        return WaterBandSpec(top: h * 0.605, height: h * 0.175, causticTint: Color(hex: 0xE2F8FF), causticStrength: 0.20)
    case .cove:
        return WaterBandSpec(top: h * 0.51, height: h * 0.25, causticTint: Color(hex: 0xFFF3E2), causticStrength: 0.18)
    case .lake:
        return WaterBandSpec(top: h * 0.55, height: h * 0.22, causticTint: Color(hex: 0xC4D2FF), causticStrength: 0.13)
    case .peak, .grove:
        return nil
    }
}

// MARK: - Chapter Dispatch

private func drawChapterBackdrop(in context: inout GraphicsContext, chapter: Chapter, size: CGSize, time t: Double) {
    switch chapter {
    case .spring: drawSpringBackdrop(in: &context, size: size, time: t)
    case .brook: drawBrookBackdrop(in: &context, size: size, time: t)
    case .meadow: drawMeadowBackdrop(in: &context, size: size, time: t)
    case .falls: drawFallsBackdrop(in: &context, size: size, time: t)
    case .cove: drawCoveBackdrop(in: &context, size: size, time: t)
    case .peak: drawPeakBackdrop(in: &context, size: size, time: t)
    case .grove: drawGroveBackdrop(in: &context, size: size, time: t)
    case .lake: drawLakeBackdrop(in: &context, size: size, time: t)
    }
}

private func drawChapterWater(
    in context: inout GraphicsContext,
    chapter: Chapter,
    fullSize: CGSize,
    bandSize: CGSize,
    time t: Double
) {
    switch chapter {
    case .spring: drawSpringWater(in: &context, size: bandSize, time: t)
    case .brook: drawBrookWater(in: &context, size: bandSize, time: t)
    case .meadow: drawMeadowWater(in: &context, size: bandSize, time: t)
    case .falls: drawFallsWater(in: &context, size: bandSize, time: t)
    case .cove: drawCoveWater(in: &context, size: bandSize, time: t)
    case .lake: drawLakeWater(in: &context, fullSize: fullSize, bandSize: bandSize, time: t)
    case .peak, .grove: break
    }
}

private func drawChapterForeground(in context: inout GraphicsContext, chapter: Chapter, size: CGSize, time t: Double) {
    switch chapter {
    case .spring: drawSpringForeground(in: &context, size: size, time: t)
    case .brook: drawBrookForeground(in: &context, size: size, time: t)
    case .meadow: drawMeadowForeground(in: &context, size: size, time: t)
    case .falls: drawFallsForeground(in: &context, size: size, time: t)
    case .cove: drawCoveForeground(in: &context, size: size, time: t)
    case .peak: drawPeakForeground(in: &context, size: size, time: t)
    case .grove: drawGroveForeground(in: &context, size: size, time: t)
    case .lake: drawLakeForeground(in: &context, size: size, time: t)
    }
}

// MARK: - Shared Storybook Drawing Primitives

private func fillVerticalSky(in context: inout GraphicsContext, size: CGSize, colors: [Color]) {
    let rect = CGRect(origin: .zero, size: size)
    context.fill(
        Path(rect),
        with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
    )
}

/// Organic curved water shoreline with painterly foam/glint lip (zero straight horizontal cuts).
private func drawCurvedWaterBody(
    in context: inout GraphicsContext,
    size: CGSize,
    topOffset: CGFloat = 9,
    curveAmp: CGFloat = 4.5,
    waveAmp: CGFloat = 1.5,
    colors: [Color],
    lipColor: Color,
    lipWidth: CGFloat = 2.4,
    time t: Double
) {
    let w = max(size.width, 1)
    let h = size.height

    func shoreY(_ x: CGFloat) -> CGFloat {
        let u = Double(x / w)
        let cove = curveAmp * CGFloat(sin(u * Double.pi))
        let ripple = waveAmp * CGFloat(sin(u * Double.pi * 3.0 + t * 0.55))
        return max(topOffset - cove + ripple, 2)
    }

    var body = Path()
    var lip = Path()
    let start = CGPoint(x: 0, y: shoreY(0))
    body.move(to: start)
    lip.move(to: start)

    var x: CGFloat = 8
    while x <= w + 8 {
        let pt = CGPoint(x: min(x, w), y: shoreY(min(x, w)))
        body.addLine(to: pt)
        lip.addLine(to: pt)
        x += 8
    }
    body.addLine(to: CGPoint(x: w, y: h))
    body.addLine(to: CGPoint(x: 0, y: h))
    body.closeSubpath()

    context.fill(
        body,
        with: .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: 0, y: topOffset * 0.5), endPoint: CGPoint(x: 0, y: h))
    )
    context.stroke(lip, with: .color(lipColor), style: StrokeStyle(lineWidth: lipWidth, lineCap: .round, lineJoin: .round))
}

/// Warm-rimmed Studio Ghibli cumulus cloud with sunlit crown highlight and soft belly shadow.
private func drawGhibliCloud(
    in context: inout GraphicsContext,
    center: CGPoint,
    width: CGFloat,
    lit: Color,
    rim: Color,
    shade: Color,
    alpha: Double
) {
    let h = width * 0.36
    let left = center.x - width * 0.5
    let baseY = center.y + h * 0.35

    var path = Path()
    path.move(to: CGPoint(x: left + width * 0.06, y: baseY))
    path.addQuadCurve(to: CGPoint(x: left + width * 0.24, y: baseY - h * 0.62), control: CGPoint(x: left - width * 0.03, y: baseY - h * 0.44))
    path.addCurve(
        to: CGPoint(x: left + width * 0.56, y: baseY - h * 0.96),
        control1: CGPoint(x: left + width * 0.30, y: baseY - h * 1.15),
        control2: CGPoint(x: left + width * 0.50, y: baseY - h * 1.16)
    )
    path.addCurve(
        to: CGPoint(x: left + width * 0.84, y: baseY - h * 0.52),
        control1: CGPoint(x: left + width * 0.68, y: baseY - h * 1.02),
        control2: CGPoint(x: left + width * 0.84, y: baseY - h * 0.80)
    )
    path.addQuadCurve(to: CGPoint(x: left + width * 0.94, y: baseY), control: CGPoint(x: left + width * 1.04, y: baseY - h * 0.24))
    path.closeSubpath()

    context.drawLayer { layer in
        layer.opacity = alpha
        let grad = Gradient(stops: [
            .init(color: rim, location: 0.0),
            .init(color: lit, location: 0.38),
            .init(color: shade, location: 1.0)
        ])
        layer.fill(
            path,
            with: .linearGradient(grad, startPoint: CGPoint(x: center.x, y: baseY - h), endPoint: CGPoint(x: center.x, y: baseY))
        )
        layer.stroke(path, with: .color(rim.opacity(0.75)), lineWidth: 1.2)
    }
}

/// Alto's Odyssey sweeping curved-slope faceted alpine peak with sunlit and shaded faces.
private func drawFacetedPeak(
    in context: inout GraphicsContext,
    apex: CGPoint,
    leftFoot: CGPoint,
    rightFoot: CGPoint,
    litColor: Color,
    shadowColor: Color,
    ridgeGlow: Color
) {
    let ridgeMidX = apex.x + (rightFoot.x - leftFoot.x) * 0.04
    let ridgeMidY = (apex.y + leftFoot.y) * 0.56
    let ridgeBase = CGPoint(x: apex.x - (rightFoot.x - leftFoot.x) * 0.06, y: max(leftFoot.y, rightFoot.y))

    // Left sunlit sweeping alpine face.
    var litFace = Path()
    litFace.move(to: apex)
    litFace.addQuadCurve(to: leftFoot, control: CGPoint(x: (apex.x + leftFoot.x) * 0.52, y: apex.y + (leftFoot.y - apex.y) * 0.64))
    litFace.addLine(to: ridgeBase)
    litFace.addQuadCurve(to: apex, control: CGPoint(x: ridgeMidX, y: ridgeMidY))
    litFace.closeSubpath()
    context.fill(litFace, with: .color(litColor))

    // Right cool-violet shadow alpine face.
    var darkFace = Path()
    darkFace.move(to: apex)
    darkFace.addQuadCurve(to: ridgeBase, control: CGPoint(x: ridgeMidX, y: ridgeMidY))
    darkFace.addLine(to: rightFoot)
    darkFace.addQuadCurve(to: apex, control: CGPoint(x: (apex.x + rightFoot.x) * 0.48, y: apex.y + (rightFoot.y - apex.y) * 0.60))
    darkFace.closeSubpath()
    context.fill(darkFace, with: .color(shadowColor))

    // Subtle glowing sunlit crest line.
    var ridge = Path()
    ridge.move(to: leftFoot)
    ridge.addQuadCurve(to: apex, control: CGPoint(x: (apex.x + leftFoot.x) * 0.52, y: apex.y + (leftFoot.y - apex.y) * 0.64))
    context.stroke(ridge, with: .color(ridgeGlow.opacity(0.65)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
}

/// Stacked sculpted granite boulder with sunlit shoulder, cool crevice and moss cap.
private func drawSculptedBoulder(
    in context: inout GraphicsContext,
    rect: CGRect,
    stoneLit: Color,
    stoneDark: Color,
    mossLit: Color,
    mossDark: Color
) {
    let body = Path(roundedRect: rect, cornerRadius: rect.height * 0.46)
    let grad = Gradient(colors: [stoneLit, stoneDark])
    context.fill(body, with: .linearGradient(grad, startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))

    // Soft warm stone shoulder highlight.
    let sheen = CGRect(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.18, width: rect.width * 0.44, height: rect.height * 0.24)
    context.fill(Path(ellipseIn: sheen), with: .color(Color(hex: 0xFFFDF5).opacity(0.22)))

    // Lush two-tone overhanging moss cushion.
    let mossBase = CGRect(x: rect.minX + rect.width * 0.06, y: rect.minY - 2, width: rect.width * 0.86, height: rect.height * 0.42)
    context.fill(Path(ellipseIn: mossBase), with: .color(mossDark))
    let mossCrown = CGRect(x: rect.minX + rect.width * 0.14, y: rect.minY - 2, width: rect.width * 0.62, height: rect.height * 0.26)
    context.fill(Path(ellipseIn: mossCrown), with: .color(mossLit))
}

/// Curved botanical fern frond with paired leaflets.
private func drawFernFrond(
    in context: inout GraphicsContext,
    base: CGPoint,
    length: CGFloat,
    angle: Double,
    curl: Double,
    color: Color
) {
    let segments = 8
    var stem = Path()
    stem.move(to: base)
    var pts: [CGPoint] = [base]
    var curAngle = angle
    var cur = base
    let step = length / CGFloat(segments)

    for _ in 0..<segments {
        curAngle += curl
        let next = CGPoint(x: cur.x + CGFloat(cos(curAngle)) * step, y: cur.y + CGFloat(sin(curAngle)) * step)
        stem.addLine(to: next)
        pts.append(next)
        cur = next
    }
    context.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

    for i in 1..<pts.count {
        let frac = 1.0 - CGFloat(i) / CGFloat(pts.count + 1)
        let leafLen = length * 0.26 * frac
        let p = pts[i]
        let a = angle + curl * Double(i)
        for side in [-1.0, 1.0] {
            let la = a + side * 0.92
            let tip = CGPoint(x: p.x + CGFloat(cos(la)) * leafLen, y: p.y + CGFloat(sin(la)) * leafLen)
            let midX = (p.x + tip.x) * 0.5
            let midY = (p.y + tip.y) * 0.5
            let nx = -CGFloat(sin(la)) * 4.8 * frac
            let ny = CGFloat(cos(la)) * 4.8 * frac
            var leaflet = Path()
            leaflet.move(to: p)
            leaflet.addQuadCurve(to: tip, control: CGPoint(x: midX + nx, y: midY + ny))
            leaflet.addQuadCurve(to: p, control: CGPoint(x: midX - nx, y: midY - ny))
            leaflet.closeSubpath()
            context.fill(leaflet, with: .color(color))
        }
    }
}

/// Graceful swaying shoreline cattail & reed cluster.
private func drawCattailReed(
    in context: inout GraphicsContext,
    base: CGPoint,
    height: CGFloat,
    lean: CGFloat,
    stemColor: Color,
    headColor: Color?
) {
    let tip = CGPoint(x: base.x + lean, y: base.y - height)
    let ctrl = CGPoint(x: base.x + lean * 0.32, y: base.y - height * 0.55)
    var stem = Path()
    stem.move(to: base)
    stem.addQuadCurve(to: tip, control: ctrl)
    context.stroke(stem, with: .color(stemColor), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

    if let headColor {
        let head = CGRect(x: tip.x - 3.2, y: tip.y - 2, width: 6.4, height: 15)
        context.fill(Path(roundedRect: head, cornerRadius: 3.2), with: .color(headColor))
    }
}

/// Delicate hanging weeping-willow vine with paired leaf droplets.
private func drawWillowVine(
    in context: inout GraphicsContext,
    top: CGPoint,
    drop: CGFloat,
    sway: CGFloat,
    stemColor: Color,
    leafColor: Color
) {
    let bottom = CGPoint(x: top.x + sway, y: top.y + drop)
    let ctrl = CGPoint(x: top.x + sway * 0.35, y: top.y + drop * 0.52)
    var vine = Path()
    vine.move(to: top)
    vine.addQuadCurve(to: bottom, control: ctrl)
    context.stroke(vine, with: .color(stemColor), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

    let leafCount = 7
    for i in 1...leafCount {
        let u = CGFloat(i) / CGFloat(leafCount)
        let inv = 1.0 - u
        let px = inv * inv * top.x + 2 * inv * u * ctrl.x + u * u * bottom.x
        let py = inv * inv * top.y + 2 * inv * u * ctrl.y + u * u * bottom.y
        let side: CGFloat = i.isMultiple(of: 2) ? 1 : -1
        let leafRect = CGRect(x: px + side * 1.5 - 2.6, y: py - 1, width: 5.2, height: 9.5)
        context.fill(Path(ellipseIn: leafRect), with: .color(leafColor))
    }
}

/// Sculpted multi-petal pink-and-cream lotus blossom resting on a veined notched lily pad.
private func drawGouacheLotusPad(
    in context: inout GraphicsContext,
    center: CGPoint,
    rx: CGFloat,
    bloom: Bool,
    padLight: Color,
    padDeep: Color
) {
    let ry = rx * 0.34
    let rip = CGRect(x: center.x - rx * 1.24, y: center.y - ry * 1.24, width: rx * 2.48, height: ry * 2.48)
    context.stroke(Path(ellipseIn: rip), with: .color(.white.opacity(0.36)), lineWidth: 1.2)

    // Notched pad silhouette.
    var pad = Path()
    pad.move(to: CGPoint(x: center.x + rx * 0.22, y: center.y + ry * 0.12))
    let steps = 36
    let startA = 0.45
    let endA = 0.22 + Double.pi * 2.0
    for i in 0...steps {
        let a = startA + (endA - startA) * (Double(i) / Double(steps))
        pad.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * rx, y: center.y + CGFloat(sin(a)) * ry))
    }
    pad.closeSubpath()

    let padGrad = Gradient(colors: [padLight, padDeep])
    context.fill(pad, with: .radialGradient(padGrad, center: CGPoint(x: center.x - rx * 0.2, y: center.y - ry * 0.2), startRadius: 2, endRadius: rx))
    context.stroke(pad, with: .color(padDeep.opacity(0.55)), lineWidth: 0.9)

    // Delicate radial leaf veins.
    for a in [1.4, 2.3, 3.2, 4.2, 5.2] {
        var v = Path()
        v.move(to: center)
        v.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * rx * 0.78, y: center.y + CGFloat(sin(a)) * ry * 0.78))
        context.stroke(v, with: .color(Color(hex: 0xEAFFD4).opacity(0.45)), lineWidth: 0.85)
    }

    guard bloom else { return }
    let petals: [(dx: CGFloat, h: CGFloat, w: CGFloat, col: Color)] = [
        (-8, 12, 7.5, Color(hex: 0xFF9AC2)), (8, 12, 7.5, Color(hex: 0xFF9AC2)),
        (-4, 15, 8.0, Color(hex: 0xFFC2DA)), (4, 15, 8.0, Color(hex: 0xFFC2DA)),
        (0, 16, 8.5, Color(hex: 0xFFF3F8))
    ]
    for p in petals {
        let rect = CGRect(x: center.x + p.dx - p.w * 0.5, y: center.y - p.h + 1, width: p.w, height: p.h)
        context.fill(Path(ellipseIn: rect), with: .color(p.col))
    }
    context.fill(Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 6.5, width: 7, height: 4.5)), with: .color(Color(hex: 0xFFD966)))
}

/// Swaying curved tropical palm silhouette.
private func drawSwayingPalm(
    in context: inout GraphicsContext,
    base: CGPoint,
    height: CGFloat,
    lean: CGFloat,
    trunkColor: Color,
    frondLight: Color,
    frondDark: Color
) {
    let crown = CGPoint(x: base.x + lean, y: base.y - height)
    let ctrl = CGPoint(x: base.x + lean * 0.28, y: base.y - height * 0.56)
    var trunk = Path()
    trunk.move(to: CGPoint(x: base.x - 3.2, y: base.y))
    trunk.addQuadCurve(to: CGPoint(x: crown.x - 1.3, y: crown.y), control: CGPoint(x: ctrl.x - 2.0, y: ctrl.y))
    trunk.addLine(to: CGPoint(x: crown.x + 1.3, y: crown.y))
    trunk.addQuadCurve(to: CGPoint(x: base.x + 3.2, y: base.y), control: CGPoint(x: ctrl.x + 2.0, y: ctrl.y))
    trunk.closeSubpath()
    context.fill(trunk, with: .color(trunkColor))

    let fronds: [(CGFloat, CGFloat, CGFloat, Bool)] = [
        (-28, -5, 11, true), (-20, -18, 6, false), (5, -20, 4, false), (25, -13, 8, false), (26, 0, 12, true)
    ]
    for (dx, dy, droop, dark) in fronds {
        var leaf = Path()
        leaf.move(to: crown)
        leaf.addQuadCurve(to: CGPoint(x: crown.x + dx, y: crown.y + dy + droop), control: CGPoint(x: crown.x + dx * 0.52, y: crown.y + dy - 8))
        leaf.addQuadCurve(to: crown, control: CGPoint(x: crown.x + dx * 0.48, y: crown.y + dy + 2))
        leaf.closeSubpath()
        context.fill(leaf, with: .color(dark ? frondDark : frondLight))
    }
}

/// Grounded foreground path/shoreline ledge centered cleanly around `y ~ 0.76`.
private func drawForegroundLedge(
    in context: inout GraphicsContext,
    size: CGSize,
    topY: CGFloat,
    topColor: Color,
    midColor: Color,
    deepColor: Color,
    rimColor: Color
) {
    let w = size.width
    let h = size.height

    var bank = Path()
    bank.move(to: CGPoint(x: -6, y: topY + 6))
    bank.addCurve(
        to: CGPoint(x: w * 0.50, y: topY - 4),
        control1: CGPoint(x: w * 0.16, y: topY - 12),
        control2: CGPoint(x: w * 0.34, y: topY - 4)
    )
    bank.addCurve(
        to: CGPoint(x: w + 6, y: topY + 5),
        control1: CGPoint(x: w * 0.68, y: topY - 4),
        control2: CGPoint(x: w * 0.84, y: topY - 12)
    )
    bank.addLine(to: CGPoint(x: w + 6, y: h + 6))
    bank.addLine(to: CGPoint(x: -6, y: h + 6))
    bank.closeSubpath()

    let grad = Gradient(stops: [
        .init(color: topColor, location: 0.0),
        .init(color: midColor, location: 0.45),
        .init(color: deepColor, location: 1.0)
    ])
    context.fill(bank, with: .linearGradient(grad, startPoint: CGPoint(x: 0, y: topY - 10), endPoint: CGPoint(x: 0, y: h)))
    context.stroke(bank, with: .color(rimColor.opacity(0.68)), lineWidth: 2.0)
}

private func drawJourneyPine(in context: inout GraphicsContext, base: CGPoint, height: CGFloat, color: Color) {
    for tier in 0..<3 {
        let f = CGFloat(tier) / 3.0
        let bottomY = base.y - height * f * 0.58
        let topY = bottomY - height * (0.48 - f * 0.08)
        let halfW = height * (0.24 - f * 0.05)
        var tri = Path()
        tri.move(to: CGPoint(x: base.x, y: topY))
        tri.addLine(to: CGPoint(x: base.x + halfW, y: bottomY))
        tri.addLine(to: CGPoint(x: base.x - halfW, y: bottomY))
        tri.closeSubpath()
        context.fill(tri, with: .color(color))
    }
}

private func drawJourneyMoon(in context: inout GraphicsContext, center: CGPoint, radius r: CGFloat) {
    let haloRect = CGRect(x: center.x - r * 2.5, y: center.y - r * 2.5, width: r * 5.0, height: r * 5.0)
    context.fill(
        Path(ellipseIn: haloRect),
        with: .radialGradient(
            Gradient(colors: [Color(hex: 0xD8E2FF).opacity(0.38), Color(hex: 0xD8E2FF).opacity(0)]),
            center: center, startRadius: r * 0.4, endRadius: r * 2.5
        )
    )

    context.drawLayer { layer in
        layer.translateBy(x: center.x, y: center.y)
        layer.rotate(by: .degrees(-22))
        let hornRad = 64.0 * Double.pi / 180.0
        let innerX = r * CGFloat(cos(hornRad))
        let innerR = r * CGFloat(sin(hornRad))
        var crescent = Path()
        crescent.addArc(center: .zero, radius: r, startAngle: .degrees(296), endAngle: .degrees(64), clockwise: true)
        crescent.addArc(center: CGPoint(x: innerX, y: 0), radius: innerR, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        crescent.closeSubpath()
        layer.fill(crescent, with: .color(Color(hex: 0xFFF8DF)))
    }

    // Companion slender 6-point evening starlet.
    let sp = CGPoint(x: center.x + r * 0.82, y: center.y - r * 0.56)
    let sr: CGFloat = 5.2
    context.fill(StarletShape().path(in: CGRect(x: sp.x - sr, y: sp.y - sr, width: sr * 2, height: sr * 2)), with: .color(Color(hex: 0xFFF6CC)))
}

// MARK: - 1. Misty Spring (.spring)

private func drawSpringBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0xE2F7EE), Color(hex: 0xC9EFE0), Color(hex: 0xA4DAC4)
    ])

    // Diagonal sunlit volumetric forest shafts piercing the morning mist.
    for i in 0..<3 {
        let sway = CGFloat(sin(t * 0.24 + Double(i))) * 10
        let xTop = w * (0.56 + CGFloat(i) * 0.14) + sway
        var ray = Path()
        ray.move(to: CGPoint(x: xTop, y: 0))
        ray.addLine(to: CGPoint(x: xTop + 36, y: 0))
        ray.addLine(to: CGPoint(x: xTop - 86, y: h * 0.62))
        ray.addLine(to: CGPoint(x: xTop - 124, y: h * 0.62))
        ray.closeSubpath()
        context.fill(
            ray,
            with: .linearGradient(
                Gradient(colors: [Color(hex: 0xFFFFEB).opacity(0.36), Color(hex: 0xFFFFEB).opacity(0)]),
                startPoint: CGPoint(x: xTop, y: 0), endPoint: CGPoint(x: xTop - 95, y: h * 0.62)
            )
        )
    }

    // Plane 1: Far misty eucalyptus mountain ridge (cleanly below y = 0.445*h header band).
    var farMtn = Path()
    farMtn.move(to: CGPoint(x: 0, y: h * 0.56))
    farMtn.addQuadCurve(to: CGPoint(x: w * 0.36, y: h * 0.485), control: CGPoint(x: w * 0.16, y: h * 0.455))
    farMtn.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.505), control: CGPoint(x: w * 0.54, y: h * 0.515))
    farMtn.addQuadCurve(to: CGPoint(x: w, y: h * 0.475), control: CGPoint(x: w * 0.88, y: h * 0.448))
    farMtn.addLine(to: CGPoint(x: w, y: h * 0.64))
    farMtn.addLine(to: CGPoint(x: 0, y: h * 0.64))
    farMtn.closeSubpath()
    context.fill(farMtn, with: .color(Color(hex: 0x9AD2BD).opacity(0.68)))

    // Plane 2: Mid cedar & pine misty ridge (tallest tips strictly >= 0.455*h).
    let cedars: [(CGFloat, CGFloat)] = [
        (0.05, 0.095), (0.13, 0.115), (0.22, 0.085), (0.31, 0.070),
        (0.70, 0.075), (0.79, 0.095), (0.87, 0.115), (0.95, 0.095)
    ]
    for (xf, hf) in cedars {
        drawJourneyPine(in: &context, base: CGPoint(x: w * xf, y: h * 0.57), height: h * hf, color: Color(hex: 0x6BB098).opacity(0.80))
    }

    // Plane 3: Mossy forest shoreline valley behind the spring pool.
    var valley = Path()
    valley.move(to: CGPoint(x: 0, y: h * 0.58))
    valley.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.53), control: CGPoint(x: w * 0.22, y: h * 0.495))
    valley.addQuadCurve(to: CGPoint(x: w, y: h * 0.57), control: CGPoint(x: w * 0.78, y: h * 0.49))
    valley.addLine(to: CGPoint(x: w, y: h * 0.68))
    valley.addLine(to: CGPoint(x: 0, y: h * 0.68))
    valley.closeSubpath()
    context.fill(valley, with: .color(Color(hex: 0x569E82).opacity(0.86)))

    // Stacked sculpted mossy river boulders framing left and right flanks.
    drawSculptedBoulder(in: &context, rect: CGRect(x: -w * 0.06, y: h * 0.50, width: w * 0.28, height: h * 0.11), stoneLit: Color(hex: 0x8CA8A2), stoneDark: Color(hex: 0x577572), mossLit: Color(hex: 0x7ED194), mossDark: Color(hex: 0x478F64))
    drawSculptedBoulder(in: &context, rect: CGRect(x: w * 0.14, y: h * 0.54, width: w * 0.15, height: h * 0.07), stoneLit: Color(hex: 0x9BB5AF), stoneDark: Color(hex: 0x64837E), mossLit: Color(hex: 0x8AD99E), mossDark: Color(hex: 0x529B6F))
    drawSculptedBoulder(in: &context, rect: CGRect(x: w * 0.76, y: h * 0.505, width: w * 0.29, height: h * 0.11), stoneLit: Color(hex: 0x86A29C), stoneDark: Color(hex: 0x516E6B), mossLit: Color(hex: 0x76C98C), mossDark: Color(hex: 0x3F855D))
}

private func drawSpringWater(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    drawCurvedWaterBody(
        in: &context, size: size, topOffset: 10, curveAmp: 5.5, waveAmp: 1.4,
        colors: [Color(hex: 0x94ECE4), Color(hex: 0x4AC5C0), Color(hex: 0x26959A)],
        lipColor: Color(hex: 0xE8FFFB).opacity(0.80), time: t
    )

    // Luminous mineral spring glow & concentric animated ripples.
    let cx = size.width * 0.50
    let cy = size.height * 0.46
    context.fill(
        Path(ellipseIn: CGRect(x: cx - 64, y: cy - 22, width: 128, height: 44)),
        with: .radialGradient(Gradient(colors: [Color(hex: 0xD6FFF8).opacity(0.42), Color(hex: 0xD6FFF8).opacity(0)]), center: CGPoint(x: cx, y: cy), startRadius: 4, endRadius: 64)
    )
    for i in 0..<3 {
        let p = (t * 0.42 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1.0)
        let rx = CGFloat(14 + p * Double(size.width) * 0.25)
        let ry = rx * 0.26
        context.stroke(
            Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)),
            with: .color(Color(hex: 0xECFFFC).opacity(0.68 * (1.0 - p))),
            lineWidth: 1.8
        )
    }
}

private func drawSpringForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    // Rising gentle mineral mist wisps drifting above the turquoise spring.
    for i in 0..<6 {
        let seed = Double(i) + 3.0
        let cycle = (t * 0.13 + journeyNoise(seed, 1.1)).truncatingRemainder(dividingBy: 1.0)
        let x = w * (0.16 + CGFloat(journeyNoise(seed, 2.2)) * 0.68) + CGFloat(sin(t * 0.48 + seed)) * 12
        let y = h * 0.67 - CGFloat(cycle) * h * 0.22
        let alpha = sin(cycle * Double.pi) * 0.34
        let mistW = w * 0.26
        context.fill(Path(ellipseIn: CGRect(x: x - mistW * 0.5, y: y - 13, width: mistW, height: 26)), with: .color(Color(hex: 0xF4FFFB).opacity(alpha)))
    }

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.75,
        topColor: Color(hex: 0x8DD29D), midColor: Color(hex: 0x5EA876), deepColor: Color(hex: 0x3A7656),
        rimColor: Color(hex: 0xD8F9D2)
    )

    // Wet glistening river pebbles tucked on the mossy path.
    let pebbles: [(CGFloat, CGFloat, CGFloat)] = [(0.28, 0.81, 14), (0.70, 0.82, 16), (0.50, 0.85, 19)]
    for (xf, yf, r) in pebbles {
        let rect = CGRect(x: w * xf - r, y: h * yf - r * 0.42, width: r * 2, height: r * 0.84)
        context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xDCEAE5).opacity(0.78)))
        context.fill(Path(ellipseIn: CGRect(x: rect.minX + 4, y: rect.minY + 2, width: rect.width * 0.45, height: rect.height * 0.3)), with: .color(.white.opacity(0.45)))
    }

    // Lush curved botanical fern fronds framing both bottom corners.
    let sway = sin(t * 0.9) * 0.04
    drawFernFrond(in: &context, base: CGPoint(x: -4, y: h * 0.85), length: w * 0.25, angle: -0.78 + sway, curl: 0.08, color: Color(hex: 0x2A6648))
    drawFernFrond(in: &context, base: CGPoint(x: w * 0.06, y: h * 0.93), length: w * 0.19, angle: -0.45 + sway, curl: 0.06, color: Color(hex: 0x3D855E))
    drawFernFrond(in: &context, base: CGPoint(x: w + 4, y: h * 0.85), length: w * 0.25, angle: -2.36 - sway, curl: -0.08, color: Color(hex: 0x2A6648))
    drawFernFrond(in: &context, base: CGPoint(x: w * 0.94, y: h * 0.93), length: w * 0.19, angle: -2.68 - sway, curl: -0.06, color: Color(hex: 0x3D855E))
}

// MARK: - 2. Bubble Brook (.brook)

private func drawBrookBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0xDDF4FF), Color(hex: 0xC4EBFC), Color(hex: 0xE6FBF0)
    ])

    let drift = CGFloat(sin(t * 0.18)) * 8
    drawGhibliCloud(in: &context, center: CGPoint(x: w * 0.80 + drift, y: h * 0.44), width: w * 0.24, lit: .white, rim: Color(hex: 0xFFFDF5), shade: Color(hex: 0xC6E6F6), alpha: 0.88)

    // Layered Studio Ghibli rolling sunlit butter-mint hills (strictly >= 0.455*h).
    var farHill = Path()
    farHill.move(to: CGPoint(x: 0, y: h * 0.56))
    farHill.addQuadCurve(to: CGPoint(x: w * 0.54, y: h * 0.49), control: CGPoint(x: w * 0.24, y: h * 0.455))
    farHill.addQuadCurve(to: CGPoint(x: w, y: h * 0.52), control: CGPoint(x: w * 0.80, y: h * 0.46))
    farHill.addLine(to: CGPoint(x: w, y: h * 0.64))
    farHill.addLine(to: CGPoint(x: 0, y: h * 0.64))
    farHill.closeSubpath()
    context.fill(farHill, with: .color(Color(hex: 0xB3E4BC)))

    var midHill = Path()
    midHill.move(to: CGPoint(x: 0, y: h * 0.56))
    midHill.addQuadCurve(to: CGPoint(x: w * 0.46, y: h * 0.525), control: CGPoint(x: w * 0.20, y: h * 0.485))
    midHill.addQuadCurve(to: CGPoint(x: w, y: h * 0.52), control: CGPoint(x: w * 0.76, y: h * 0.485))
    midHill.addLine(to: CGPoint(x: w, y: h * 0.63))
    midHill.addLine(to: CGPoint(x: 0, y: h * 0.63))
    midHill.closeSubpath()
    let hillGrad = Gradient(colors: [Color(hex: 0xA8E0A4), Color(hex: 0x79C98E)])
    context.fill(midHill, with: .linearGradient(hillGrad, startPoint: CGPoint(x: 0, y: h * 0.485), endPoint: CGPoint(x: 0, y: h * 0.60)))

    // Distant rounded meadow trees nestled cleanly below y = 0.45*h.
    for (xf, yf, r) in [(0.14, 0.485, 11.5), (0.22, 0.492, 9.5), (0.83, 0.482, 12.5)] {
        let cr = CGFloat(r)
        context.fill(Path(ellipseIn: CGRect(x: w * CGFloat(xf) - cr, y: h * CGFloat(yf) - cr, width: cr * 2, height: cr * 1.8)), with: .color(Color(hex: 0x62B37C)))
    }
}

private func drawBrookWater(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    drawCurvedWaterBody(
        in: &context, size: size, topOffset: 9, curveAmp: 4.0, waveAmp: 1.5,
        colors: [Color(hex: 0x9BE7FA), Color(hex: 0x56C6ED), Color(hex: 0x35A2D8)],
        lipColor: Color(hex: 0xEBFFFF).opacity(0.78), time: t
    )

    // Sweeping S-curved sunlit meadow banks with dappled wildflower tufts.
    var leftBank = Path()
    leftBank.move(to: CGPoint(x: 0, y: 6))
    leftBank.addQuadCurve(to: CGPoint(x: w * 0.39, y: 9), control: CGPoint(x: w * 0.20, y: 2))
    leftBank.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.46), control1: CGPoint(x: w * 0.31, y: h * 0.20), control2: CGPoint(x: w * 0.28, y: h * 0.36))
    leftBank.addLine(to: CGPoint(x: 0, y: h * 0.52))
    leftBank.closeSubpath()
    context.fill(leftBank, with: .color(Color(hex: 0x7FD094)))
    context.stroke(leftBank, with: .color(Color(hex: 0xE2FAD0).opacity(0.72)), lineWidth: 1.6)

    var rightBank = Path()
    rightBank.move(to: CGPoint(x: w * 0.65, y: 9))
    rightBank.addQuadCurve(to: CGPoint(x: w, y: 6), control: CGPoint(x: w * 0.84, y: 2))
    rightBank.addLine(to: CGPoint(x: w, y: h * 0.48))
    rightBank.addCurve(to: CGPoint(x: w * 0.65, y: 9), control1: CGPoint(x: w * 0.80, y: h * 0.34), control2: CGPoint(x: w * 0.74, y: h * 0.20))
    rightBank.closeSubpath()
    context.fill(rightBank, with: .color(Color(hex: 0x74C68C)))
    context.stroke(rightBank, with: .color(Color(hex: 0xE2FAD0).opacity(0.68)), lineWidth: 1.6)

    // Shimmering turquoise current ribbons curving through the S-brook.
    for i in 0..<8 {
        let seed = Double(i) + 12.0
        let p = (t * 0.28 + journeyNoise(seed, 1.3)).truncatingRemainder(dividingBy: 1.0)
        let x = w * (0.14 + CGFloat(p) * 0.72)
        let y = h * (0.28 + CGFloat(journeyNoise(seed, 2.3)) * 0.50)
        var dash = Path()
        dash.move(to: CGPoint(x: x - 14, y: y))
        dash.addQuadCurve(to: CGPoint(x: x + 14, y: y), control: CGPoint(x: x, y: y - 3.0))
        context.stroke(dash, with: .color(.white.opacity(0.66 * sin(p * Double.pi))), style: StrokeStyle(lineWidth: 2.1, lineCap: .round))
    }

    // Curved mossy stepping stones crossing the brook.
    let stones: [(CGFloat, CGFloat, CGFloat)] = [(0.23, 0.56, 20), (0.40, 0.63, 24), (0.58, 0.61, 22), (0.76, 0.55, 19)]
    for (xf, yf, rx) in stones {
        let cx = w * xf
        let cy = h * yf
        context.fill(Path(ellipseIn: CGRect(x: cx - rx, y: cy - rx * 0.34 + 3.8, width: rx * 2, height: rx * 0.72)), with: .color(Color(hex: 0x1A688A).opacity(0.30)))
        let stoneRect = CGRect(x: cx - rx, y: cy - rx * 0.34, width: rx * 2, height: rx * 0.68)
        context.fill(Path(ellipseIn: stoneRect), with: .linearGradient(Gradient(colors: [Color(hex: 0xFAF4EA), Color(hex: 0xDED2C2)]), startPoint: CGPoint(x: cx, y: stoneRect.minY), endPoint: CGPoint(x: cx, y: stoneRect.maxY)))
        context.fill(Path(ellipseIn: CGRect(x: cx - rx * 0.76, y: cy - rx * 0.24, width: rx * 0.52, height: rx * 0.24)), with: .color(Color(hex: 0x7BC485).opacity(0.75)))
    }
}

private func drawBrookForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.75,
        topColor: Color(hex: 0xA8DF98), midColor: Color(hex: 0x77C484), deepColor: Color(hex: 0x4E9866),
        rimColor: Color(hex: 0xE6FBD2)
    )

    // Sunlit riverside buttercups tucked near both corners.
    for (xf, yf) in [(0.11, 0.82), (0.17, 0.85), (0.83, 0.84), (0.90, 0.81)] {
        let pt = CGPoint(x: w * CGFloat(xf), y: h * CGFloat(yf))
        context.fill(Path(ellipseIn: CGRect(x: pt.x - 4.2, y: pt.y - 4.2, width: 8.4, height: 8.4)), with: .color(Color(hex: 0xFFE06B)))
        context.fill(Path(ellipseIn: CGRect(x: pt.x - 1.6, y: pt.y - 1.6, width: 3.2, height: 3.2)), with: .color(Color(hex: 0xFFFDF5)))
    }

    // Delicate overhanging weeping-willow vines framed strictly below y = 0.44*h header band.
    let sway = CGFloat(sin(t * 0.85)) * 5.0
    for strand in 0..<4 {
        let dropH = h * (0.14 + CGFloat(strand % 2) * 0.06)
        drawWillowVine(
            in: &context,
            top: CGPoint(x: w * (0.98 - CGFloat(strand) * 0.042), y: h * 0.44),
            drop: dropH,
            sway: -sway - 4,
            stemColor: Color(hex: 0x56A06C).opacity(0.68),
            leafColor: Color(hex: 0x76C487).opacity(0.76)
        )
    }
    for strand in 0..<2 {
        drawWillowVine(
            in: &context,
            top: CGPoint(x: w * (0.018 + CGFloat(strand) * 0.032), y: h * 0.455),
            drop: h * (0.13 + CGFloat(strand) * 0.035),
            sway: sway + 4,
            stemColor: Color(hex: 0x56A06C).opacity(0.62),
            leafColor: Color(hex: 0x76C487).opacity(0.70)
        )
    }

    // Layered iridescent rising brook bubbles rising gently in the brook basin (>= 0.46*h).
    for i in 0..<10 {
        let seed = Double(i) + 31.0
        let cycle = (t * (0.15 + journeyNoise(seed, 1.4) * 0.11) + journeyNoise(seed, 2.4)).truncatingRemainder(dividingBy: 1.0)
        let bx = w * (0.10 + CGFloat(journeyNoise(seed, 3.4)) * 0.80) + CGFloat(sin(t * 1.1 + seed)) * 10
        let by = h * 0.72 - CGFloat(cycle) * h * 0.25
        let r = CGFloat(5.0 + journeyNoise(seed, 4.4) * 7.2)
        let alpha = sin(cycle * Double.pi) * 0.86

        let rect = CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xE8FCFF).opacity(0.28 * alpha)))
        let rim = i.isMultiple(of: 2) ? Color(hex: 0xFFB8E6) : Color(hex: 0x9BEBFF)
        context.stroke(Path(ellipseIn: rect), with: .color(rim.opacity(0.78 * alpha)), lineWidth: 1.35)
        context.fill(Path(ellipseIn: CGRect(x: bx - r * 0.48, y: by - r * 0.50, width: r * 0.42, height: r * 0.30)), with: .color(.white.opacity(0.92 * alpha)))
    }
}

// MARK: - 3. Lily Meadow (.meadow)

private func drawMeadowBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0xEFFBE8), Color(hex: 0xDBF4DF), Color(hex: 0xFBF9DF)
    ])

    // Far sunlit sage hill plane (strictly >= 0.455*h).
    var farHill = Path()
    farHill.move(to: CGPoint(x: 0, y: h * 0.56))
    farHill.addQuadCurve(to: CGPoint(x: w * 0.45, y: h * 0.49), control: CGPoint(x: w * 0.22, y: h * 0.455))
    farHill.addQuadCurve(to: CGPoint(x: w, y: h * 0.51), control: CGPoint(x: w * 0.76, y: h * 0.46))
    farHill.addLine(to: CGPoint(x: w, y: h * 0.62))
    farHill.addLine(to: CGPoint(x: 0, y: h * 0.62))
    farHill.closeSubpath()
    context.fill(farHill, with: .color(Color(hex: 0xB5E3B4)))

    // Mid Studio Ghibli lush meadow hill plane.
    var midHill = Path()
    midHill.move(to: CGPoint(x: 0, y: h * 0.56))
    midHill.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.515), control: CGPoint(x: w * 0.26, y: h * 0.48))
    midHill.addQuadCurve(to: CGPoint(x: w, y: h * 0.54), control: CGPoint(x: w * 0.78, y: h * 0.485))
    midHill.addLine(to: CGPoint(x: w, y: h * 0.62))
    midHill.addLine(to: CGPoint(x: 0, y: h * 0.62))
    midHill.closeSubpath()
    context.fill(midHill, with: .color(Color(hex: 0x86CE92)))

    // Sunlit distant rounded tree silhouettes cleanly below y = 0.45*h.
    let trees: [(CGFloat, CGFloat, CGFloat)] = [(0.09, 0.495, 17), (0.19, 0.505, 13), (0.81, 0.498, 14), (0.91, 0.49, 18)]
    for (xf, yf, r) in trees {
        let cx = w * xf
        let cy = h * yf
        context.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 1.75)), with: .color(Color(hex: 0x5CA972)))
        context.fill(Path(ellipseIn: CGRect(x: cx - r * 0.75, y: cy - r * 0.92, width: r * 1.3, height: r * 0.95)), with: .color(Color(hex: 0x9DE09E).opacity(0.65)))
    }

    // Warm diagonal golden sunbeams across the meadow.
    let sway = CGFloat(sin(t * 0.3)) * 8
    var beam = Path()
    beam.move(to: CGPoint(x: w * 0.70 + sway, y: 0))
    beam.addLine(to: CGPoint(x: w * 0.90 + sway, y: 0))
    beam.addLine(to: CGPoint(x: w * 0.52, y: h * 0.56))
    beam.addLine(to: CGPoint(x: w * 0.32, y: h * 0.56))
    beam.closeSubpath()
    context.fill(
        beam,
        with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF8CF).opacity(0.36), Color(hex: 0xFFF8CF).opacity(0)]), startPoint: CGPoint(x: w * 0.80, y: 0), endPoint: CGPoint(x: w * 0.44, y: h * 0.56))
    )
}

private func drawMeadowWater(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    drawCurvedWaterBody(
        in: &context, size: size, topOffset: 9, curveAmp: 4.5, waveAmp: 1.2,
        colors: [Color(hex: 0x98E3CA), Color(hex: 0x52BBA2), Color(hex: 0x31907E)],
        lipColor: Color(hex: 0xECFFF4).opacity(0.78), time: t
    )

    // Veined notched lily pads & multi-petal blooming pink-and-cream lotus flowers.
    let pads: [(CGFloat, CGFloat, CGFloat, Bool)] = [
        (0.18, 0.38, 28, true),
        (0.38, 0.60, 22, false),
        (0.66, 0.42, 30, true),
        (0.84, 0.64, 24, true)
    ]
    for (idx, pad) in pads.enumerated() {
        let bob = CGFloat(sin(t * 1.1 + Double(idx) * 1.4)) * 1.8
        drawGouacheLotusPad(
            in: &context,
            center: CGPoint(x: w * pad.0, y: h * pad.1 + bob),
            rx: pad.2,
            bloom: pad.3,
            padLight: Color(hex: 0x9CE2A0),
            padDeep: Color(hex: 0x4EA36A)
        )
    }
}

private func drawMeadowForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.75,
        topColor: Color(hex: 0xB4E38E), midColor: Color(hex: 0x7EC577), deepColor: Color(hex: 0x4E965A),
        rimColor: Color(hex: 0xEDFFD2)
    )

    // Swaying cattail reeds framing both foreground corners.
    let sway = CGFloat(sin(t * 1.0)) * 3.5
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.05, y: h * 0.90), height: h * 0.22, lean: 6 + sway, stemColor: Color(hex: 0x3C7F54), headColor: Color(hex: 0x7D5442))
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.09, y: h * 0.92), height: h * 0.16, lean: 12 + sway * 0.8, stemColor: Color(hex: 0x4B9464), headColor: nil)
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.95, y: h * 0.90), height: h * 0.22, lean: -6 - sway, stemColor: Color(hex: 0x3C7F54), headColor: Color(hex: 0x7D5442))
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.91, y: h * 0.92), height: h * 0.16, lean: -11 - sway * 0.8, stemColor: Color(hex: 0x4B9464), headColor: nil)

    // Buttercups & daisies tucked along the bank.
    for (xf, yf) in [(0.15, 0.83), (0.21, 0.86), (0.80, 0.85), (0.86, 0.82)] {
        let c = CGPoint(x: w * CGFloat(xf), y: h * CGFloat(yf))
        context.fill(Path(ellipseIn: CGRect(x: c.x - 5, y: c.y - 4, width: 10, height: 8)), with: .color(.white))
        context.fill(Path(ellipseIn: CGRect(x: c.x - 2.2, y: c.y - 2.2, width: 4.4, height: 4.4)), with: .color(Color(hex: 0xFFD85E)))
    }

    // Three graceful darting translucent-winged dragonflies.
    for i in 0..<3 {
        let phase = t * (0.95 + Double(i) * 0.22) + Double(i) * 2.1
        let cx = w * (0.24 + CGFloat(i) * 0.26) + CGFloat(sin(phase)) * 26
        let cy = h * (0.50 + CGFloat(i % 2) * 0.08) + CGFloat(sin(phase * 2.0)) * 10
        let wingBeat = CGFloat(sin(t * 24.0 + Double(i))) * 2.5

        context.fill(Path(ellipseIn: CGRect(x: cx - 10, y: cy - 3.5 + wingBeat * 0.3, width: 9, height: 4.5)), with: .color(Color(hex: 0xE6FFFF).opacity(0.84)))
        context.fill(Path(ellipseIn: CGRect(x: cx + 1, y: cy - 3.5 - wingBeat * 0.3, width: 9, height: 4.5)), with: .color(Color(hex: 0xE6FFFF).opacity(0.84)))
        var body = Path()
        body.move(to: CGPoint(x: cx, y: cy - 4))
        body.addLine(to: CGPoint(x: cx, y: cy + 8))
        context.stroke(body, with: .color(Color(hex: 0x26A4B6)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
    }
}

// MARK: - 4. Rainbow Falls (.falls)

private func drawFallsBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0xDCEAFF), Color(hex: 0xC2DCFF), Color(hex: 0xE8F5FF)
    ])

    // Distant hazy canyon silhouette (strictly >= 0.46*h, leaving header sky open).
    var farCanyon = Path()
    farCanyon.move(to: CGPoint(x: 0, y: h * 0.465))
    farCanyon.addLine(to: CGPoint(x: w * 0.42, y: h * 0.485))
    farCanyon.addLine(to: CGPoint(x: w * 0.56, y: h * 0.475))
    farCanyon.addLine(to: CGPoint(x: w, y: h * 0.46))
    farCanyon.addLine(to: CGPoint(x: w, y: h * 0.66))
    farCanyon.addLine(to: CGPoint(x: 0, y: h * 0.66))
    farCanyon.closeSubpath()
    context.fill(farCanyon, with: .color(Color(hex: 0xA8B6DF).opacity(0.62)))

    // Left & right Monument Valley faceted stepped sandstone-and-slate cliffs.
    drawFacetedCliff(in: &context, isLeft: true, width: w, height: h, sway: CGFloat(sin(t * 0.9)) * 2.5)
    drawFacetedCliff(in: &context, isLeft: false, width: w, height: h, sway: CGFloat(cos(t * 0.9)) * 2.5)

    // Animated multi-ribbon cascading waterfall through the stepped canyon notch.
    let fallRect = CGRect(x: w * 0.355, y: h * 0.49, width: w * 0.285, height: h * 0.165)
    let fallGrad = Gradient(colors: [Color(hex: 0xB8F2FF), Color(hex: 0x62CEF5), Color(hex: 0xD2F9FF)])
    context.fill(Path(roundedRect: fallRect, cornerRadius: 8), with: .linearGradient(fallGrad, startPoint: CGPoint(x: 0, y: fallRect.minY), endPoint: CGPoint(x: 0, y: fallRect.maxY)))

    for i in 0..<8 {
        let xf = 0.38 + CGFloat(i) * 0.033
        let p = (t * 0.92 + Double(i) * 0.21).truncatingRemainder(dividingBy: 1.0)
        let yStart = fallRect.minY + CGFloat(p) * (fallRect.height * 0.68)
        var streak = Path()
        streak.move(to: CGPoint(x: w * xf, y: yStart))
        streak.addLine(to: CGPoint(x: w * xf, y: min(yStart + 22, fallRect.maxY)))
        context.stroke(streak, with: .color(.white.opacity(0.78 * sin(p * Double.pi))), style: StrokeStyle(lineWidth: i.isMultiple(of: 2) ? 3.0 : 2.0, lineCap: .round))
    }

    // Soft translucent 5-band watercolor rainbow arc cresting strictly at y = 0.46*h (clear of title & wax seals!).
    let rainbowCenter = CGPoint(x: w * 0.50, y: h * 0.655)
    let bands: [Color] = [
        Color(hex: 0xFF9EA8), Color(hex: 0xFFD28C), Color(hex: 0xB8EDA8), Color(hex: 0x98E3FA), Color(hex: 0xCAB4FF)
    ]
    let baseR = min(w * 0.39, h * 0.195)
    for (idx, col) in bands.enumerated() {
        let r = baseR - CGFloat(idx) * 4.6
        var arc = Path()
        arc.addArc(center: rainbowCenter, radius: r, startAngle: .degrees(194), endAngle: .degrees(346), clockwise: false)
        context.stroke(arc, with: .color(col.opacity(0.56)), style: StrokeStyle(lineWidth: 4.6, lineCap: .round))
    }
}

private func drawFacetedCliff(in context: inout GraphicsContext, isLeft: Bool, width w: CGFloat, height h: CGFloat, sway: CGFloat) {
    let topY = isLeft ? h * 0.495 : h * 0.485
    let edgeX = isLeft ? w * 0.35 : w * 0.64
    let outerX: CGFloat = isLeft ? -4 : w + 4
    let midX = isLeft ? w * 0.22 : w * 0.78

    // Sunlit sandstone-lavender front facet.
    var front = Path()
    front.move(to: CGPoint(x: outerX, y: topY))
    front.addLine(to: CGPoint(x: midX, y: topY))
    front.addLine(to: CGPoint(x: midX + (isLeft ? 10 : -10), y: h * 0.66))
    front.addLine(to: CGPoint(x: outerX, y: h * 0.66))
    front.closeSubpath()
    context.fill(front, with: .color(isLeft ? Color(hex: 0xC4A7B8) : Color(hex: 0x8D9AC4)))

    // Cool deep-slate inner canyon shadow facet facing the waterfall.
    var inner = Path()
    inner.move(to: CGPoint(x: midX, y: topY))
    inner.addLine(to: CGPoint(x: edgeX, y: topY + 6))
    inner.addLine(to: CGPoint(x: edgeX + (isLeft ? 14 : -14), y: h * 0.66))
    inner.addLine(to: CGPoint(x: midX + (isLeft ? 10 : -10), y: h * 0.66))
    inner.closeSubpath()
    context.fill(inner, with: .color(Color(hex: 0x5D6C9A)))

    // Crisp sunlit moss & terrace cap ledge.
    let capMinX = min(outerX, edgeX)
    let capW = abs(edgeX - outerX)
    context.fill(Path(roundedRect: CGRect(x: capMinX, y: topY - 4, width: capW, height: 10), cornerRadius: 5), with: .color(Color(hex: 0x62BE87)))
    context.fill(Path(roundedRect: CGRect(x: capMinX, y: topY - 4, width: capW * 0.72, height: 4.5), cornerRadius: 2.2), with: .color(Color(hex: 0xA8EBAC).opacity(0.75)))

    // Draping cliffside hanging fern vines.
    let vineX = isLeft ? w * 0.28 : w * 0.71
    drawWillowVine(in: &context, top: CGPoint(x: vineX, y: topY + 4), drop: h * 0.095, sway: sway, stemColor: Color(hex: 0x3D8A5F), leafColor: Color(hex: 0x6CC48E))
}

private func drawFallsWater(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    drawCurvedWaterBody(
        in: &context, size: size, topOffset: 10, curveAmp: 5.0, waveAmp: 1.8,
        colors: [Color(hex: 0x9EEEFB), Color(hex: 0x56C7ED), Color(hex: 0x2E9BD0)],
        lipColor: Color(hex: 0xE8FBFF).opacity(0.84), time: t
    )

    // Layered billowing mist plumes at the plunge base.
    let puffs: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (0.34, 9, 13, 0.60), (0.40, 3, 19, 0.74), (0.46, 7, 23, 0.84),
        (0.52, 4, 22, 0.82), (0.58, 7, 18, 0.70), (0.64, 9, 13, 0.56)
    ]
    for (idx, sp) in puffs.enumerated() {
        let seed = Double(idx) + 5.0
        let pulse = CGFloat(0.88 + 0.12 * sin(t * 2.1 + seed))
        let driftY = CGFloat(sin(t * 1.7 + seed)) * 2.5
        let rx = sp.2 * pulse
        let ry = rx * 0.68
        context.fill(Path(ellipseIn: CGRect(x: size.width * sp.0 - rx, y: sp.1 + driftY - ry * 0.45, width: rx * 2, height: ry * 2)), with: .color(Color(hex: 0xF5FDFF).opacity(sp.3)))
    }
}

private func drawFallsForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.75,
        topColor: Color(hex: 0x7FD19C), midColor: Color(hex: 0x52A479), deepColor: Color(hex: 0x337258),
        rimColor: Color(hex: 0xD8FCE2)
    )

    let sway = sin(t * 1.0) * 0.05
    drawFernFrond(in: &context, base: CGPoint(x: -4, y: h * 0.87), length: w * 0.24, angle: -0.75 + sway, curl: 0.08, color: Color(hex: 0x246049))
    drawFernFrond(in: &context, base: CGPoint(x: w + 4, y: h * 0.87), length: w * 0.24, angle: -2.39 - sway, curl: -0.08, color: Color(hex: 0x246049))
}

// MARK: - 5. Coral Cove (.cove)

private func drawCoveBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0xFFE9DB), Color(hex: 0xFFD8C4), Color(hex: 0xFFF3E2)
    ])

    // Warm sunlit coastal sun nestled cleanly on open right horizon sky (>= 0.45*h).
    let sunC = CGPoint(x: w * 0.82, y: h * 0.455)
    context.fill(
        Path(ellipseIn: CGRect(x: sunC.x - 42, y: sunC.y - 42, width: 84, height: 84)),
        with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF7D4).opacity(0.88), Color(hex: 0xFFF7D4).opacity(0)]), center: sunC, startRadius: 6, endRadius: 42)
    )
    context.fill(Path(ellipseIn: CGRect(x: sunC.x - 15, y: sunC.y - 15, width: 30, height: 30)), with: .color(Color(hex: 0xFFFCE6)))

    // Far rose-ochre cape receding in coastal mist.
    var farCape = Path()
    farCape.move(to: CGPoint(x: w * 0.66, y: h * 0.54))
    farCape.addQuadCurve(to: CGPoint(x: w + 4, y: h * 0.475), control: CGPoint(x: w * 0.84, y: h * 0.46))
    farCape.addLine(to: CGPoint(x: w + 4, y: h * 0.55))
    farCape.closeSubpath()
    context.fill(farCape, with: .color(Color(hex: 0xD9A4A4).opacity(0.58)))

    // Sculpted burnt-terracotta headland cleanly below y = 0.45*h header band.
    var headland = Path()
    headland.move(to: CGPoint(x: -4, y: h * 0.54))
    headland.addLine(to: CGPoint(x: -4, y: h * 0.465))
    headland.addQuadCurve(to: CGPoint(x: w * 0.39, y: h * 0.535), control: CGPoint(x: w * 0.23, y: h * 0.448))
    headland.closeSubpath()
    let rockGrad = Gradient(colors: [Color(hex: 0xD97D63), Color(hex: 0x9C493A)])
    context.fill(headland, with: .linearGradient(rockGrad, startPoint: CGPoint(x: 0, y: h * 0.455), endPoint: CGPoint(x: 0, y: h * 0.535)))
    context.stroke(headland, with: .color(Color(hex: 0xFFF2DE).opacity(0.68)), lineWidth: 1.4)

    // Cutout glowing coastal sea arch cleanly above the curved bay lip (h * 0.52).
    var arch = Path()
    arch.addArc(center: CGPoint(x: w * 0.22, y: h * 0.518), radius: 13.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    arch.closeSubpath()
    context.fill(arch, with: .color(Color(hex: 0xFFF3E2)))

    // Swaying coastal palm on the open right cape balancing the left sea-arch headland asymmetrically.
    let sway = CGFloat(sin(t * 0.9)) * 2.8
    drawSwayingPalm(in: &context, base: CGPoint(x: w * 0.91, y: h * 0.505), height: 28, lean: -10 - sway, trunkColor: Color(hex: 0x7A493D), frondLight: Color(hex: 0x4E9470), frondDark: Color(hex: 0x357255))

    // Tiny distant paper-cut white sailboat on the right horizon.
    let bx = w * 0.85
    let by = h * 0.52 + CGFloat(sin(t * 1.1)) * 1.8
    var sail = Path()
    sail.move(to: CGPoint(x: bx, y: by - 19))
    sail.addQuadCurve(to: CGPoint(x: bx + 10, y: by - 4), control: CGPoint(x: bx + 8.5, y: by - 11))
    sail.addLine(to: CGPoint(x: bx, y: by - 4))
    sail.closeSubpath()
    context.fill(sail, with: .color(Color(hex: 0xFFFDF8)))
    var hull = Path()
    hull.move(to: CGPoint(x: bx - 8.5, y: by - 3))
    hull.addLine(to: CGPoint(x: bx + 11.5, y: by - 3))
    hull.addLine(to: CGPoint(x: bx + 7.5, y: by + 1))
    hull.addLine(to: CGPoint(x: bx - 5.5, y: by + 1))
    hull.closeSubpath()
    context.fill(hull, with: .color(Color(hex: 0xB85947)))

    // Soaring coastal gulls gliding cleanly in open right sky band (>= 0.45*h).
    let drift = CGFloat(sin(t * 0.4)) * 8
    for idx in 0..<3 {
        let gx = w * (0.46 + CGFloat(idx) * 0.11) + drift
        let gy = h * (0.462 + CGFloat(idx % 2) * 0.025)
        let flap = CGFloat(sin(t * 3.0 + Double(idx))) * 1.8
        var gull = Path()
        gull.move(to: CGPoint(x: gx - 7.5, y: gy + flap))
        gull.addQuadCurve(to: CGPoint(x: gx, y: gy + 2), control: CGPoint(x: gx - 3.8, y: gy - 2.8))
        gull.addQuadCurve(to: CGPoint(x: gx + 7.5, y: gy + flap), control: CGPoint(x: gx + 3.8, y: gy - 2.8))
        context.stroke(gull, with: .color(Color(hex: 0x7A5458).opacity(0.65)), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
    }
}

private func drawCoveWater(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    drawCurvedWaterBody(
        in: &context, size: size, topOffset: 8, curveAmp: 3.2, waveAmp: 1.8,
        colors: [Color(hex: 0x8DE5E8), Color(hex: 0x4EC3D6), Color(hex: 0x7CE0DE)],
        lipColor: Color(hex: 0xFFF7EB).opacity(0.82), time: t
    )

    // Three gently breathing scalloped white sea-foam shoreline arcs.
    let tide = CGFloat(sin(t * 0.95)) * 5.0
    for i in 0..<3 {
        let yBase = h * (0.68 + CGFloat(i) * 0.12) + tide * (1.0 - CGFloat(i) * 0.25)
        var foam = Path()
        foam.move(to: CGPoint(x: -4, y: yBase))
        foam.addQuadCurve(to: CGPoint(x: w * 0.50, y: yBase - 6), control: CGPoint(x: w * 0.24, y: yBase + 8))
        foam.addQuadCurve(to: CGPoint(x: w + 4, y: yBase), control: CGPoint(x: w * 0.76, y: yBase + 8))
        context.stroke(foam, with: .color(.white.opacity(0.80 - Double(i) * 0.18)), style: StrokeStyle(lineWidth: 3.4 - CGFloat(i) * 0.7, lineCap: .round))
    }
}

private func drawCoveForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.74,
        topColor: Color(hex: 0xFCE4C4), midColor: Color(hex: 0xF2CCA2), deepColor: Color(hex: 0xDEB082),
        rimColor: Color(hex: 0xFFF8EB)
    )

    // Swaying coastal sea-oat silhouettes framing far corners.
    let sway = CGFloat(sin(t * 1.1)) * 3.5
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.04, y: h * 0.90), height: h * 0.16, lean: 9 + sway, stemColor: Color(hex: 0xB8936A), headColor: Color(hex: 0xDFC194))
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.96, y: h * 0.90), height: h * 0.16, lean: -9 - sway, stemColor: Color(hex: 0xB8936A), headColor: Color(hex: 0xDFC194))

    // Pearly scallop shells & coral starfish tucked on the warm sand.
    let leftShell = CGRect(x: w * 0.11, y: h * 0.81, width: 16, height: 11)
    context.fill(Path(ellipseIn: leftShell), with: .color(Color(hex: 0xFFD9E2)))
    context.stroke(Path(ellipseIn: leftShell), with: .color(Color(hex: 0xD492A0)), lineWidth: 1.0)

    let rightShell = CGRect(x: w * 0.82, y: h * 0.82, width: 18, height: 12)
    context.fill(Path(ellipseIn: rightShell), with: .color(Color(hex: 0xFFF6EC)))
    context.stroke(Path(ellipseIn: rightShell), with: .color(Color(hex: 0xD6B59C)), lineWidth: 1.0)

    let sc = CGPoint(x: w * 0.18, y: h * 0.86)
    let sr: CGFloat = 7.5
    var star = Path()
    for p in 0..<10 {
        let angle = Double(p) * (Double.pi / 5.0) - Double.pi / 2.0
        let rad = p.isMultiple(of: 2) ? Double(sr) : Double(sr) * 0.42
        let pt = CGPoint(x: Double(sc.x) + cos(angle) * rad, y: Double(sc.y) + sin(angle) * rad)
        if p == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
    }
    star.closeSubpath()
    context.fill(star, with: .color(Color(hex: 0xFF8B7B)))
}

// MARK: - 6. Cloud Peak (.peak)

private func drawPeakBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0xFFE9D2), Color(hex: 0xFFD4AC), Color(hex: 0xFFF2D6)
    ])

    // Radiant Alto's Odyssey alpine sunrise orb nestled cleanly on mid-right horizon (>= 0.46*h).
    let sunC = CGPoint(x: w * 0.78, y: h * 0.468)
    context.fill(
        Path(ellipseIn: CGRect(x: sunC.x - 58, y: sunC.y - 58, width: 116, height: 116)),
        with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF5C2).opacity(0.88), Color(hex: 0xFFF5C2).opacity(0)]), center: sunC, startRadius: 8, endRadius: 58)
    )
    context.fill(Path(ellipseIn: CGRect(x: sunC.x - 17, y: sunC.y - 17, width: 34, height: 34)), with: .color(Color(hex: 0xFFFCE8)))

    // Multi-plane Alto's Odyssey faceted sweeping alpine peaks (all crests strictly >= 0.46*h).
    drawFacetedPeak(
        in: &context,
        apex: CGPoint(x: w * 0.56, y: h * 0.475),
        leftFoot: CGPoint(x: w * 0.24, y: h * 0.66),
        rightFoot: CGPoint(x: w * 0.88, y: h * 0.66),
        litColor: Color(hex: 0xF3D0B8),
        shadowColor: Color(hex: 0xB8A6CE),
        ridgeGlow: Color(hex: 0xFFF6E0)
    )
    drawFacetedPeak(
        in: &context,
        apex: CGPoint(x: w * 0.19, y: h * 0.462),
        leftFoot: CGPoint(x: -w * 0.14, y: h * 0.66),
        rightFoot: CGPoint(x: w * 0.52, y: h * 0.66),
        litColor: Color(hex: 0xF7C99E),
        shadowColor: Color(hex: 0x8F80B8),
        ridgeGlow: Color(hex: 0xFFF7E2)
    )
    drawFacetedPeak(
        in: &context,
        apex: CGPoint(x: w * 0.86, y: h * 0.485),
        leftFoot: CGPoint(x: w * 0.54, y: h * 0.67),
        rightFoot: CGPoint(x: w * 1.18, y: h * 0.67),
        litColor: Color(hex: 0xF5C39A),
        shadowColor: Color(hex: 0x7A6EA8),
        ridgeGlow: Color(hex: 0xFFF4D6)
    )

    // Billowing golden-rimmed multi-layer paper-cut sea of clouds rolling below the summit.
    let driftA = CGFloat(sin(t * 0.25)) * 12
    let driftB = CGFloat(cos(t * 0.22)) * 14
    drawCloudSeaBand(in: &context, width: w, baseY: h * 0.595, amp: 20, shift: driftA, color: Color(hex: 0xFBE8DF), highlight: Color(hex: 0xFFF9E6))
    drawCloudSeaBand(in: &context, width: w, baseY: h * 0.655, amp: 19, shift: -driftB, color: Color(hex: 0xF2DCE6), highlight: Color(hex: 0xFFFBF2))
    drawCloudSeaBand(in: &context, width: w, baseY: h * 0.715, amp: 16, shift: driftA * 0.7, color: Color(hex: 0xFFF9F4), highlight: .white)
}

private func drawCloudSeaBand(
    in context: inout GraphicsContext,
    width: CGFloat,
    baseY: CGFloat,
    amp: CGFloat,
    shift: CGFloat,
    color: Color,
    highlight: Color
) {
    var path = Path()
    path.move(to: CGPoint(x: -30, y: baseY + 60))
    path.addLine(to: CGPoint(x: -30, y: baseY))
    let puffs = 6
    let step = (width + 60) / CGFloat(puffs)
    for i in 0..<puffs {
        let x0 = -30 + CGFloat(i) * step + shift
        let x1 = x0 + step
        let crest = amp * (i.isMultiple(of: 2) ? 1.0 : 0.72)
        path.addQuadCurve(to: CGPoint(x: x1, y: baseY), control: CGPoint(x: (x0 + x1) * 0.5, y: baseY - crest))
    }
    path.addLine(to: CGPoint(x: width + 30, y: baseY + 60))
    path.closeSubpath()
    context.fill(path, with: .color(color))
    context.stroke(path, with: .color(highlight.opacity(0.85)), lineWidth: 1.8)
}

private func drawPeakForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.74,
        topColor: Color(hex: 0xB8DF84), midColor: Color(hex: 0x7EBF6B), deepColor: Color(hex: 0x4E8E55),
        rimColor: Color(hex: 0xF5FFCC)
    )

    // Charming trail stone cairn with fluttering miniature linen prayer-pennants on far left.
    let cx = w * 0.13
    let cy = h * 0.78
    var pole = Path()
    pole.move(to: CGPoint(x: cx, y: cy - 14))
    pole.addLine(to: CGPoint(x: cx + 2, y: cy - 42))
    context.stroke(pole, with: .color(Color(hex: 0x7A5B4B)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

    // Fluttering miniature prayer pennant string.
    let wave = CGFloat(sin(t * 2.2)) * 2.5
    var cord = Path()
    cord.move(to: CGPoint(x: cx + 2, y: cy - 40))
    cord.addQuadCurve(to: CGPoint(x: cx + 32, y: cy - 28 + wave), control: CGPoint(x: cx + 17, y: cy - 31 + wave * 0.5))
    context.stroke(cord, with: .color(Color(hex: 0x8F7668).opacity(0.7)), lineWidth: 0.9)
    let flags: [(CGFloat, CGFloat, Color)] = [(8, -36, Color(hex: 0xFF9E8C)), (16, -34, Color(hex: 0xFFE07A)), (24, -31, Color(hex: 0x8CDFF5))]
    for (dx, dy, col) in flags {
        var flag = Path()
        flag.move(to: CGPoint(x: cx + dx, y: cy + dy + wave * 0.4))
        flag.addLine(to: CGPoint(x: cx + dx + 6, y: cy + dy + 2 + wave * 0.5))
        flag.addLine(to: CGPoint(x: cx + dx + 2, y: cy + dy + 7 + wave * 0.6))
        flag.closeSubpath()
        context.fill(flag, with: .color(col))
    }

    context.fill(Path(ellipseIn: CGRect(x: cx - 12, y: cy - 5, width: 24, height: 10)), with: .color(Color(hex: 0xC4B4A4)))
    context.fill(Path(ellipseIn: CGRect(x: cx - 8.5, y: cy - 12, width: 17, height: 8.5)), with: .color(Color(hex: 0xDAD0C5)))
    context.fill(Path(ellipseIn: CGRect(x: cx - 5, y: cy - 17.5, width: 10, height: 6.5)), with: .color(Color(hex: 0xEDE5DC)))

    // Swaying alpine grass & pastel alpine wildflowers on right ridge.
    let sway = CGFloat(sin(t * 1.3)) * 3.5
    for idx in 0..<5 {
        let gx = w * (0.79 + CGFloat(idx) * 0.042)
        let gy = h * 0.80 + CGFloat(idx % 2) * 8
        var blade = Path()
        blade.move(to: CGPoint(x: gx, y: gy))
        blade.addQuadCurve(to: CGPoint(x: gx + sway + 4, y: gy - 16), control: CGPoint(x: gx + 2, y: gy - 9))
        context.stroke(blade, with: .color(Color(hex: 0x4E8C54)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        if idx.isMultiple(of: 2) {
            context.fill(Path(ellipseIn: CGRect(x: gx + sway + 1.5, y: gy - 19, width: 5, height: 5)), with: .color(Color(hex: 0xFFF3B8)))
        }
    }
}

// MARK: - 7. Lantern Grove (.grove)

private func drawGroveBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0x24244E), Color(hex: 0x382B64), Color(hex: 0x604484), Color(hex: 0x946292)
    ])

    // Delicate twilight 6-point starlets strictly clear of top-left header band (x < 0.68, y < 0.44*h).
    for i in 0..<12 {
        let seed = Double(i) + 43.0
        let x = w * (0.06 + CGFloat(journeyNoise(seed, 1.2)) * 0.88)
        let y = h * (0.43 + CGFloat(journeyNoise(seed, 2.2)) * 0.08)
        if x < w * 0.68 && y < h * 0.45 { continue }
        let twinkle = 0.25 + 0.55 * (0.5 + 0.5 * sin(t * 1.3 + seed))
        if i.isMultiple(of: 4) {
            let s: CGFloat = 3.6
            context.fill(StarletShape().path(in: CGRect(x: x - s, y: y - s, width: s * 2, height: s * 2)), with: .color(Color(hex: 0xFFF3D6).opacity(twinkle)))
        } else {
            let r = CGFloat(1.1 + journeyNoise(seed, 3.2) * 1.1)
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFF3D6).opacity(twinkle)))
        }
    }

    // Distant twilight hill & silhouetted garden torii/pavilion roof in mist.
    var farHill = Path()
    farHill.move(to: CGPoint(x: 0, y: h * 0.78))
    farHill.addLine(to: CGPoint(x: 0, y: h * 0.60))
    farHill.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.56), control: CGPoint(x: w * 0.26, y: h * 0.51))
    farHill.addQuadCurve(to: CGPoint(x: w, y: h * 0.61), control: CGPoint(x: w * 0.78, y: h * 0.52))
    farHill.addLine(to: CGPoint(x: w, y: h * 0.78))
    farHill.closeSubpath()
    context.fill(farHill, with: .color(Color(hex: 0x392C60).opacity(0.86)))

    // Distant silhouetted pavilion roofline on right crest.
    let px = w * 0.78
    let py = h * 0.555
    var roof = Path()
    roof.move(to: CGPoint(x: px - 26, y: py))
    roof.addQuadCurve(to: CGPoint(x: px, y: py - 13), control: CGPoint(x: px - 10, y: py - 4))
    roof.addQuadCurve(to: CGPoint(x: px + 26, y: py), control: CGPoint(x: px + 10, y: py - 4))
    roof.closeSubpath()
    context.fill(roof, with: .color(Color(hex: 0x2B204C).opacity(0.85)))
    context.fill(Path(CGRect(x: px - 14, y: py, width: 3.5, height: 18)), with: .color(Color(hex: 0x2B204C).opacity(0.8)))
    context.fill(Path(CGRect(x: px + 10.5, y: py, width: 3.5, height: 18)), with: .color(Color(hex: 0x2B204C).opacity(0.8)))

    // Gnarled cherry-blossom boughs arching organically from mid-left & upper-right (>= 0.44*h clear of header!).
    drawBlossomBough(in: &context, start: CGPoint(x: -6, y: h * 0.485), end: CGPoint(x: w * 0.40, y: h * 0.53), ctrl: CGPoint(x: w * 0.18, y: h * 0.468))
    drawBlossomBough(in: &context, start: CGPoint(x: w + 6, y: h * 0.445), end: CGPoint(x: w * 0.58, y: h * 0.515), ctrl: CGPoint(x: w * 0.80, y: h * 0.442))

    // Five softly swaying hand-ribbed paper lanterns (including Dewy's glowing aqua lantern!).
    drawGroveLanterns(in: &context, size: size, time: t)
}

private func drawGroveLanterns(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    let lanterns: [(xf: CGFloat, yf: CGFloat, aqua: Bool, phase: Double)] = [
        (0.14, 0.54, false, 0.2), (0.32, 0.575, false, 1.5), (0.50, 0.60, true, 2.6),
        (0.70, 0.56, false, 3.8), (0.86, 0.515, false, 5.0)
    ]
    for item in lanterns {
        let swing = CGFloat(sin(t * 1.15 + item.phase)) * 3.0
        let anchor = CGPoint(x: w * item.xf, y: h * item.yf - 18)
        let c = CGPoint(x: anchor.x + swing, y: h * item.yf + 4)

        var cord = Path()
        cord.move(to: anchor)
        cord.addLine(to: CGPoint(x: c.x, y: c.y - 11))
        context.stroke(cord, with: .color(Color(hex: 0x221836).opacity(0.8)), lineWidth: 1.1)

        let haloCol = item.aqua ? Color(hex: 0x8AF0FF) : Color(hex: 0xFFE08C)
        let bodyCol = item.aqua ? Color(hex: 0x8CEBFC) : Color(hex: 0xFFCE80)
        let glowR: CGFloat = 34 * CGFloat(0.88 + 0.12 * sin(t * 2.8 + item.phase))
        context.fill(
            Path(ellipseIn: CGRect(x: c.x - glowR, y: c.y - glowR, width: glowR * 2, height: glowR * 2)),
            with: .radialGradient(Gradient(colors: [haloCol.opacity(0.78), haloCol.opacity(0)]), center: c, startRadius: 2, endRadius: glowR)
        )

        let bodyRect = CGRect(x: c.x - 8.5, y: c.y - 10.5, width: 17, height: 21)
        context.fill(Path(roundedRect: bodyRect, cornerRadius: 7.5), with: .color(bodyCol))

        // Hand-ribbed lantern lines & wooden caps + tiny hanging tassel.
        for rib in [-4.0, 0.0, 4.0] {
            var line = Path()
            line.move(to: CGPoint(x: bodyRect.minX + 1.5, y: c.y + CGFloat(rib)))
            line.addLine(to: CGPoint(x: bodyRect.maxX - 1.5, y: c.y + CGFloat(rib)))
            context.stroke(line, with: .color(Color(hex: 0x5C3A52).opacity(0.28)), lineWidth: 0.7)
        }
        context.fill(Path(roundedRect: CGRect(x: c.x - 4.5, y: bodyRect.minY - 2, width: 9, height: 2.5), cornerRadius: 1), with: .color(Color(hex: 0x38254A)))
        context.fill(Path(roundedRect: CGRect(x: c.x - 4.5, y: bodyRect.maxY - 0.5, width: 9, height: 2.5), cornerRadius: 1), with: .color(Color(hex: 0x38254A)))
        var tassel = Path()
        tassel.move(to: CGPoint(x: c.x, y: bodyRect.maxY + 2))
        tassel.addLine(to: CGPoint(x: c.x + swing * 0.25, y: bodyRect.maxY + 8))
        context.stroke(tassel, with: .color(Color(hex: 0xE89BB5).opacity(0.8)), lineWidth: 1.2)
    }
}

private func drawBlossomBough(in context: inout GraphicsContext, start: CGPoint, end: CGPoint, ctrl: CGPoint) {
    var branch = Path()
    branch.move(to: start)
    branch.addQuadCurve(to: end, control: ctrl)
    context.stroke(branch, with: .color(Color(hex: 0x3D294D)), style: StrokeStyle(lineWidth: 5.0, lineCap: .round))

    // Layered multi-tone painterly pink cherry-blossom clusters.
    for i in 0..<6 {
        let u = CGFloat(i) / 5.0
        let inv = 1.0 - u
        let bx = inv * inv * start.x + 2 * inv * u * ctrl.x + u * u * end.x
        let by = inv * inv * start.y + 2 * inv * u * ctrl.y + u * u * end.y
        let r: CGFloat = 14 + CGFloat(i % 2) * 5
        context.fill(Path(ellipseIn: CGRect(x: bx - r, y: by - r * 0.8, width: r * 2, height: r * 1.6)), with: .color(Color(hex: 0xDF7EAD).opacity(0.88)))
        context.fill(Path(ellipseIn: CGRect(x: bx - r * 0.72, y: by - r * 0.92, width: r * 1.5, height: r * 1.2)), with: .color(Color(hex: 0xFFC2DF).opacity(0.92)))
    }
}

private func drawGroveForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.75,
        topColor: Color(hex: 0x7A659E), midColor: Color(hex: 0x57457D), deepColor: Color(hex: 0x3A2E5C),
        rimColor: Color(hex: 0xE5C6F5)
    )

    // Drifting sakura blossom petals tumbling gently through twilight air.
    for i in 0..<14 {
        let seed = Double(i) + 51.0
        let cycle = (t * (0.14 + journeyNoise(seed, 1.5) * 0.1) + journeyNoise(seed, 2.5)).truncatingRemainder(dividingBy: 1.0)
        let x = w * CGFloat(journeyNoise(seed, 3.5)) + CGFloat(sin(t * 1.1 + seed)) * 18
        let y = h * 0.34 + CGFloat(cycle) * h * 0.56
        let rot = Angle.radians(t * 1.6 + seed)
        let alpha = sin(cycle * Double.pi) * 0.9

        context.drawLayer { layer in
            layer.opacity = alpha
            layer.translateBy(x: x, y: y)
            layer.rotate(by: rot)
            let petalRect = CGRect(x: -4.2, y: -5.0, width: 8.4, height: 10.0)
            layer.fill(BlossomPetalShape().path(in: petalRect), with: .color(Color(hex: 0xFFC4E0)))
        }
    }
}

// MARK: - 8. Starlight Lake (.lake)

private func drawLakeBackdrop(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height
    fillVerticalSky(in: &context, size: size, colors: [
        Color(hex: 0x131B3E), Color(hex: 0x1D2859), Color(hex: 0x2B3672), Color(hex: 0x414C8C)
    ])

    // Delicate 6-point StarletShape constellation strictly below header safe band (>= 0.45*h).
    let leftStars: [CGPoint] = [
        CGPoint(x: w * 0.10, y: h * 0.472), CGPoint(x: w * 0.19, y: h * 0.456),
        CGPoint(x: w * 0.29, y: h * 0.492), CGPoint(x: w * 0.37, y: h * 0.468)
    ]
    var constLine = Path()
    for (idx, pt) in leftStars.enumerated() {
        if idx == 0 { constLine.move(to: pt) } else { constLine.addLine(to: pt) }
    }
    context.stroke(constLine, with: .color(Color(hex: 0xD2DCFF).opacity(0.28)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round, dash: [3, 3]))
    for (idx, pt) in leftStars.enumerated() {
        let pulse = 0.65 + 0.35 * sin(t * 1.5 + Double(idx))
        let s: CGFloat = 4.0
        context.fill(StarletShape().path(in: CGRect(x: pt.x - s, y: pt.y - s, width: s * 2, height: s * 2)), with: .color(Color(hex: 0xFFF7D6).opacity(pulse)))
    }

    // Crisp pearl starfield strictly below header band (y >= 0.445*h).
    for i in 0..<22 {
        let seed = Double(i) + 71.0
        let x = w * CGFloat(journeyNoise(seed, 1.6))
        let y = h * (0.448 + CGFloat(journeyNoise(seed, 2.6)) * 0.085)
        let twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * (1.2 + journeyNoise(seed, 3.6) * 1.6) + seed))
        if i.isMultiple(of: 6) {
            let s: CGFloat = 3.6
            context.fill(StarletShape().path(in: CGRect(x: x - s, y: y - s, width: s * 2, height: s * 2)), with: .color(Color(hex: 0xFFF7D6).opacity(twinkle)))
        } else {
            let r = CGFloat(1.0 + journeyNoise(seed, 4.6) * 1.3)
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFFDF8).opacity(twinkle)))
        }
    }

    // Luminous crescent moon serenely positioned in open right mid-sky (cleanly clear of header & peaks).
    drawJourneyMoon(in: &context, center: CGPoint(x: w * 0.80, y: h * 0.468), radius: min(w * 0.048, 18))

    // 3-plane misty pine mountain ridges (strictly >= 0.495*h).
    var farPeaks = Path()
    farPeaks.move(to: CGPoint(x: 0, y: h * 0.58))
    farPeaks.addLine(to: CGPoint(x: w * 0.16, y: h * 0.495))
    farPeaks.addLine(to: CGPoint(x: w * 0.36, y: h * 0.54))
    farPeaks.addLine(to: CGPoint(x: w * 0.60, y: h * 0.525))
    farPeaks.addLine(to: CGPoint(x: w * 0.88, y: h * 0.505))
    farPeaks.addLine(to: CGPoint(x: w, y: h * 0.54))
    farPeaks.addLine(to: CGPoint(x: w, y: h * 0.62))
    farPeaks.addLine(to: CGPoint(x: 0, y: h * 0.62))
    farPeaks.closeSubpath()
    context.fill(farPeaks, with: .color(Color(hex: 0x2B346E).opacity(0.82)))

    var midRidge = Path()
    midRidge.move(to: CGPoint(x: 0, y: h * 0.58))
    midRidge.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.555), control: CGPoint(x: w * 0.22, y: h * 0.515))
    midRidge.addQuadCurve(to: CGPoint(x: w, y: h * 0.57), control: CGPoint(x: w * 0.78, y: h * 0.52))
    midRidge.addLine(to: CGPoint(x: w, y: h * 0.62))
    midRidge.addLine(to: CGPoint(x: 0, y: h * 0.62))
    midRidge.closeSubpath()
    context.fill(midRidge, with: .color(Color(hex: 0x1A2152)))

    let pines: [(CGFloat, CGFloat)] = [
        (0.04, 0.085), (0.11, 0.105), (0.18, 0.080), (0.25, 0.065),
        (0.76, 0.068), (0.84, 0.088), (0.91, 0.102), (0.97, 0.082)
    ]
    for (xf, hf) in pines {
        drawJourneyPine(in: &context, base: CGPoint(x: w * xf, y: h * 0.575), height: h * hf, color: Color(hex: 0x10163B))
    }
}

private func drawLakeWater(in context: inout GraphicsContext, fullSize: CGSize, bandSize: CGSize, time t: Double) {
    let w = bandSize.width
    let h = bandSize.height
    drawCurvedWaterBody(
        in: &context, size: bandSize, topOffset: 9, curveAmp: 3.4, waveAmp: 1.0,
        colors: [Color(hex: 0x313C7E), Color(hex: 0x1F2760), Color(hex: 0x151B48)],
        lipColor: Color(hex: 0xB8C6F8).opacity(0.62), lipWidth: 2.0, time: t
    )

    // Soft inverted shoreline pine reflections.
    context.fill(Path(ellipseIn: CGRect(x: -10, y: 8, width: w * 0.30, height: 24)), with: .color(Color(hex: 0x0F153A).opacity(0.45)))
    context.fill(Path(ellipseIn: CGRect(x: w * 0.72, y: 8, width: w * 0.32, height: 24)), with: .color(Color(hex: 0x0F153A).opacity(0.45)))

    // Cascading golden-ivory moon-path reflections.
    let mx = fullSize.width * 0.78
    for row in 0..<7 {
        let y = 12 + CGFloat(row) * 14
        if y > h - 8 { break }
        let shimmer = 0.8 + 0.2 * sin(t * 1.4 + Double(row))
        let halfW = CGFloat(max(24.0 - Double(row) * 2.5, 6.0)) * CGFloat(shimmer)
        var stripe = Path()
        stripe.move(to: CGPoint(x: mx - halfW, y: y))
        stripe.addLine(to: CGPoint(x: mx + halfW, y: y))
        context.stroke(stripe, with: .color(Color(hex: 0xFFF5D0).opacity(0.56 - Double(row) * 0.06)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
    }

    // Mirrored glowing star-shimmers in the still alpine lake.
    for i in 0..<12 {
        let seed = Double(i) + 91.0
        let x = w * CGFloat(journeyNoise(seed, 1.8))
        let y = h * (0.18 + CGFloat(journeyNoise(seed, 2.8)) * 0.65)
        let alpha = 0.25 + 0.50 * (0.5 + 0.5 * sin(t * 1.5 + seed))
        context.fill(Path(ellipseIn: CGRect(x: x - 2.8, y: y - 1.1, width: 5.6, height: 2.2)), with: .color(Color(hex: 0xFFF4D0).opacity(alpha)))
    }
}

private func drawLakeForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
    let w = size.width
    let h = size.height

    drawForegroundLedge(
        in: &context, size: size, topY: h * 0.75,
        topColor: Color(hex: 0x34447A), midColor: Color(hex: 0x222D5C), deepColor: Color(hex: 0x161D42),
        rimColor: Color(hex: 0x9BB0F0)
    )

    // Swaying reed silhouettes framing both foreground corners.
    let sway = CGFloat(sin(t * 0.9)) * 3.0
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.05, y: h * 0.91), height: h * 0.18, lean: 7 + sway, stemColor: Color(hex: 0x111738), headColor: Color(hex: 0x1C244E))
    drawCattailReed(in: &context, base: CGPoint(x: w * 0.95, y: h * 0.91), height: h * 0.18, lean: -7 - sway, stemColor: Color(hex: 0x111738), headColor: Color(hex: 0x1C244E))

    // Warm glowing amber fireflies drifting gently across the lakeside bank.
    for i in 0..<11 {
        let seed = Double(i) + 101.0
        let x = w * (0.08 + CGFloat(journeyNoise(seed, 1.9)) * 0.84) + CGFloat(sin(t * 0.55 + seed)) * 14
        let y = h * (0.48 + CGFloat(journeyNoise(seed, 2.9)) * 0.34) + CGFloat(cos(t * 0.45 + seed)) * 9
        let glow = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 1.7 + seed * 1.6))

        let haloR: CGFloat = 11
        context.fill(
            Path(ellipseIn: CGRect(x: x - haloR, y: y - haloR, width: haloR * 2, height: haloR * 2)),
            with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE38A).opacity(0.65 * glow), Color(hex: 0xFFB84D).opacity(0)]), center: CGPoint(x: x, y: y), startRadius: 1, endRadius: haloR)
        )
        context.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)), with: .color(Color(hex: 0xFFFAD6).opacity(glow)))
    }
}

// MARK: - Onboarding Golden-Dawn Sanctuary Panorama

/// Lush golden-apricot sunrise over a layered lagoon archipelago for Onboarding Step 0.
struct OnboardingPanoramaView: View {
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Group {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
                        let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : 14.2
                        composedOnboarding(size: size, time: t)
                    }
                } else {
                    composedOnboarding(size: size, time: 14.2)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }

    private func composedOnboarding(size: CGSize, time t: Double) -> some View {
        let horizon = size.height * 0.56
        let waterTop = max(horizon - 6, 0)
        let pondHeight = max(size.height - waterTop, 1)

        return ZStack(alignment: .topLeading) {
            Canvas { context, s in
                drawOnboardingSkyAndArchipelago(in: &context, size: s, horizon: horizon, time: t)
            }
            .gouacheBloom(0.032)

            Canvas { context, s in
                drawOnboardingWater(in: &context, size: s, time: t)
            }
            .frame(width: size.width, height: pondHeight)
            .pondCaustics(time: t, tint: Color(hex: 0xFFF3D4), strength: 0.19)
            .offset(y: waterTop)

            Canvas { context, s in
                drawOnboardingForeground(in: &context, size: s, time: t)
            }
        }
        .paperGrain(0.026)
    }

    private func drawOnboardingSkyAndArchipelago(in context: inout GraphicsContext, size: CGSize, horizon: CGFloat, time t: Double) {
        let w = size.width
        fillVerticalSky(in: &context, size: size, colors: [
            Color(hex: 0xA8DCF2), Color(hex: 0xF7CBB5), Color(hex: 0xFFEED2)
        ])

        // Radiant sunrise orb & warm diagonal dawn sunbeams.
        let sunC = CGPoint(x: w * 0.68, y: horizon * 0.54)
        context.fill(
            Path(ellipseIn: CGRect(x: sunC.x - 105, y: sunC.y - 105, width: 210, height: 210)),
            with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF6C8).opacity(0.88), Color(hex: 0xFFF6C8).opacity(0)]), center: sunC, startRadius: 8, endRadius: 105)
        )
        context.fill(Path(ellipseIn: CGRect(x: sunC.x - 24, y: sunC.y - 24, width: 48, height: 48)), with: .color(Color(hex: 0xFFFDE8)))

        // Warm-rimmed Studio Ghibli cumulus clouds.
        let drift = CGFloat(sin(t * 0.22)) * 12
        drawGhibliCloud(in: &context, center: CGPoint(x: w * 0.22 + drift, y: horizon * 0.34), width: w * 0.32, lit: Color(hex: 0xFFF9F0), rim: Color(hex: 0xFFFDE8), shade: Color(hex: 0xF2C2B4), alpha: 0.92)
        drawGhibliCloud(in: &context, center: CGPoint(x: w * 0.80 - drift * 0.8, y: horizon * 0.64), width: w * 0.30, lit: Color(hex: 0xFFFBF5), rim: .white, shade: Color(hex: 0xEFC1B5), alpha: 0.88)

        // 3 atmospheric layered lagoon archipelago islands.
        var farIsland = Path()
        farIsland.move(to: CGPoint(x: w * 0.22, y: horizon + 8))
        farIsland.addQuadCurve(to: CGPoint(x: w * 0.56, y: horizon + 8), control: CGPoint(x: w * 0.39, y: horizon - 28))
        farIsland.closeSubpath()
        context.fill(farIsland, with: .color(Color(hex: 0xB8C7CE).opacity(0.65)))

        var leftCape = Path()
        leftCape.move(to: CGPoint(x: -6, y: horizon + 10))
        leftCape.addQuadCurve(to: CGPoint(x: w * 0.36, y: horizon + 10), control: CGPoint(x: w * 0.14, y: horizon - 46))
        leftCape.closeSubpath()
        context.fill(leftCape, with: .color(Color(hex: 0x7DB9AA)))

        var rightSpit = Path()
        rightSpit.move(to: CGPoint(x: w * 0.66, y: horizon + 10))
        rightSpit.addQuadCurve(to: CGPoint(x: w + 6, y: horizon + 10), control: CGPoint(x: w * 0.86, y: horizon - 42))
        rightSpit.closeSubpath()
        context.fill(rightSpit, with: .color(Color(hex: 0x5EA38D)))

        // Gracefully swaying silhouetted tropical palms on far right spit.
        let sway = CGFloat(sin(t * 0.85)) * 4.0
        drawSwayingPalm(in: &context, base: CGPoint(x: w * 0.87, y: horizon - 14), height: 56, lean: -14 - sway, trunkColor: Color(hex: 0x5C453E), frondLight: Color(hex: 0x3D7A67), frondDark: Color(hex: 0x29594D))
        drawSwayingPalm(in: &context, base: CGPoint(x: w * 0.94, y: horizon - 10), height: 42, lean: -7 - sway * 0.7, trunkColor: Color(hex: 0x5C453E), frondLight: Color(hex: 0x458570), frondDark: Color(hex: 0x2F6355))
    }

    private func drawOnboardingWater(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        drawCurvedWaterBody(
            in: &context, size: size, topOffset: 8, curveAmp: 3.0, waveAmp: 1.5,
            colors: [Color(hex: 0xA8E7EC), Color(hex: 0x5CC0DC), Color(hex: 0x8FDDF0)],
            lipColor: Color(hex: 0xFFF7E8).opacity(0.80), time: t
        )

        // Glittering golden sun-path dancing across the turquoise bay.
        let cx = size.width * 0.68
        for row in 0..<7 {
            let y = 14 + CGFloat(row) * 15
            if y > size.height - 8 { break }
            let half = CGFloat(max(32.0 - Double(row) * 3.4, 8.0)) * CGFloat(0.84 + 0.16 * sin(t * 1.4 + Double(row)))
            var stripe = Path()
            stripe.move(to: CGPoint(x: cx - half, y: y))
            stripe.addLine(to: CGPoint(x: cx + half, y: y))
            context.stroke(stripe, with: .color(Color(hex: 0xFFF6D0).opacity(0.62 - Double(row) * 0.07)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        }
    }

    private func drawOnboardingForeground(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let w = size.width
        let h = size.height
        let sway = CGFloat(sin(t * 1.0)) * 3.0

        // Delicate shore reeds & wildflower silhouettes framing far lower edges.
        drawCattailReed(in: &context, base: CGPoint(x: w * 0.04, y: h * 0.88), height: h * 0.16, lean: 8 + sway, stemColor: Color(hex: 0x4A8C74).opacity(0.65), headColor: Color(hex: 0x8F6B54).opacity(0.65))
        drawCattailReed(in: &context, base: CGPoint(x: w * 0.96, y: h * 0.88), height: h * 0.16, lean: -8 - sway, stemColor: Color(hex: 0x4A8C74).opacity(0.65), headColor: Color(hex: 0x8F6B54).opacity(0.65))

        // Drifting warm sunrise pollen motes.
        for i in 0..<10 {
            let seed = Double(i) + 121.0
            let x = w * CGFloat(journeyNoise(seed, 1.1)) + CGFloat(sin(t * 0.5 + seed)) * 10
            let y = h * (0.18 + CGFloat(journeyNoise(seed, 2.1)) * 0.56) + CGFloat(cos(t * 0.4 + seed)) * 8
            let alpha = 0.25 + 0.55 * (0.5 + 0.5 * sin(t * 1.3 + seed))
            let r = CGFloat(1.8 + journeyNoise(seed, 3.1) * 2.2)
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFF6C8).opacity(alpha)))
        }
    }
}

// MARK: - Dewy+ Celestial Storybook Pavilion Panorama

/// Radiant Monument Valley celestial floating sanctuaries tucked along outer flanks,
/// translucent pastel rainbow halo, cloud terraces, opalescent mirror pool & 6-point starlets.
struct PaywallPanoramaView: View {
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Group {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
                        let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : 14.2
                        composedPaywall(size: size, time: t)
                    }
                } else {
                    composedPaywall(size: size, time: 14.2)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }

    private func composedPaywall(size: CGSize, time t: Double) -> some View {
        let poolTop = size.height * 0.66
        let waterTop = max(poolTop - 6, 0)
        let poolHeight = max(size.height - waterTop, 1)

        return ZStack(alignment: .topLeading) {
            Canvas { context, s in
                drawPaywallSanctuary(in: &context, size: s, poolTop: poolTop, time: t)
            }
            .gouacheBloom(0.032)

            Canvas { context, s in
                drawPaywallPool(in: &context, size: s, time: t)
            }
            .frame(width: size.width, height: poolHeight)
            .pondCaustics(time: t, tint: Color(hex: 0xFFF0FA), strength: 0.18)
            .offset(y: waterTop)

            Canvas { context, s in
                drawPaywallStarlets(in: &context, size: s, time: t)
            }
        }
        .paperGrain(0.026)
    }

    private func drawPaywallSanctuary(in context: inout GraphicsContext, size: CGSize, poolTop: CGFloat, time t: Double) {
        let w = size.width
        let h = size.height

        fillVerticalSky(in: &context, size: size, colors: [
            Color(hex: 0xB8AEF8), Color(hex: 0xE2C1F6), Color(hex: 0xFFD9DE), Color(hex: 0xFFF3DE)
        ])

        // Radiant central celestial glow behind crowned Dewy.
        let centerHalo = CGPoint(x: w * 0.50, y: poolTop - 34)
        let haloR = min(w * 0.60, 230)
        context.fill(
            Path(ellipseIn: CGRect(x: centerHalo.x - haloR, y: centerHalo.y - haloR, width: haloR * 2, height: haloR * 2)),
            with: .radialGradient(Gradient(colors: [Color(hex: 0xFFFDF0).opacity(0.78), Color(hex: 0xFFFDF0).opacity(0)]), center: centerHalo, startRadius: 8, endRadius: haloR)
        )

        // Soft translucent 5-band watercolor rainbow halo overarching the pavilion.
        let bands: [Color] = [
            Color(hex: 0xFF9EB5), Color(hex: 0xFFD08C), Color(hex: 0xB4ECA8), Color(hex: 0x98E3FA), Color(hex: 0xCBB5FF)
        ]
        let arcR = min(w * 0.47, h * 0.44)
        for (idx, col) in bands.enumerated() {
            let r = arcR - CGFloat(idx) * 5.0
            var arc = Path()
            arc.addArc(center: CGPoint(x: w * 0.50, y: poolTop + 8), radius: r, startAngle: .degrees(190), endAngle: .degrees(350), clockwise: false)
            context.stroke(arc, with: .color(col.opacity(0.46)), style: StrokeStyle(lineWidth: 5.0, lineCap: .round))
        }

        // Billowing pastel-gold cloud terraces rolling along the horizon.
        let drift = CGFloat(sin(t * 0.24)) * 8
        drawCloudSeaBand(in: &context, width: w, baseY: poolTop - 8, amp: 20, shift: drift, color: Color(hex: 0xEFE2FF), highlight: Color(hex: 0xFFFDF4))
        drawCloudSeaBand(in: &context, width: w, baseY: poolTop + 4, amp: 14, shift: -drift * 0.8, color: Color(hex: 0xFFF7FC), highlight: .white)

        // Monument Valley floating arched sanctuaries tucked gracefully along outer flanks (leaving center & upper-mid-left clear!).
        let bobL = CGFloat(sin(t * 0.78)) * 3.0
        let bobR = CGFloat(sin(t * 0.78 + 1.6)) * 3.0
        drawMonumentSanctuary(in: &context, center: CGPoint(x: w * 0.12, y: poolTop - 16 + bobL), flip: false, time: t)
        drawMonumentSanctuary(in: &context, center: CGPoint(x: w * 0.88, y: poolTop - 18 + bobR), flip: true, time: t)
    }

    private func drawMonumentSanctuary(in context: inout GraphicsContext, center: CGPoint, flip: Bool, time t: Double) {
        let dir: CGFloat = flip ? -1 : 1
        // Billowing pastel-gold cloud pedestal.
        drawGhibliCloud(in: &context, center: CGPoint(x: center.x, y: center.y + 18), width: 82, lit: Color(hex: 0xFFF9FE), rim: .white, shade: Color(hex: 0xDBC9F5), alpha: 0.96)

        // Stepped rose-ivory marble base terrace.
        let terrace = CGRect(x: center.x - 26, y: center.y - 2, width: 52, height: 12)
        context.fill(Path(roundedRect: terrace, cornerRadius: 2.5), with: .linearGradient(Gradient(colors: [Color(hex: 0xFFFBF8), Color(hex: 0xE8D8F2)]), startPoint: CGPoint(x: terrace.minX, y: terrace.minY), endPoint: CGPoint(x: terrace.maxX, y: terrace.maxY)))
        context.stroke(Path(roundedRect: terrace, cornerRadius: 2.5), with: .color(Color(hex: 0x9C86C8).opacity(0.42)), lineWidth: 0.8)

        // Side lancet arch gallery & tall stepped main spire tower.
        let mainX = center.x - dir * 5
        let mainRect = CGRect(x: mainX - 11, y: center.y - 34, width: 22, height: 34)
        context.fill(Path(roundedRect: mainRect, cornerRadius: 2), with: .linearGradient(Gradient(colors: [Color(hex: 0xFFFDFB), Color(hex: 0xEFE1F7)]), startPoint: CGPoint(x: mainRect.minX, y: mainRect.minY), endPoint: CGPoint(x: mainRect.maxX, y: mainRect.maxY)))
        context.stroke(Path(roundedRect: mainRect, cornerRadius: 2), with: .color(Color(hex: 0x9C86C8).opacity(0.45)), lineWidth: 0.8)

        // Secondary flanking turret.
        let sideX = center.x + dir * 15
        let sideRect = CGRect(x: sideX - 7, y: center.y - 22, width: 14, height: 22)
        context.fill(Path(roundedRect: sideRect, cornerRadius: 2), with: .color(Color(hex: 0xF7ECFA)))
        context.stroke(Path(roundedRect: sideRect, cornerRadius: 2), with: .color(Color(hex: 0x9C86C8).opacity(0.40)), lineWidth: 0.8)

        // Antique-brass curved spires & needle finials.
        for (tx, topY, halfW, spireH) in [(mainX, mainRect.minY, CGFloat(13), CGFloat(20)), (sideX, sideRect.minY, CGFloat(8.5), CGFloat(12))] {
            var spire = Path()
            spire.move(to: CGPoint(x: tx - halfW, y: topY))
            spire.addQuadCurve(to: CGPoint(x: tx, y: topY - spireH), control: CGPoint(x: tx - halfW * 0.25, y: topY - spireH * 0.58))
            spire.addQuadCurve(to: CGPoint(x: tx + halfW, y: topY), control: CGPoint(x: tx + halfW * 0.25, y: topY - spireH * 0.58))
            spire.closeSubpath()
            context.fill(spire, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE394), Color(hex: 0xD9A44C)]), startPoint: CGPoint(x: tx - halfW, y: topY - spireH), endPoint: CGPoint(x: tx + halfW, y: topY)))
        }

        // Graceful lancet arched doorway & warm glowing upper window.
        var arch = Path()
        arch.move(to: CGPoint(x: mainX - 4.5, y: center.y))
        arch.addLine(to: CGPoint(x: mainX - 4.5, y: center.y - 12))
        arch.addQuadCurve(to: CGPoint(x: mainX, y: center.y - 18), control: CGPoint(x: mainX - 4.5, y: center.y - 16))
        arch.addQuadCurve(to: CGPoint(x: mainX + 4.5, y: center.y - 12), control: CGPoint(x: mainX + 4.5, y: center.y - 16))
        arch.addLine(to: CGPoint(x: mainX + 4.5, y: center.y))
        arch.closeSubpath()
        context.fill(arch, with: .color(Color(hex: 0x9A84CF).opacity(0.55)))

        let win = CGRect(x: mainX - 2.6, y: mainRect.minY + 7, width: 5.2, height: 8.5)
        context.fill(Path(roundedRect: win, cornerRadius: 2.6), with: .color(Color(hex: 0xFFF3B8)))

        // Fluttering silk spire pennant.
        let wave = CGFloat(sin(t * 2.1)) * 2.0
        let tip = CGPoint(x: mainX, y: mainRect.minY - 20)
        var flag = Path()
        flag.move(to: tip)
        flag.addQuadCurve(to: CGPoint(x: tip.x + dir * 10, y: tip.y + 2 + wave), control: CGPoint(x: tip.x + dir * 5, y: tip.y - 1.5 - wave))
        flag.addLine(to: CGPoint(x: tip.x, y: tip.y + 4))
        flag.closeSubpath()
        context.fill(flag, with: .color(Color(hex: 0xFFAEC8)))
    }

    private func drawPaywallPool(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        drawCurvedWaterBody(
            in: &context, size: size, topOffset: 8, curveAmp: 3.2, waveAmp: 1.4,
            colors: [Color(hex: 0xD8D4FA), Color(hex: 0xA8C8FA), Color(hex: 0xFAF4EA)],
            lipColor: Color(hex: 0xFFF9FF).opacity(0.86), time: t
        )

        for i in 0..<5 {
            let y = 16 + CGFloat(i) * 14
            if y > size.height - 6 { break }
            let half = CGFloat(max(42.0 - Double(i) * 5.0, 14.0)) * CGFloat(0.88 + 0.12 * sin(t * 1.2 + Double(i)))
            var line = Path()
            line.move(to: CGPoint(x: size.width * 0.5 - half, y: y))
            line.addLine(to: CGPoint(x: size.width * 0.5 + half, y: y))
            context.stroke(line, with: .color(.white.opacity(0.52 - Double(i) * 0.08)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        }
    }

    private func drawPaywallStarlets(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        for i in 0..<14 {
            let seed = Double(i) + 141.0
            let x = size.width * CGFloat(journeyNoise(seed, 1.3)) + CGFloat(sin(t * 0.45 + seed)) * 8
            let y = size.height * (0.14 + CGFloat(journeyNoise(seed, 2.3)) * 0.54) + CGFloat(cos(t * 0.4 + seed)) * 6
            let pulse = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 1.6 + seed * 1.8))
            let s = CGFloat(3.2 + journeyNoise(seed, 3.3) * 4.6)

            if i.isMultiple(of: 2) {
                let rect = CGRect(x: x - s, y: y - s, width: s * 2, height: s * 2)
                context.fill(StarletShape().path(in: rect), with: .color(Color(hex: 0xFFF4B8).opacity(pulse)))
                context.fill(Path(ellipseIn: CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2)), with: .color(Color(hex: 0xFFFDF8).opacity(pulse)))
            } else {
                let r = s * 0.34
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFFDF8).opacity(pulse * 0.85)))
            }
        }
    }
}
