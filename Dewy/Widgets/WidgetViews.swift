import SwiftUI
import WidgetKit
import AppIntents

// Shared by the app (widget previews in Settings) and the widget extension.
// Only uses Theme, Models, MascotView, Shapes, HydrationStore, DemoData, LogDrinkIntent and system
// frameworks: no Modifiers/Scene/Effects, so the clay helpers below are private to this file.
// Everything drawn here is a still frame (no TimelineView, `animated: false` on Dewy).

/// Everything a widget needs to draw Dewy, computed from the saved data.
/// Shared by the widget extension and the app (which shows widget previews).
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

        return DewySnapshot(date: date, total: running, goal: goal, bands: bands, theme: data.profile.theme, unit: data.profile.unit, streak: streak)
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

    /// A short amount for tiny Lock Screen widgets: "850", "1.4L" or "47".
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

/// The widget for every family: a pastel sky for the time of day, a clay cloud and Dewy on his lily pad.
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

// MARK: - Sky

/// The widget's backdrop: the sky for the time of day, a sun glow, one clay cloud and a strip of pond.
struct WidgetSky: View {
    var theme: AppTheme
    var date: Date = .now

    var body: some View {
        let phase = theme.phase(at: date)
        GeometryReader { proxy in
            let size = proxy.size
            let isWide = size.width > size.height * 1.4
            ZStack(alignment: .topLeading) {
                phase.gradient

                RadialGradient(
                    colors: [phase.sunGlow.opacity(phase.isNight ? 0.4 : 0.9), phase.sunGlow.opacity(0)],
                    center: UnitPoint(x: 0.92, y: 0.02),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.6
                )

                if phase.isNight {
                    WidgetStars(size: size)
                }

                WidgetCloud(phase: phase, width: isWide ? 92 : 70)
                    .position(x: size.width * (isWide ? 0.9 : 0.8), y: size.height * (isWide ? 0.2 : 0.36))

                WidgetPond(phase: phase)
                    .frame(width: size.width, height: size.height * 0.27)
                    .position(x: size.width / 2, y: size.height * (1 - 0.135))
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }
}

private struct WidgetCloud: View {
    var phase: SkyPhase
    var width: CGFloat

    var body: some View {
        let tint = phase.cloudTint?.blended(with: .white, by: phase.isNight ? 0.25 : 0.55) ?? .white
        Group {
            if Art.exists("prop-cloud-2") {
                Image("prop-cloud-2")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .colorMultiply(tint)
            } else {
                // Three soft puffs if the art is missing.
                ZStack {
                    Circle().frame(width: width * 0.42).offset(x: -width * 0.2, y: width * 0.04)
                    Circle().frame(width: width * 0.56).offset(x: width * 0.06, y: -width * 0.04)
                    Capsule().frame(width: width * 0.9, height: width * 0.3).offset(y: width * 0.12)
                }
                .foregroundStyle(tint)
            }
        }
        .frame(width: width, height: width * 0.62)
        .opacity(phase.isNight ? 0.6 : 0.95)
        .shadow(color: Palette.shadow.opacity(phase.isNight ? 0 : 0.12), radius: 6, x: 0, y: 4)
    }
}

private struct WidgetStars: View {
    var size: CGSize

    private let points: [(CGFloat, CGFloat, CGFloat)] = [
        (0.12, 0.12, 7), (0.34, 0.08, 4), (0.55, 0.18, 6), (0.7, 0.07, 4),
        (0.22, 0.32, 4), (0.46, 0.38, 5), (0.08, 0.5, 4), (0.62, 0.48, 3)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<points.count, id: \.self) { index in
                let point = points[index]
                SparkleShape()
                    .fill(index.isMultiple(of: 3) ? Color(hex: 0xFFF3C4) : Color.white.opacity(0.85))
                    .frame(width: point.2 * 2, height: point.2 * 2)
                    .position(x: size.width * point.0, y: size.height * point.1)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

/// The pond along the bottom of the widget, with a soft clay lip of light.
private struct WidgetPond: View {
    var phase: SkyPhase

    var body: some View {
        ZStack {
            WidgetPondShape(closed: true)
                .fill(LinearGradient(colors: phase.pond, startPoint: .top, endPoint: .bottom))
            WidgetPondShape(closed: false)
                .stroke(phase.glint.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
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
            control: CGPoint(x: rect.midX, y: rect.minY - lip * 0.8)
        )
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Shared pieces

/// Dewy standing on the lily pad art, as a single still frame.
private struct WidgetDewyOnPad: View {
    var snapshot: DewySnapshot
    var size: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            pad
            MascotView(
                progress: snapshot.progress,
                mood: DewyMood(progress: snapshot.progress),
                size: size,
                sparkles: snapshot.progress >= 1,
                bands: snapshot.bands,
                animated: false,
                showsShadow: false
            )
            .padding(.bottom, size * 0.1)
        }
        .frame(width: size * 1.15)
    }

    @ViewBuilder
    private var pad: some View {
        if Art.exists("prop-lilypad") {
            Image("prop-lilypad")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * 1.05)
                .shadow(color: Color(hex: 0x1E5A78).opacity(0.18), radius: 3, x: 0, y: 3)
        } else {
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: 0xB5EBC0), Color(hex: 0x7FD196)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 1.05, height: size * 0.27)
        }
    }
}

/// A chunky aqua progress capsule with a glossy top.
private struct WidgetProgressBar: View {
    var progress: Double
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fraction = CGFloat(min(max(progress, 0), 1))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.75))
                    .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                if fraction > 0 {
                    Capsule()
                        .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.45))
                                .frame(height: height * 0.28)
                                .padding(.horizontal, height * 0.35)
                                .padding(.top, height * 0.16)
                        }
                        .frame(width: max(width * fraction, height))
                }
            }
        }
        .frame(height: height)
        .shadow(color: Palette.aquaDeep.opacity(0.18), radius: 3, x: 0, y: 2)
    }
}

