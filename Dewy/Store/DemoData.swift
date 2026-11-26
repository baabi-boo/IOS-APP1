import Foundation

/// Deterministic sample data used for previews and App Store screenshots.
enum DemoData {
    private struct Generator {
        var state: UInt64
        mutating func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 11) / Double(1 << 53)
        }
    }

    static func make(now: Date = .now) -> AppData {
        let calendar = Calendar.current
        var random = Generator(state: 42)
        var profile = UserProfile()
        profile.name = "Mira"
        profile.dailyGoal = 2_200
        profile.weightKg = 62
        profile.activity = .active
        profile.remindersOn = true
        profile.theme = LaunchOptions.theme ?? .lagoon

        var entries: [DrinkEntry] = []
        let today = calendar.startOfDay(for: now)
        let weighted: [DrinkKind] = [.water, .water, .water, .water, .water, .tea, .tea, .coffee, .coffee, .sparkling, .juice, .milk]

        // History: ~6 weeks, mostly successful days and a 9-day streak.
        for offset in 1...45 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let inStreak = offset <= 9
            let roll = random.next()
            let factor: Double
            if inStreak {
                factor = 1.02 + random.next() * 0.3
            } else if roll < 0.12 {
                factor = 0.35 + random.next() * 0.3
            } else if roll < 0.25 {
                factor = 0.7 + random.next() * 0.25
            } else {
                factor = 1.0 + random.next() * 0.45
            }
            var remaining = profile.dailyGoal * factor
            var minute = 7 * 60 + Int(random.next() * 60)
            while remaining > 60 {
                let kind = weighted[Int(random.next() * Double(weighted.count)) % weighted.count]
                let amount = min(remaining / kind.hydration, [200.0, 250, 330, 400, 500][Int(random.next() * 5) % 5])
                if let date = calendar.date(byAdding: .minute, value: minute, to: day) {
                    entries.append(DrinkEntry(date: date, amount: amount.rounded(), kind: kind))
                }
                remaining -= amount * kind.hydration
                minute += 70 + Int(random.next() * 80)
            }
        }

        // Today
        let todays: [(Int, DrinkKind, Double)]
        if LaunchOptions.screenshot == "celebrate" {
            todays = [(7 * 60 + 45, .water, 500), (9 * 60 + 10, .coffee, 250), (11 * 60, .juice, 300), (13 * 60 + 20, .tea, 300)]
        } else {
            todays = [(7 * 60 + 45, .water, 350), (9 * 60 + 10, .coffee, 200), (10 * 60 + 30, .juice, 250), (12 * 60 + 40, .water, 400), (14 * 60 + 5, .tea, 300)]
        }
        for (minute, kind, amount) in todays {
            if let date = calendar.date(byAdding: .minute, value: minute, to: today) {
                entries.append(DrinkEntry(date: date, amount: amount, kind: kind))
            }
        }

        let onboarded = LaunchOptions.screenshot != "onboarding"
        return AppData(profile: profile, entries: entries, hasOnboarded: onboarded)
    }
}
