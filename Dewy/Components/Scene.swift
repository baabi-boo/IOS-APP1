import SwiftUI
import UIKit

private func fract(_ value: Double) -> Double { value - floor(value) }

/// Deterministic pseudo-random number in 0..<1 for a seed.
private func noise(_ seed: Double, _ salt: Double) -> Double {
    fract(sin(seed * 12.9898 + salt * 78.233) * 43758.5453)
}

// MARK: - Clay world

/// The living backdrop: a pastel sky that follows the time of day, clay clouds drifting at
/// two depths (parallax), the sun or moon, the world's landmark at the horizon and a pond
/// that ripples where you tap it.
struct ClayWorld: View {
    /// Distance of the pond's far shore from the top. Pass a value larger than the view to show only sky.
    var horizon: CGFloat
    var animated = true
    /// Decorations bought in the Friends tab.
    var decor: [Decor] = []
    /// Lets the pond ripple where it's tapped.
    var interactive = false
    /// Hides the landmark (for compact headers where it would crowd the title).
    var showsLandmark = true

    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps: [(Date, CGPoint)] = []

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let phase = theme.phase()
            let hasPond = horizon < size.height
            ZStack(alignment: .topLeading) {
                phase.gradient

                // Sun or moon glow.
                RadialGradient(
                    colors: [phase.sunGlow.opacity(phase.isNight ? 0.45 : 0.9), phase.sunGlow.opacity(0)],
                    center: UnitPoint(x: 0.82, y: min(0.12 * 800 / max(size.height, 1), 0.3)),
                    startRadius: 0, endRadius: 220
                )

                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isLive)) { timeline in
                        let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : 120
                        sceneLayer(size: size, phase: phase, hasPond: hasPond, time: t, now: timeline.date)
                    }
                } else {
                    sceneLayer(size: size, phase: phase, hasPond: hasPond, time: 120, now: .now)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                guard interactive, location.y > horizon else { return }
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.2)
                taps = taps.filter { Date.now.timeIntervalSince($0.0) < 2 } + [(Date.now, location)]
            }
            .allowsHitTesting(interactive)
        }
        .accessibilityHidden(true)
    }

    private func sceneLayer(size: CGSize, phase: SkyPhase, hasPond: Bool, time t: Double, now: Date) -> some View {
        ZStack(alignment: .topLeading) {
            if phase.isNight {
                Canvas { context, canvasSize in
                    drawStars(in: &context, size: canvasSize, limit: min(horizon, size.height) - 10, time: t)
                }
            }

            celestial(phase: phase, size: size, time: t)

            // Far clouds: small, slow, high.
            cloud("prop-cloud-2", width: 110, y: min(horizon * 0.2, 90) + 30, speed: 3, offset: 0.15, size: size, time: t, phase: phase, opacity: 0.8)
            cloud("prop-cloud-2", width: 80, y: min(horizon * 0.42, 190), speed: 2.2, offset: 0.62, size: size, time: t, phase: phase, opacity: 0.7)

            if showsLandmark && hasPond {
                landmarks(size: size, time: t)
            }

            if hasPond {
                Canvas { context, canvasSize in
                    drawPond(in: &context, size: canvasSize, phase: phase, time: t)
                    drawTaps(in: &context, now: now)
                }
            }

            decorLayer(size: size, time: t, hasPond: hasPond)

            // Near cloud: bigger, faster, in front of the landmark.
            cloud("prop-cloud-1", width: 132, y: min(horizon * 0.5, 230) + (hasPond ? 0 : 40), speed: 6, offset: 0.4, size: size, time: t, phase: phase, opacity: 0.95)
        }
    }

    // MARK: Pieces

    @ViewBuilder
    private func celestial(phase: SkyPhase, size: CGSize, time t: Double) -> some View {
        let isMoon = phase.isNight
        let name = isMoon ? "prop-moon" : "prop-sun"
        let width: CGFloat = isMoon ? 64 : 78
        let lift: CGFloat = phase == .dawn || phase == .dusk ? 36 : 0
        let y = min(max(horizon * 0.18, 70), 120) + lift
        if Art.exists(name) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .rotationEffect(.degrees(isMoon ? sin(t * 0.5) * 4 : t.truncatingRemainder(dividingBy: 360) * 3))
                .shadow(color: phase.sunGlow.opacity(0.9), radius: 18)
                .position(x: size.width * 0.84, y: y)
        } else {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xFFF3B8), Palette.butter], startPoint: .top, endPoint: .bottom))
                .frame(width: width * 0.7)
                .position(x: size.width * 0.84, y: y)
        }
    }

    @ViewBuilder
    private func cloud(_ name: String, width: CGFloat, y: CGFloat, speed: Double, offset: Double, size: CGSize, time t: Double, phase: SkyPhase, opacity: Double) -> some View {
        let span = Double(size.width + width * 2)
        let x = CGFloat((offset * span + t * speed).truncatingRemainder(dividingBy: span)) - width
        if Art.exists(name) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .colorMultiply(phase.cloudTint?.blended(with: .white, by: phase.isNight ? 0.25 : 0.55) ?? .white)
                .opacity(phase.isNight ? opacity * 0.6 : opacity)
                .position(x: x + width / 2, y: y)
        }
    }

    @ViewBuilder
    private func landmarks(size: CGSize, time t: Double) -> some View {
        let bob = CGFloat(sin(t * 1.1)) * 2.5
        switch theme {
        case .lagoon, .midnight:
            art("prop-island", width: 118, at: CGPoint(x: size.width * 0.15, y: horizon + 4), anchorBottom: true)
        case .peach:
            art("prop-lighthouse", width: 52, at: CGPoint(x: size.width * 0.11, y: horizon + 8), anchorBottom: true)
            art("prop-sailboat", width: 58, at: CGPoint(x: size.width * 0.86, y: horizon + 10 + bob), anchorBottom: true)
        case .matcha:
            art("prop-hills", width: size.width * 1.05, at: CGPoint(x: size.width * 0.5, y: horizon + 10), anchorBottom: true)
        case .lavender:
            art("prop-castle", width: 108, at: CGPoint(x: size.width * 0.84, y: horizon - 6 + bob * 1.6), anchorBottom: true)
        }
    }

    @ViewBuilder
    private func art(_ name: String, width: CGFloat, at point: CGPoint, anchorBottom: Bool) -> some View {
        if let image = UIImage(named: name) {
            let height = width * image.size.height / max(image.size.width, 1)
            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
                .position(x: point.x, y: anchorBottom ? point.y - height / 2 : point.y)
        }
    }

    @ViewBuilder
    private func decorLayer(size: CGSize, time t: Double, hasPond: Bool) -> some View {
        let flying = decor.filter(\.flies)
        let floating = decor.filter(\.floats)
        let standing = decor.filter { !$0.flies && !$0.floats }
        ForEach(Array(flying.enumerated()), id: \.element) { index, item in
            let drift = CGFloat(sin(t * 0.6 + Double(index))) * 6
            art(item.imageName, width: item == .rainbow ? 150 : 62, at: CGPoint(x: size.width * (index == 0 ? 0.24 : 0.6), y: min(horizon * 0.42, 200) + drift), anchorBottom: false)
        }
        if hasPond {
            ForEach(Array(standing.enumerated()), id: \.element) { index, item in
                let x: CGFloat = index == 0 ? 0.1 : (index == 1 ? 0.9 : 0.3)
                art(item.imageName, width: item == .blossom ? 92 : 58, at: CGPoint(x: size.width * x, y: horizon + 70 + CGFloat(index) * 6), anchorBottom: true)
            }
            ForEach(Array(floating.enumerated()), id: \.element) { index, item in
                let bob = CGFloat(sin(t * 1.4 + Double(index) * 2)) * 2.5
                let sway = CGFloat(sin(t * 0.3 + Double(index))) * 10
                art(item.imageName, width: 50, at: CGPoint(x: size.width * (index == 0 ? 0.78 : 0.2) + sway, y: horizon + 110 + bob), anchorBottom: true)
            }
        }
    }

    // MARK: Drawing

    private func drawStars(in context: inout GraphicsContext, size: CGSize, limit: CGFloat, time t: Double) {
        for index in 0..<40 {
            let seed = Double(index)
            let x = CGFloat(noise(seed, 1)) * size.width
            let y = CGFloat(noise(seed, 2)) * max(limit, 0)
            let twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * (1 + noise(seed, 3) * 2) + seed))
            let s = CGFloat(3 + noise(seed, 4) * 6)
            context.opacity = twinkle
            if index.isMultiple(of: 4) {
                context.fill(SparkleShape().path(in: CGRect(x: x - s, y: y - s, width: s * 2, height: s * 2)), with: .color(Color(hex: 0xFFF3C4)))
            } else {
                let r = s * 0.22
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white))
            }
        }
        context.opacity = 1
    }

    private func drawPond(in context: inout GraphicsContext, size: CGSize, phase: SkyPhase, time t: Double) {
        let w = size.width
        let top = horizon
        func shore(_ x: CGFloat) -> CGFloat {
            top + 2 * CGFloat(sin(Double(x / w) * .pi * 3 + t * 0.5))
        }
        var pond = Path()
        pond.move(to: CGPoint(x: 0, y: shore(0)))
        var x: CGFloat = 0
        while x <= w + 8 {
            pond.addLine(to: CGPoint(x: x, y: shore(x)))
            x += 8
        }
        pond.addLine(to: CGPoint(x: w, y: size.height))
        pond.addLine(to: CGPoint(x: 0, y: size.height))
        pond.closeSubpath()
        context.fill(pond, with: .linearGradient(Gradient(colors: phase.pond), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: size.height)))

        // Soft clay lip where water meets the sky.
        var lip = Path()
        lip.move(to: CGPoint(x: 0, y: shore(0)))
        x = 0
        while x <= w + 8 {
            lip.addLine(to: CGPoint(x: x, y: shore(x)))
            x += 8
        }
        context.stroke(lip, with: .color(phase.glint.opacity(0.85)), lineWidth: 4)

        // Reflection of the sun or moon.
        let cx = w * 0.84
        for row in 0..<5 {
            let y = top + 12 + CGFloat(row) * 13
            let shimmer = 0.85 + 0.15 * sin(t * 1.4 + Double(row))
            let half = CGFloat(34 - row * 5) * CGFloat(shimmer)
            var stripe = Path()
            stripe.move(to: CGPoint(x: cx - half, y: y))
            stripe.addLine(to: CGPoint(x: cx + half, y: y))
            context.stroke(stripe, with: .color(phase.sunGlow.opacity(0.5 - Double(row) * 0.08)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }

        // Little dashes of light drifting on the water.
        let depth = size.height - top
        for index in 0..<10 {
            let seed = Double(index)
            let y = top + 22 + CGFloat(noise(seed, 7)) * max(depth - 40, 0)
            let span = Double(w + 80)
            let px = (noise(seed, 9) * span + t * (3 + noise(seed, 8) * 5)).truncatingRemainder(dividingBy: span) - 40
            let length = CGFloat(12 + noise(seed, 10) * 22)
            var dash = Path()
            dash.move(to: CGPoint(x: CGFloat(px), y: y))
            dash.addLine(to: CGPoint(x: CGFloat(px) + length, y: y))
            context.opacity = 0.3 + 0.35 * (0.5 + 0.5 * sin(t * 1.3 + seed))
            context.stroke(dash, with: .color(phase.glint), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        context.opacity = 1
    }

    private func drawTaps(in context: inout GraphicsContext, now: Date) {
        for (start, point) in taps {
            let age = now.timeIntervalSince(start)
            guard age >= 0, age < 1.6 else { continue }
            let progress = age / 1.6
            for ring in 0..<2 {
                let p = max(progress - Double(ring) * 0.18, 0)
                let rx = CGFloat(10 + p * 70)
                let rect = CGRect(x: point.x - rx, y: point.y - rx * 0.28, width: rx * 2, height: rx * 0.56)
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.85 * (1 - p))), lineWidth: 2.5)
            }
        }
    }
}