/// A butter-yellow streak pill (butter always means streaks in Dewy).
private struct WidgetStreakPill: View {
    var streak: Int

    var body: some View {
        HStack(spacing: 2) {
            Group {
                if Art.exists("icon-flame") {
                    Image("icon-flame")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Palette.butterDeep)
                }
            }
            .frame(width: 13, height: 13)
            Text("\(streak)")
                .font(.display(12))
                .foregroundStyle(Ink.primary)
                .lineLimit(1)
        }
        .padding(.leading, 5)
        .padding(.trailing, 7)
        .frame(height: 21)
        .background {
            Capsule()
                .fill(LinearGradient(colors: [Color.white, Palette.butterSoft], startPoint: .top, endPoint: .bottom))
                .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                .shadow(color: Palette.butterDeep.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .fixedSize()
        .accessibilityLabel("\(streak) day streak")
    }
}

/// Picks ink for text drawn straight on the sky, or white when the system removes the background (StandBy).
private func widgetInk(_ phase: SkyPhase, showsBackground: Bool, soft: Bool = false) -> Color {
    if !showsBackground { return soft ? Color.white.opacity(0.75) : .white }
    return soft ? phase.onSkySoft : phase.onSky
}

// MARK: - Home Screen

struct DewyWidgetSmall: View {
    var snapshot: DewySnapshot

    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    var body: some View {
        let phase = snapshot.skyPhase
        let ink = widgetInk(phase, showsBackground: showsBackground)
        let soft = widgetInk(phase, showsBackground: showsBackground, soft: true)
        ZStack(alignment: .bottomTrailing) {
            WidgetDewyOnPad(snapshot: snapshot, size: 62)
                .padding(.trailing, 6)
                .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 4) {
                    VStack(alignment: .leading, spacing: -2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(snapshot.format(snapshot.total, withUnit: false))
                                .font(.display(26))
                                .foregroundStyle(ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Text(snapshot.unit.label)
                                .font(.display(12, .medium))
                                .foregroundStyle(soft)
                        }
                        Text("of \(snapshot.format(snapshot.goal))")
                            .font(.dewy(11, .bold))
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
                        .font(.display(15))
                        .foregroundStyle(ink)
                    WidgetProgressBar(progress: snapshot.clampedProgress, height: 13)
                        .frame(width: 62)
                }
                .padding(.bottom, 2)
            }
            .padding(14)
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
        let ink = widgetInk(phase, showsBackground: showsBackground)
        let soft = widgetInk(phase, showsBackground: showsBackground, soft: true)
        HStack(alignment: .bottom, spacing: 10) {
            WidgetDewyOnPad(snapshot: snapshot, size: 92)
                .padding(.bottom, 4)
                .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 6) {
                    VStack(alignment: .leading, spacing: -2) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(snapshot.format(snapshot.total, withUnit: false))
                                .font(.display(30))
                                .foregroundStyle(ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(snapshot.unit.label)
                                .font(.display(14, .medium))
                                .foregroundStyle(soft)
                        }
                        Text("of \(snapshot.format(snapshot.goal)) · \(snapshot.percent)%")
                            .font(.dewy(12, .bold))
                            .foregroundStyle(soft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                    if snapshot.streak > 0 {
                        WidgetStreakPill(streak: snapshot.streak)
                    }
                }
                WidgetProgressBar(progress: snapshot.clampedProgress, height: 14)
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
        .padding(.trailing, 14)
        .padding(.vertical, 14)
    }

    private func quickButton(_ kind: DrinkKind) -> some View {
        Button(intent: LogDrinkIntent(kind: kind, amount: kind.defaultAmount)) {
            HStack(spacing: 2) {
                Image(kind.imageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                Text("+\(snapshot.format(kind.defaultAmount, withUnit: false))")
                    .font(.display(12))
                    .foregroundStyle(Ink.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.leading, 4)
            .padding(.trailing, 7)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background { WidgetClayPill(glow: kind.color) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(snapshot.format(kind.defaultAmount)) of \(kind.name)")
    }
}

/// A white clay capsule: soft volume, a bright rim and a warm, drink-tinted shadow.
private struct WidgetClayPill: View {
    var glow: Color

    var body: some View {
        Capsule()
            .fill(Color.white)
            .overlay {
                Capsule().fill(LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0), location: 0.55),
                        .init(color: Color(hex: 0x6B4A3A).opacity(0.06), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
            }
            .overlay {
                Capsule().stroke(LinearGradient(colors: [Color.white, Color.white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1.5)
            }
            .shadow(color: glow.opacity(0.3), radius: 5, x: 0, y: 3)
            .shadow(color: Palette.shadow.opacity(0.12), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Lock Screen

/// A droplet that fills from the bottom with today's progress.
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
                    .font(.display(13))
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
                    .font(.display(18))
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
