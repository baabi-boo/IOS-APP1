import SwiftUI
import WidgetKit
import AppIntents

// Shared by the main app (widget previews in Settings) and the widget extension.
// Strictly depends ONLY on Theme, Models, MascotView, Shapes, HydrationStore, DemoData,
// LogDrinkIntent and system frameworks — never Modifiers, Scene, ShaderModifiers or FriendView.
// Everything drawn here is a single still frame (`animated: false`, no TimelineView).

/// Everything a widget needs to draw Dewy, computed from the saved data.
struct DewySnapshot: TimelineEntry {
    var date: Date
    var total: Double
    var goal: Double
    var bands: [LiquidBand]
    var theme: AppTheme
    var unit: VolumeUnit
    var streak: Int

    var progress: Double { total / max(goal, 1) }

    static func load(at date: Date = .now) -> DewySnapshot {
        make(from: Persistence().load() ?? AppData(), at: date)
    }

    static func make(from data: AppData, at date: Date) -> DewySnapshot {
        let calendar = Calendar.current
        let goal = max(data.profile.dailyGoal, 1)
        let today = data.entries
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
        var running = 0.0
        let bands = today.map { entry -> LiquidBand in
            running += entry.effective
            return LiquidBand(color: entry.kind.color, upTo: running / goal)
        }

        var totals: [Date: Double] = [:]
        for entry in data.entries {
            totals[calendar.startOfDay(for: entry.date), default: 0] += entry.effective
        }
        var day = calendar.startOfDay(for: date)
        if (totals[day] ?? 0) < goal, let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var streak = 0
        while (totals[day] ?? 0) >= goal {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return DewySnapshot(
            date: date,
            total: running,
            goal: goal,
            bands: bands,
            theme: data.profile.theme,
            unit: data.profile.unit,
            streak: streak
        )
    }

    static let sample = DewySnapshot(
        date: .now,
        total: 1_390,
        goal: 2_200,
        bands: [
            LiquidBand(color: DrinkKind.water.color, upTo: 0.16),
            LiquidBand(color: DrinkKind.coffee.color, upTo: 0.24),
            LiquidBand(color: DrinkKind.juice.color, upTo: 0.34),
            LiquidBand(color: DrinkKind.water.color, upTo: 0.52),
            LiquidBand(color: DrinkKind.tea.color, upTo: 0.63)
        ],
        theme: .lagoon,
        unit: .ml,
        streak: 15
    )

    func format(_ milliliters: Double, withUnit: Bool = true) -> String {
        let value = unit == .ml
            ? Int(milliliters.rounded()).formatted(.number)
            : Int((milliliters / VolumeUnit.mlPerOunce).rounded()).formatted(.number)
        return withUnit ? "\(value) \(unit.label)" : value
    }
}

private extension DewySnapshot {
    var percent: Int { Int((progress * 100).rounded()) }
    var clampedProgress: Double { min(max(progress, 0), 1) }
    var skyPhase: SkyPhase { theme.phase(at: date) }

    /// Short amount for compact Lock Screen widgets: "850", "1.4L" or "47".
    var compactAmount: String {
        switch unit {
        case .ml:
            if total >= 1_000 {
                return String(format: "%.1fL", total / 1_000)
            }
            return "\(Int(total.rounded()))"
        case .oz:
            return "\(Int((total / VolumeUnit.mlPerOunce).rounded()))"
        }
    }
}

/// Editorial storybook widget for every Home Screen & Lock Screen family.
struct DewyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var snapshot: DewySnapshot

    private var isAccessory: Bool {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }

    var body: some View {
        content
            .environment(\.dewyTheme, snapshot.theme)
            .containerBackground(for: .widget) {
                if isAccessory {
                    Color.clear
                } else {
                    WidgetSky(theme: snapshot.theme, date: snapshot.date)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            WidgetAccessoryCircular(snapshot: snapshot)
        case .accessoryRectangular:
            WidgetAccessoryRectangular(snapshot: snapshot)
        case .accessoryInline:
            Label("\(snapshot.format(snapshot.total)) · \(snapshot.percent)%", systemImage: "drop.fill")
        case .systemMedium:
            DewyWidgetMedium(snapshot: snapshot)
        default:
            DewyWidgetSmall(snapshot: snapshot)
        }
    }
}

// MARK: - Handcrafted Storybook Widget Sky

/// Per-world multi-layer gouache sky, native paper-cut clouds, horizon silhouette and curved pond.
struct WidgetSky: View {
    var theme: AppTheme
    var date: Date = .now

