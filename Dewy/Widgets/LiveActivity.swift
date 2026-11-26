import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Today's progress on the Lock Screen and in the Dynamic Island.
/// Shared by the app (which starts and updates it) and the widget extension (which draws it).
struct DewyActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var total: Double
        var goal: Double
        var totalText: String
        var goalText: String
        var streak: Int
        /// The latest drink, for its little illustration.
        var lastDrink: String

        var progress: Double { total / max(goal, 1) }
    }

    var name: String
}

extension DewyActivityAttributes.ContentState {
    /// Builds the state from saved app data, formatted in the user's unit.
    static func make(from data: AppData, now: Date = .now) -> Self {
        let calendar = Calendar.current
        let today = data.entries.filter { calendar.isDate($0.date, inSameDayAs: now) }.sorted { $0.date < $1.date }
        let total = today.reduce(0) { $0 + $1.effective }
        let goal = max(data.profile.dailyGoal, 1)
        func format(_ ml: Double) -> String {
            switch data.profile.unit {
            case .ml: return "\(Int(ml.rounded()).formatted(.number)) ml"
            case .oz: return "\((ml / VolumeUnit.mlPerOunce).formatted(.number.precision(.fractionLength(0)))) oz"
            }
        }
        // Streak: consecutive goal days ending today (or yesterday if today isn't done yet).
        var totals: [Date: Double] = [:]
        for entry in data.entries { totals[calendar.startOfDay(for: entry.date), default: 0] += entry.effective }
        var day = calendar.startOfDay(for: now)
        if (totals[day] ?? 0) < goal, let yesterday = calendar.date(byAdding: .day, value: -1, to: day) { day = yesterday }
        var streak = 0
        while (totals[day] ?? 0) >= goal {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return Self(total: total, goal: goal, totalText: format(total), goalText: format(goal), streak: streak, lastDrink: (today.last?.kind ?? .water).imageName)
    }
}

/// The quick-sip buttons on the Live Activity. As a `LiveActivityIntent` it runs in the app's
/// process, so the app can refresh the activity, Apple Health and its own state right away.
struct QuickSipIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Quick sip"
    static let isDiscoverable = false

    @Parameter(title: "Amount (ml)", default: 250)
    var amount: Double

    init() {}

    init(amount: Double) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        let persistence = Persistence()
        var data = persistence.load() ?? AppData()
        let entry = DrinkEntry(date: .now, amount: amount, kind: .water)
        data.entries.append(entry)
        persistence.save(data)
        WidgetCenter.shared.reloadAllTimelines()
        await QuickSipHooks.notify(entry, data)
        return .result()
    }
}

/// Lets the app react to sips logged from the Live Activity. The widget leaves it empty.
@MainActor
enum QuickSipHooks {
    static var onLogged: (@MainActor (DrinkEntry, AppData) -> Void)?

    static func notify(_ entry: DrinkEntry, _ data: AppData) {
        onLogged?(entry, data)
    }
}
