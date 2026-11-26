import SwiftUI
import Observation

/// The single source of truth for Dewy: profile, drink log, stats and achievements.
@MainActor
@Observable
final class HydrationStore {
    var profile: UserProfile
    var entries: [DrinkEntry]
    var hasOnboarded: Bool

    private let persistence: Persistence?
    private let calendar = Calendar.current

    init() {
        if LaunchOptions.isDemo {
            let demo = DemoData.make()
            profile = demo.profile
            entries = demo.entries
            hasOnboarded = demo.hasOnboarded
            persistence = nil
        } else {
            let persistence = Persistence()
            let data = persistence.load() ?? AppData()
            profile = data.profile
            entries = data.entries
            hasOnboarded = data.hasOnboarded
            self.persistence = persistence
        }
    }

    // MARK: Basics

    var theme: AppTheme { profile.theme }
    var goal: Double { max(profile.dailyGoal, 1) }

    // MARK: Today

    var todayEntries: [DrinkEntry] {
        entries(on: .now).sorted { $0.date > $1.date }
    }

    var todayTotal: Double { total(on: .now) }

    var todayProgress: Double { todayTotal / goal }

    var mood: DewyMood { DewyMood(progress: todayProgress) }

    /// Today's drinks as stacked liquid layers for Dewy, oldest at the bottom.
    var todayBands: [LiquidBand] {
        var running = 0.0
        let sorted = entries(on: .now).sorted { $0.date < $1.date }
        return sorted.map { (entry) -> LiquidBand in
            running += entry.effective
            return LiquidBand(color: entry.kind.color, upTo: running / goal)
        }
    }

    /// Effective hydration per drink kind on a day, in `DrinkKind.allCases` order.
    func kindTotals(on day: Date) -> [KindAmount] {
        let dayEntries = entries(on: day)
        return DrinkKind.allCases.compactMap { (kind) -> KindAmount? in
            let amount = dayEntries.filter { $0.kind == kind }.reduce(0) { $0 + $1.effective }
            return amount > 0 ? KindAmount(kind: kind, amount: amount) : nil
        }
    }