    var body: some View {
        let phase = theme.phase(at: date)
        let sunGlow = theme.sunGlow(for: phase)
        let sea = theme.sea(for: phase)
        let glint = theme.glint(for: phase)

        GeometryReader { proxy in
            let size = proxy.size
            let isWide = size.width > size.height * 1.4
            let pondHeight = size.height * 0.29

            ZStack(alignment: .topLeading) {
                theme.skyGradient(for: phase)

                RadialGradient(
                    colors: [sunGlow.opacity(phase.isNight ? 0.38 : 0.85), sunGlow.opacity(0)],
                    center: UnitPoint(x: 0.90, y: 0.06),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.58
                )

                if phase.isNight {
                    WidgetStars(size: size)
                }

                WidgetPaperCloud(theme: theme, phase: phase)
                    .frame(width: isWide ? 84 : 62, height: isWide ? 34 : 26)
                    .position(x: size.width * (isWide ? 0.86 : 0.78), y: size.height * (isWide ? 0.22 : 0.34))

                WidgetHorizonSilhouette(theme: theme, phase: phase)
                    .frame(width: size.width, height: size.height * 0.24)
                    .position(x: size.width * 0.5, y: size.height - pondHeight - size.height * 0.08)

                WidgetPond(colors: sea, glint: glint)
                    .frame(width: size.width, height: pondHeight)
                    .position(x: size.width * 0.5, y: size.height - pondHeight * 0.5)
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }
}

/// Handcrafted multi-lobe paper-cut cloud drawn natively via SwiftUI Canvas.
private struct WidgetPaperCloud: View {
    var theme: AppTheme
    var phase: SkyPhase

    var body: some View {
        let lit: Color = phase.isNight ? Color(hex: 0x626BA8) : (theme.cloudTint(for: phase) ?? Palette.paper)
        let shade: Color = phase.isNight ? Color(hex: 0x394278) : theme.cloudShade

        Canvas { context, size in
            let w = size.width
            let h = size.height
            var path = Path()
            path.move(to: CGPoint(x: w * 0.10, y: h * 0.86))
            path.addQuadCurve(to: CGPoint(x: w * 0.28, y: h * 0.36), control: CGPoint(x: 0, y: h * 0.52))
            path.addCurve(
                to: CGPoint(x: w * 0.62, y: h * 0.16),
                control1: CGPoint(x: w * 0.34, y: 0),
                control2: CGPoint(x: w * 0.54, y: 0)
            )
            path.addCurve(
                to: CGPoint(x: w * 0.86, y: h * 0.48),
                control1: CGPoint(x: w * 0.74, y: h * 0.12),
                control2: CGPoint(x: w * 0.86, y: h * 0.28)
            )
            path.addQuadCurve(to: CGPoint(x: w * 0.90, y: h * 0.86), control: CGPoint(x: w, y: h * 0.68))
            path.closeSubpath()

            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [lit, shade]),
                    startPoint: CGPoint(x: w * 0.5, y: 0),
                    endPoint: CGPoint(x: w * 0.5, y: h)
                )
            )
        }
        .opacity(phase.isNight ? 0.52 : 0.88)
    }
}

/// Subtle distant paper-cut horizon landform giving each of the 5 worlds its signature silhouette.
private struct WidgetHorizonSilhouette: View {
    var theme: AppTheme
    var phase: SkyPhase

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let hillColor = silhouetteColor
            var hill = Path()
            switch theme {
            case .matcha:
                hill.move(to: CGPoint(x: 0, y: h))
                hill.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.52), control: CGPoint(x: w * 0.24, y: h * 0.18))
                hill.addQuadCurve(to: CGPoint(x: w, y: h * 0.60), control: CGPoint(x: w * 0.78, y: h * 0.28))
                hill.addLine(to: CGPoint(x: w, y: h))
                hill.closeSubpath()
            case .midnight:
                hill.move(to: CGPoint(x: 0, y: h))
                hill.addLine(to: CGPoint(x: w * 0.18, y: h * 0.30))
                hill.addLine(to: CGPoint(x: w * 0.36, y: h * 0.64))
                hill.addLine(to: CGPoint(x: w * 0.72, y: h * 0.52))
                hill.addLine(to: CGPoint(x: w * 0.88, y: h * 0.24))
                hill.addLine(to: CGPoint(x: w, y: h * 0.54))
                hill.addLine(to: CGPoint(x: w, y: h))
                hill.closeSubpath()
            default:
                hill.move(to: CGPoint(x: 0, y: h))
                hill.addQuadCurve(to: CGPoint(x: w * 0.42, y: h), control: CGPoint(x: w * 0.18, y: h * 0.34))
                hill.closeSubpath()
            }
            context.fill(hill, with: .color(hillColor))
        }
    }

    private var silhouetteColor: Color {
        if phase.isNight || theme == .midnight {
            return Color(hex: 0x262E60).opacity(0.62)
        }
        switch theme {
        case .lagoon: return Color(hex: 0x6DB0A8).opacity(0.45)
        case .peach: return Color(hex: 0xD69A82).opacity(0.42)
        case .matcha: return Color(hex: 0x6BA684).opacity(0.46)
        case .lavender: return Color(hex: 0x9B8CC8).opacity(0.42)
        case .midnight: return Color(hex: 0x262E60).opacity(0.62)
        }
    }
}

