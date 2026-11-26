import SwiftUI
import WidgetKit
import AppIntents

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

/// The widget for every family, in Dewy's world colors.
struct DewyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var snapshot: DewySnapshot

    var body: some View {
        content
            .environment(\.dewyTheme, snapshot.theme)
            .containerBackground(for: .widget) {
                WidgetSky(theme: snapshot.theme)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: min(snapshot.progress, 1)) {
                Image(systemName: "drop.fill")
            } currentValueLabel: {
                Text("\(Int((snapshot.progress * 100).rounded()))")
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Label("Dewy", systemImage: "drop.fill")
                    .font(.display(14))
                Text("\(snapshot.format(snapshot.total)) of \(snapshot.format(snapshot.goal))")
                    .font(.dewy(13, .semibold))
                ProgressView(value: min(snapshot.progress, 1))
            }
        case .systemMedium:
            DewyWidgetMedium(snapshot: snapshot)
        default:
            DewyWidgetSmall(snapshot: snapshot)
        }
    }
}

/// The widget's sky: the world's gradient with a band of water at the bottom.
struct WidgetSky: View {
    var theme: AppTheme

    var body: some View {
        ZStack(alignment: .bottom) {
            theme.skyGradient
            RadialGradient(colors: [theme.sunGlow.opacity(0.8), theme.sunGlow.opacity(0)], center: UnitPoint(x: 0.88, y: 0.08), startRadius: 0, endRadius: 120)
            VStack(spacing: 0) {
                Rectangle().fill(theme.seaGlint).frame(height: 3)
                theme.seaGradient
            }
            .frame(height: 46)
        }
    }
}

struct DewyWidgetSmall: View {
    var snapshot: DewySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("\(Int((snapshot.progress * 100).rounded()))%")
                    .font(.display(15))
                    .foregroundStyle(.white)
                Spacer()
                if snapshot.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 10, weight: .heavy))
                        Text("\(snapshot.streak)").font(.display(13))
                    }
                    .foregroundStyle(Color(hex: 0xFF6A3D))
                    .padding(.horizontal, 7)
                    .frame(height: 20)
                    .background(Color.white, in: Capsule())
                }
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 4) {
                MascotView(progress: snapshot.progress, mood: DewyMood(progress: snapshot.progress), size: 74, bands: snapshot.bands, animated: false, showsShadow: false)
                    .frame(width: 74, height: 84)
                VStack(alignment: .leading, spacing: -2) {
                    Text(snapshot.format(snapshot.total, withUnit: false))
                        .font(.display(24))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(snapshot.unit.label)
                        .font(.display(13, .medium))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(.bottom, 8)
            }
        }
        .padding(14)
    }
}

struct DewyWidgetMedium: View {
    var snapshot: DewySnapshot

    private let quick: [DrinkKind] = [.water, .tea, .coffee]

    var body: some View {
        HStack(spacing: 14) {
            MascotView(progress: snapshot.progress, mood: DewyMood(progress: snapshot.progress), size: 104, bands: snapshot.bands, animated: false, showsShadow: false)
                .frame(width: 104, height: 120)
                .padding(.top, 10)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(snapshot.format(snapshot.total, withUnit: false))
                        .font(.display(30))
                    Text(snapshot.unit.label)
                        .font(.display(14, .medium))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                Text("\(Int((snapshot.progress * 100).rounded()))% of \(snapshot.format(snapshot.goal))")
                    .font(.display(13, .medium))
                    .foregroundStyle(.white.opacity(0.9))
                HStack(spacing: 8) {
                    ForEach(quick) { kind in
                        Button(intent: LogDrinkIntent(kind: kind, amount: kind.defaultAmount)) {
                            Image(kind.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .frame(width: 42, height: 42)
                                .background(kind.light, in: Circle())
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(.white)
                                        .frame(width: 15, height: 15)
                                        .background(kind.color, in: Circle())
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Log \(Int(kind.defaultAmount)) ml of \(kind.name)")
                    }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