    func entries(on day: Date) -> [DrinkEntry] {
        entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func total(on day: Date) -> Double {
        entries(on: day).reduce(0) { $0 + $1.effective }
    }

    // MARK: Actions

    @discardableResult
    func add(_ kind: DrinkKind, amount: Double, at date: Date = .now) -> DrinkEntry {
        var date = date
        // Demo data puts today's sips at fixed times that can be later than "now";
        // keep new drinks after them so they pour in on top of Dewy's layers.
        if LaunchOptions.isDemo, let latest = entries(on: date).map(\.date).max(), latest >= date {
            date = latest.addingTimeInterval(60)
        }
        let entry = DrinkEntry(date: date, amount: amount, kind: kind)
        entries.append(entry)
        save()
        return entry
    }

    func delete(_ entry: DrinkEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func completeOnboarding(with profile: UserProfile) {
        self.profile = profile
        hasOnboarded = true
        save()
        ReminderScheduler.reschedule(for: profile)
    }

    func clearToday() {
        entries.removeAll { calendar.isDateInToday($0.date) }
        save()
    }

    func eraseEverything() {
        entries = []
        profile = UserProfile()
        hasOnboarded = false
        save()
        ReminderScheduler.reschedule(for: profile)
    }

    func save() {
        persistence?.save(AppData(profile: profile, entries: entries, hasOnboarded: hasOnboarded))
    }

    // MARK: Stats

    /// Effective hydration per calendar day.
    func totalsByDay() -> [Date: Double] {
        var totals: [Date: Double] = [:]
        for entry in entries {
            totals[calendar.startOfDay(for: entry.date), default: 0] += entry.effective
        }
        return totals
    }

    func dailyTotals(days: Int) -> [DayTotal] {
        let totals = totalsByDay()
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(date: day, amount: totals[day] ?? 0)
        }
    }

    var currentStreak: Int {
        let totals = totalsByDay()
        var day = calendar.startOfDay(for: .now)
        if (totals[day] ?? 0) < goal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while (totals[day] ?? 0) >= goal {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    var bestStreak: Int {
        let metDays = totalsByDay().filter { $0.value >= goal }.keys.sorted()
        var best = 0
        var run = 0
        var previous: Date?
        for day in metDays {
            if let previous, calendar.dateComponents([.day], from: previous, to: day).day == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }

    var totalEffective: Double {
        entries.reduce(0) { $0 + $1.effective }
    }

    var goalMetDays: Int {
        totalsByDay().values.filter { $0 >= goal }.count
    }

    func average(days: Int) -> Double {
        let totals = dailyTotals(days: days).filter { $0.amount > 0 }
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0) { $0 + $1.amount } / Double(totals.count)
    }

    func hitRate(days: Int) -> Double {
        let totals = dailyTotals(days: days)
        guard !totals.isEmpty else { return 0 }
        return Double(totals.filter { $0.amount >= goal }.count) / Double(totals.count)
    }

    func breakdown(days: Int) -> [KindShare] {
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now)) else { return [] }
        var sums: [DrinkKind: Double] = [:]
        for entry in entries where entry.date >= start {
            sums[entry.kind, default: 0] += entry.amount
        }
        let total = sums.values.reduce(0, +)
        guard total > 0 else { return [] }
        return sums
            .map { KindShare(kind: $0.key, amount: $0.value, share: $0.value / total) }
            .sorted { $0.amount > $1.amount }
    }

    /// Average volume logged per hour of day across the last `days` days.
    func hourlyRhythm(days: Int) -> [Int: Double] {
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now)) else { return [:] }
        var buckets: [Int: Double] = [:]
        for entry in entries where entry.date >= start {
            buckets[calendar.component(.hour, from: entry.date), default: 0] += entry.amount / Double(days)
        }
        return buckets
    }

    // MARK: Achievements

    func unlockedAchievements() -> Set<Achievement> {
        var unlocked = Set<Achievement>()
        guard !entries.isEmpty else { return unlocked }
        unlocked.insert(.firstSip)
        let best = bestStreak
        if best >= 3 { unlocked.insert(.streak3) }
        if best >= 7 { unlocked.insert(.streak7) }
        if best >= 30 { unlocked.insert(.streak30) }
        if entries.contains(where: { calendar.component(.hour, from: $0.date) < 8 }) { unlocked.insert(.earlyBird) }
        if Set(entries.map(\.kind)).count >= 5 { unlocked.insert(.rainbow) }
        if totalsByDay().values.contains(where: { $0 >= goal * 1.5 }) { unlocked.insert(.overachiever) }
        let liters = totalEffective / 1_000
        if liters >= 10 { unlocked.insert(.liters10) }
        if liters >= 100 { unlocked.insert(.liters100) }
        return unlocked
    }

    // MARK: Formatting

    func format(_ milliliters: Double, withUnit: Bool = true) -> String {
        let value: String
        switch profile.unit {
        case .ml:
            value = Int(milliliters.rounded()).formatted(.number)
        case .oz:
            value = (milliliters / VolumeUnit.mlPerOunce).formatted(.number.precision(.fractionLength(0)))
        }
        return withUnit ? "\(value) \(profile.unit.label)" : value
    }

    func formatLiters(_ milliliters: Double) -> String {
        switch profile.unit {
        case .ml:
            return (milliliters / 1_000).formatted(.number.precision(.fractionLength(1))) + " L"
        case .oz:
            return (milliliters / 3_785.41).formatted(.number.precision(.fractionLength(1))) + " gal"
        }
    }

    /// The value shown in the current unit, used for numeric text transitions.
    func displayValue(_ milliliters: Double) -> Double {
        switch profile.unit {
        case .ml: milliliters.rounded()
        case .oz: (milliliters / VolumeUnit.mlPerOunce).rounded()
        }
    }
}

// MARK: - Persistence

struct Persistence {
    private let url: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("dewy.json")
    }

    func load() -> AppData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppData.self, from: data)
    }

    func save(_ appData: AppData) {
        do {
            let data = try JSONEncoder().encode(appData)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Dewy: failed to save – \(error)")
        }
    }
}

// MARK: - Launch options (used for App Store screenshots)

enum LaunchOptions {
    /// Pass `-screenshot <screen>` to launch straight into a demo screen.
    static var screenshot: String? { UserDefaults.standard.string(forKey: "screenshot") }
    static var isDemo: Bool { screenshot != nil }
    static var theme: AppTheme? { UserDefaults.standard.string(forKey: "theme").flatMap(AppTheme.init(rawValue:)) }
    static var forcePremium: Bool { UserDefaults.standard.bool(forKey: "premium") }
    static var onboardingStep: Int? {
        guard screenshot == "onboarding" else { return nil }
        return UserDefaults.standard.integer(forKey: "step")
    }
}