private struct WidgetStars: View {
    var size: CGSize

    private let points: [(CGFloat, CGFloat, CGFloat)] = [
        (0.12, 0.14, 5.5), (0.34, 0.09, 2.2), (0.56, 0.18, 5.0), (0.72, 0.08, 2.0),
        (0.22, 0.34, 4.2), (0.48, 0.38, 2.4), (0.09, 0.52, 4.0), (0.64, 0.46, 2.0)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<points.count, id: \.self) { index in
                let point = points[index]
                Group {
                    if index.isMultiple(of: 2) {
                        StarletShape()
                            .fill(index == 0 || index == 4 ? Color(hex: 0xFFF3C4) : Ink.starlight.opacity(0.88))
                            .frame(width: point.2 * 2, height: point.2 * 2)
                    } else {
                        Circle()
                            .fill(Ink.starlight.opacity(0.84))
                            .frame(width: point.2, height: point.2)
                    }
                }
                .position(x: size.width * point.0, y: size.height * point.1)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

/// Gently curved pond water plane with a bright shoreline glint.
private struct WidgetPond: View {
    var colors: [Color]
    var glint: Color

    var body: some View {
        ZStack {
            WidgetPondShape(closed: true)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            WidgetPondShape(closed: false)
                .stroke(glint.opacity(0.75), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

private struct WidgetPondShape: Shape {
    var closed: Bool

    func path(in rect: CGRect) -> Path {
        let lip = rect.height * 0.2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + lip))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + lip * 0.6),
            control: CGPoint(x: rect.midX, y: rect.minY - lip * 0.7)
        )
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Shared Widget Pieces

/// Dewy standing on a handcrafted native botanical lily pad as a crisp still frame.
private struct WidgetDewyOnPad: View {
    var snapshot: DewySnapshot
    var size: CGFloat

    var body: some View {
        let isNight = snapshot.skyPhase.isNight
        ZStack(alignment: .bottom) {
            WidgetBotanicalPad(theme: snapshot.theme, isNight: isNight)
                .frame(width: size * 1.12, height: size * 0.34)
            MascotView(
                progress: snapshot.progress,
                mood: DewyMood(progress: snapshot.progress),
                size: size,
                sparkles: snapshot.progress >= 1,
                bands: snapshot.bands,
                animated: false,
                showsShadow: false,
                isNight: isNight
            )
            .padding(.bottom, size * 0.09)
        }
        .frame(width: size * 1.15)
    }
}

/// Handcrafted veined botanical lily pad drawn natively via SwiftUI Canvas (zero PNG dependency).
private struct WidgetBotanicalPad: View {
    var theme: AppTheme
    var isNight: Bool

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let cy = size.height * 0.56
            let rx = size.width * 0.44
            let ry = size.height * 0.36

            // Soft water contact shadow beneath pad.
            let shadowRect = CGRect(x: cx - rx * 1.02, y: cy - ry * 0.75 + 2.5, width: rx * 2.04, height: ry * 1.8)
            context.fill(Path(ellipseIn: shadowRect), with: .color(Color(hex: 0x152B3B).opacity(isNight ? 0.34 : 0.16)))

            // Notched botanical pad leaf silhouette.
            var leaf = Path()
            let notchAngle: Double = 0.22
            leaf.move(to: CGPoint(x: cx + rx * 0.18, y: cy + ry * 0.04))
            let steps = 36
            for i in 0...steps {
                let frac = Double(i) / Double(steps)
                let angle = notchAngle + frac * (2.0 * .pi - notchAngle * 2.0)
                let pt = CGPoint(x: cx + CGFloat(cos(angle)) * rx, y: cy + CGFloat(sin(angle)) * ry)
                leaf.addLine(to: pt)
            }
            leaf.closeSubpath()

            let topCol = isNight ? theme.padLight.blended(with: Color(hex: 0x2B3B6B), by: 0.38) : theme.padLight
            let botCol = isNight ? theme.pad.blended(with: Color(hex: 0x172145), by: 0.38) : theme.pad
            context.fill(
                leaf,
                with: .linearGradient(
                    Gradient(colors: [topCol, botCol]),
                    startPoint: CGPoint(x: cx, y: cy - ry),
                    endPoint: CGPoint(x: cx, y: cy + ry)
                )
            )

            // Delicate radial leaf veins.
            let veinColor = botCol.blended(with: Ink.primary, by: 0.25).opacity(0.45)
            for deg in stride(from: 42.0, through: 318.0, by: 46.0) {
                let rad = deg * .pi / 180.0
                var vein = Path()
                vein.move(to: CGPoint(x: cx, y: cy))
                vein.addLine(to: CGPoint(x: cx + CGFloat(cos(rad)) * rx * 0.72, y: cy + CGFloat(sin(rad)) * ry * 0.72))
                context.stroke(vein, with: .color(veinColor), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            }

            // Warm botanical ink outline.
            context.stroke(
                leaf,
                with: .color(Ink.primary.opacity(isNight ? 0.55 : 0.38)),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

/// Matte gouache progress capsule with warm hairline track (zero plastic gloss glare).
private struct WidgetProgressBar: View {
    var progress: Double
    var height: CGFloat = 12
    var isNight: Bool = false

    var body: some View {
        let trackFill: Color = isNight ? Ink.starlight.opacity(0.16) : Palette.paper.opacity(0.84)
        let trackBorder: Color = isNight ? Ink.starlight.opacity(0.28) : Ink.hairlineStrong
        let fillGrad = LinearGradient(
            colors: [Palette.aquaLight, Palette.aqua],
            startPoint: .leading,
            endPoint: .trailing
        )

        GeometryReader { proxy in
            let width = proxy.size.width
            let fraction = CGFloat(min(max(progress, 0), 1))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackFill)
                    .overlay(Capsule().stroke(trackBorder, lineWidth: 1))
                if fraction > 0 {
                    Capsule()
                        .fill(fillGrad)
                        .overlay(Capsule().stroke(Palette.aquaDeep.opacity(0.32), lineWidth: 0.75))
                        .frame(width: max(width * fraction, height))
                        .padding(1.5)
                }
            }
        }
        .frame(height: height)
    }
}

/// Warm parchment-gold streak pill with crisp tabular count.
private struct WidgetStreakPill: View {
    var streak: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Palette.butterDeep)
            Text("\(streak)")
                .font(.dewy(11.5, .bold))
                .monospacedDigit()
                .foregroundStyle(Ink.primary)
                .lineLimit(1)
        }
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .frame(height: 21)
        .background(Palette.paper.opacity(0.92), in: Capsule())
        .overlay(Capsule().stroke(Palette.butterDeep.opacity(0.28), lineWidth: 1))
        .fixedSize()
        .accessibilityLabel("\(streak) day streak")
    }
}

/// Picks crisp editorial ink for text over the world's sky, or white in StandBy / tinted mode.
private func widgetInk(theme: AppTheme, phase: SkyPhase, showsBackground: Bool, soft: Bool = false) -> Color {
    if !showsBackground { return soft ? Color.white.opacity(0.76) : .white }
    return soft ? theme.onHeroSoft(for: phase) : theme.onHero(for: phase)
}

// MARK: - Home Screen

struct DewyWidgetSmall: View {
    var snapshot: DewySnapshot

    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    var body: some View {
        let phase = snapshot.skyPhase
        let ink = widgetInk(theme: snapshot.theme, phase: phase, showsBackground: showsBackground)
        let soft = widgetInk(theme: snapshot.theme, phase: phase, showsBackground: showsBackground, soft: true)

        ZStack(alignment: .bottomTrailing) {
            WidgetDewyOnPad(snapshot: snapshot, size: 62)
                .padding(.trailing, 5)
                .padding(.bottom, 5)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 4) {
                    VStack(alignment: .leading, spacing: -1) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(snapshot.format(snapshot.total, withUnit: false))
                                .font(.display(26, .bold))
                                .monospacedDigit()
                                .foregroundStyle(ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                            Text(snapshot.unit.label)
                                .font(.display(12, .medium))
                                .foregroundStyle(soft)
                        }
                        Text("of \(snapshot.format(snapshot.goal))")
                            .font(.dewy(10.5, .bold))
                            .foregroundStyle(soft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 0)
                    if snapshot.streak > 0 {
                        WidgetStreakPill(streak: snapshot.streak)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(snapshot.percent)%")
                        .font(.display(15, .bold))
                        .monospacedDigit()
                        .foregroundStyle(ink)
                    WidgetProgressBar(progress: snapshot.clampedProgress, height: 11, isNight: phase.isNight)
                        .frame(width: 62)
                }
                .padding(.bottom, 2)
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dewy: \(snapshot.format(snapshot.total)) of \(snapshot.format(snapshot.goal)), \(snapshot.percent) percent")
    }
}

struct DewyWidgetMedium: View {
    var snapshot: DewySnapshot

    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    private let quick: [DrinkKind] = [.water, .tea, .coffee]

    var body: some View {
        let phase = snapshot.skyPhase
        let ink = widgetInk(theme: snapshot.theme, phase: phase, showsBackground: showsBackground)
        let soft = widgetInk(theme: snapshot.theme, phase: phase, showsBackground: showsBackground, soft: true)

        HStack(alignment: .bottom, spacing: 10) {
            WidgetDewyOnPad(snapshot: snapshot, size: 88)
                .padding(.bottom, 4)
                .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 6) {
                    VStack(alignment: .leading, spacing: -1) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(snapshot.format(snapshot.total, withUnit: false))
                                .font(.display(29, .bold))
                                .monospacedDigit()
                                .foregroundStyle(ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(snapshot.unit.label)
                                .font(.display(13.5, .medium))
                                .foregroundStyle(soft)
                        }
                        Text("of \(snapshot.format(snapshot.goal)) · \(snapshot.percent)%")
                            .font(.dewy(11.5, .bold))
                            .foregroundStyle(soft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                    if snapshot.streak > 0 {
                        WidgetStreakPill(streak: snapshot.streak)
                    }
                }

                WidgetProgressBar(progress: snapshot.clampedProgress, height: 12, isNight: phase.isNight)
                    .padding(.top, 8)

                Spacer(minLength: 6)

                HStack(spacing: 6) {
                    ForEach(quick) { kind in
                        quickButton(kind)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.leading, 8)
        .padding(.trailing, 13)
        .padding(.vertical, 13)
    }

    private func quickButton(_ kind: DrinkKind) -> some View {
        Button(intent: LogDrinkIntent(kind: kind, amount: kind.defaultAmount)) {
            HStack(spacing: 3) {
                Image(kind.imageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("+\(snapshot.format(kind.defaultAmount, withUnit: false))")
                    .font(.dewy(11.5, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Ink.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.leading, 5)
            .padding(.trailing, 7)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background { WidgetPaperPill(tint: kind.color) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(snapshot.format(kind.defaultAmount)) of \(kind.name)")
    }
}

/// Crisp cotton-paper capsule for interactive widget quick-sip buttons.
private struct WidgetPaperPill: View {
    var tint: Color

    var body: some View {
        Capsule()
            .fill(Palette.paper.opacity(0.95))
            .overlay(Capsule().stroke(Ink.hairlineStrong, lineWidth: 1))
            .shadow(color: Palette.shadow.opacity(0.14), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Lock Screen

private struct WidgetDropletFill: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let fraction = CGFloat(min(max(progress, 0), 1))
            ZStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.3)
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
                    .mask(alignment: .bottom) {
                        Rectangle().frame(height: height * fraction)
                    }
                    .widgetAccentable()
            }
            .frame(width: proxy.size.width, height: height)
        }
        .accessibilityHidden(true)
    }
}

private struct WidgetAccessoryCircular: View {
    var snapshot: DewySnapshot

    var body: some View {
        Gauge(value: snapshot.clampedProgress) {
            Image(systemName: "drop.fill")
        } currentValueLabel: {
            VStack(spacing: 1) {
                WidgetDropletFill(progress: snapshot.clampedProgress)
                    .frame(width: 11, height: 14)
                Text(snapshot.compactAmount)
                    .font(.display(13, .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel("Dewy: \(snapshot.format(snapshot.total)), \(snapshot.percent) percent of goal")
    }
}

private struct WidgetAccessoryRectangular: View {
    var snapshot: DewySnapshot

    var body: some View {
        HStack(spacing: 8) {
            WidgetDropletFill(progress: snapshot.clampedProgress)
                .frame(width: 24, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.format(snapshot.total))
                    .font(.display(18, .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("of \(snapshot.format(snapshot.goal)) · \(snapshot.percent)%")
                    .font(.dewy(12, .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Gauge(value: snapshot.clampedProgress) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .widgetAccentable()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dewy: \(snapshot.format(snapshot.total)) of \(snapshot.format(snapshot.goal))")
    }
}