// MARK: - Lily pad

/// The lily pad Dewy stands on, with ripples that spread whenever a drink lands.
struct LilyPad: View {
    var width: CGFloat
    var rippleTrigger: Int = 0
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var splashes: [Date] = []

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        ZStack {
            if animated {
                TimelineView(.animation(minimumInterval: splashes.isEmpty ? 1.0 / 12.0 : 1.0 / 60.0, paused: !isLive && splashes.isEmpty)) { timeline in
                    let now = timeline.date
                    let t = isLive ? now.timeIntervalSinceReferenceDate : 0
                    ripples(time: t, now: now)
                }
            } else {
                ripples(time: 0, now: .now)
            }

            if Art.exists("prop-lilypad") {
                Image("prop-lilypad")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .offset(y: width * 0.03)
            } else {
                Ellipse()
                    .fill(LinearGradient(colors: [Color(hex: 0xB5EBC0), Color(hex: 0x7FD196)], startPoint: .top, endPoint: .bottom))
                    .frame(width: width, height: width * 0.26)
            }
        }
        .frame(width: width * 1.9, height: width * 0.5)
        .onChange(of: rippleTrigger) {
            splashes = splashes.filter { Date.now.timeIntervalSince($0) < 2 } + [Date.now]
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                splashes = splashes.filter { Date.now.timeIntervalSince($0) < 1.9 }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func ripples(time t: Double, now: Date) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.55)
            let rx = width / 2
            let ry = rx * 0.26
            func ring(_ scale: CGFloat, opacity: Double, line: CGFloat = 2.5) {
                let rect = CGRect(x: center.x - rx * scale, y: center.y - ry * scale, width: rx * 2 * scale, height: ry * 2 * scale)
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)), lineWidth: line)
            }
            let breathe = CGFloat(sin(t * 1.3)) * 0.03
            ring(1.3 + breathe, opacity: 0.5)
            ring(1.75 + breathe * 1.5, opacity: 0.28)
            for start in splashes {
                let age = now.timeIntervalSince(start)
                guard age >= 0, age < 1.8 else { continue }
                let progress = age / 1.8
                ring(1.1 + CGFloat(progress) * 1.5, opacity: 0.9 * (1 - progress), line: 3.5)
                if age > 0.25 {
                    let p2 = (age - 0.25) / 1.55
                    ring(1.05 + CGFloat(p2) * 1.1, opacity: 0.6 * (1 - p2), line: 2.5)
                }
            }
            // Shadow in the water.
            context.fill(Path(ellipseIn: CGRect(x: center.x - rx * 0.98, y: center.y - ry + 5, width: rx * 1.96, height: ry * 2)), with: .color(Color(hex: 0x1E5A78).opacity(0.18)))
        }
    }
}

// MARK: - Sky header

/// The sky behind the top of a screen. It keeps going upward in the sky's top color,
/// so the status bar area and overscrolling always show sky.
struct SkyHeaderBackground: View {
    var height: CGFloat
    /// Horizon measured from the top of the header; `nil` shows only sky.
    var horizon: CGFloat?
    var showsLandmark = true

    @Environment(\.dewyTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            theme.phase().sky[0].frame(height: 800)
            ClayWorld(horizon: horizon ?? height + 1_000, showsLandmark: showsLandmark)
                .frame(height: height)
        }
        .frame(height: height, alignment: .bottom)
        .allowsHitTesting(false)
    }
}
