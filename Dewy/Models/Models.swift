import SwiftUI

// MARK: - Drinks

enum DrinkKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case water, sparkling, tea, coffee, juice, milk, smoothie, soda, lemonade, cocoa, coconut, matcha

    var id: String { rawValue }

    var name: String {
        switch self {
        case .water: "Water"
        case .sparkling: "Sparkling"
        case .tea: "Tea"
        case .coffee: "Coffee"
        case .juice: "Juice"
        case .milk: "Milk"
        case .smoothie: "Smoothie"
        case .soda: "Soda"
        case .lemonade: "Lemonade"
        case .cocoa: "Hot Cocoa"
        case .coconut: "Coconut"
        case .matcha: "Matcha"
        }
    }

    var emoji: String {
        switch self {
        case .water: "💧"
        case .sparkling: "🫧"
        case .tea: "🍵"
        case .coffee: "☕️"
        case .juice: "🧃"
        case .milk: "🥛"
        case .smoothie: "🍓"
        case .soda: "🥤"
        case .lemonade: "🍋"
        case .cocoa: "🍫"
        case .coconut: "🥥"
        case .matcha: "🍵"
        }
    }

    /// Name of the illustration in the asset catalog.
    var imageName: String { "drink-\(rawValue)" }

    /// The drink's main color: its layer inside Dewy and its accents.
    var color: Color {
        switch self {
        case .water: Color(hex: 0x4DB4FF)
        case .sparkling: Color(hex: 0x3FD3DE)
        case .tea: Color(hex: 0x8CCF63)
        case .coffee: Color(hex: 0xD9A06F)
        case .juice: Color(hex: 0xFFAE3D)
        case .milk: Color(hex: 0xB3A6FF)
        case .smoothie: Color(hex: 0xFF7DB0)
        case .soda: Color(hex: 0xFF6470)
        case .lemonade: Color(hex: 0xFFD43B)
        case .cocoa: Color(hex: 0xB97A58)
        case .coconut: Color(hex: 0x8DD8C2)
        case .matcha: Color(hex: 0x7DC46B)
        }
    }

    /// A pale wash of the drink color, used for tiles behind the illustration.
    var light: Color {
        switch self {
        case .water: Color(hex: 0xE3F3FF)
        case .sparkling: Color(hex: 0xDDF8FA)
        case .tea: Color(hex: 0xEAF7DF)
        case .coffee: Color(hex: 0xF8ECE1)
        case .juice: Color(hex: 0xFFF1DC)
        case .milk: Color(hex: 0xEFECFF)
        case .smoothie: Color(hex: 0xFFE6F0)
        case .soda: Color(hex: 0xFFE5E7)
        case .lemonade: Color(hex: 0xFFF8D6)
        case .cocoa: Color(hex: 0xF5E8E1)
        case .coconut: Color(hex: 0xE3F7F1)
        case .matcha: Color(hex: 0xE8F5E2)
        }
    }

    /// A deeper shade for text on the light wash and for candy-button lips.
    var deep: Color {
        switch self {
        case .water: Color(hex: 0x1F8CE6)
        case .sparkling: Color(hex: 0x14A8B6)
        case .tea: Color(hex: 0x4E9E32)
        case .coffee: Color(hex: 0x9A6238)
        case .juice: Color(hex: 0xE5800F)
        case .milk: Color(hex: 0x7462E8)
        case .smoothie: Color(hex: 0xDE4585)
        case .soda: Color(hex: 0xDB3446)
        case .lemonade: Color(hex: 0xD99A00)
        case .cocoa: Color(hex: 0x7E4930)
        case .coconut: Color(hex: 0x3EA488)
        case .matcha: Color(hex: 0x4F9E42)
        }
    }

    /// How much of the volume counts towards hydration.
    var hydration: Double {
        switch self {
        case .water, .sparkling, .coconut: 1.0
        case .tea, .milk, .lemonade: 0.9
        case .juice, .cocoa, .matcha: 0.85
        case .coffee, .smoothie: 0.8
        case .soda: 0.6
        }
    }

    /// Caffeine in milligrams per milliliter.
    var caffeinePerML: Double {
        switch self {
        case .coffee: 0.4
        case .matcha: 0.25
        case .tea: 0.2
        case .soda: 0.1
        case .cocoa: 0.03
        default: 0
        }
    }

    /// Sugar in grams per milliliter.
    var sugarPerML: Double {
        switch self {
        case .smoothie: 0.12
        case .soda: 0.106
        case .lemonade: 0.1
        case .juice, .cocoa: 0.09
        case .coconut, .matcha: 0.06
        case .milk: 0.05
        default: 0
        }
    }

    var isPremium: Bool {
        switch self {
        case .water, .tea, .coffee, .juice: false
        default: true
        }
    }

    var defaultAmount: Double {
        switch self {
        case .water, .sparkling: 250
        case .tea, .coffee: 200
        case .juice, .milk, .cocoa: 250
        case .lemonade: 300
        case .smoothie, .soda, .coconut: 330
        case .matcha: 350
        }
    }

    /// A tiny line shown on the drink sheet.
    var blurb: String {
        switch self {
        case .water: "The classic. Dewy's favorite."
        case .sparkling: "Bubbly and just as hydrating."
        case .tea: "Cozy, with a little caffeine."
        case .coffee: "A morning hug in a mug."
        case .juice: "Sunshine in a glass."
        case .milk: "Creamy and calming."
        case .smoothie: "Fruity, thick and sweet."
        case .soda: "A treat. Counts a little less."
        case .lemonade: "Zesty and bright."
        case .cocoa: "Warm, sweet and snuggly."
        case .coconut: "Nature's sports drink."
        case .matcha: "Green, calm energy."
        }
    }
}

struct DrinkEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var amount: Double
    var kind: DrinkKind

    /// Volume adjusted by the drink's hydration factor.
    var effective: Double { amount * kind.hydration }

    var caffeine: Double { amount * kind.caffeinePerML }

    var sugar: Double { amount * kind.sugarPerML }
}

// MARK: - Profile

enum VolumeUnit: String, Codable, CaseIterable, Identifiable {
    case ml, oz
    var id: String { rawValue }
    static let mlPerOunce = 29.5735

    var label: String {
        switch self {
        case .ml: "ml"
        case .oz: "oz"
        }
    }

    var step: Double {
        switch self {
        case .ml: 50
        case .oz: 2 * VolumeUnit.mlPerOunce
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case chill, active, athlete
    var id: String { rawValue }

    var title: String {
        switch self {
        case .chill: "Chill"
        case .active: "Active"
        case .athlete: "Athlete"
        }
    }

    var subtitle: String {
        switch self {
        case .chill: "Mostly sitting, cozy days"
        case .active: "On my feet, walking a lot"
        case .athlete: "Workouts & sweaty sessions"
        }
    }

    var emoji: String {
        switch self {
        case .chill: "🛋️"
        case .active: "🚶"
        case .athlete: "🏃"
        }
    }

    var symbol: String {
        switch self {
        case .chill: "sofa.fill"
        case .active: "figure.walk"
        case .athlete: "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .chill: Color(hex: 0x8C7BFF)
        case .active: Color(hex: 0x2FB8F0)
        case .athlete: Color(hex: 0xFF7A59)
        }
    }

    var bonus: Double {
        switch self {
        case .chill: 0
        case .active: 350
        case .athlete: 700
        }
    }
}

enum Climate: String, Codable, CaseIterable, Identifiable {
    case cool, mild, hot
    var id: String { rawValue }

    var title: String {
        switch self {
        case .cool: "Cool"
        case .mild: "Mild"
        case .hot: "Hot"
        }
    }

    var emoji: String {
        switch self {
        case .cool: "❄️"
        case .mild: "🌤️"
        case .hot: "🔥"
        }
    }

    var symbol: String {
        switch self {
        case .cool: "snowflake"
        case .mild: "cloud.sun.fill"
        case .hot: "sun.max.fill"
        }
    }

    var tint: Color {
        switch self {
        case .cool: Color(hex: 0x5BB8FF)
        case .mild: Color(hex: 0x3FC59A)
        case .hot: Color(hex: 0xFF9A3D)
        }
    }

    var bonus: Double {
        switch self {
        case .cool: -100
        case .mild: 0
        case .hot: 500
        }
    }
}

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var weightKg: Double = 65
    var usesPounds = false
    var activity: ActivityLevel = .active
    var climate: Climate = .mild
    var wakeMinutes: Int = 7 * 60
    var sleepMinutes: Int = 23 * 60
    var dailyGoal: Double = 2_200
    var unit: VolumeUnit = .ml
    var theme: AppTheme = .lagoon
    var remindersOn = false
    var reminderInterval: Int = 120
    var soundsOn = true
    var hapticsOn = true
    /// Daily caffeine budget in milligrams (400 mg is the usual guidance for adults).
    var caffeineLimit: Double = 400

    var recommendedGoal: Double {
        UserProfile.recommendedGoal(weightKg: weightKg, activity: activity, climate: climate)
    }

    static func recommendedGoal(weightKg: Double, activity: ActivityLevel, climate: Climate) -> Double {
        let base = weightKg * 33 + activity.bonus + climate.bonus
        let rounded = (base / 50).rounded() * 50
        return min(max(rounded, 1_200), 5_000)
    }

    init() {}

    // Decodes field by field so data saved by older versions keeps loading.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = UserProfile.blank
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? d.name
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg) ?? d.weightKg
        usesPounds = try c.decodeIfPresent(Bool.self, forKey: .usesPounds) ?? d.usesPounds
        activity = (try? c.decodeIfPresent(ActivityLevel.self, forKey: .activity)) ?? d.activity
        climate = (try? c.decodeIfPresent(Climate.self, forKey: .climate)) ?? d.climate
        wakeMinutes = try c.decodeIfPresent(Int.self, forKey: .wakeMinutes) ?? d.wakeMinutes
        sleepMinutes = try c.decodeIfPresent(Int.self, forKey: .sleepMinutes) ?? d.sleepMinutes
        dailyGoal = try c.decodeIfPresent(Double.self, forKey: .dailyGoal) ?? d.dailyGoal
        unit = (try? c.decodeIfPresent(VolumeUnit.self, forKey: .unit)) ?? d.unit
        theme = (try? c.decodeIfPresent(AppTheme.self, forKey: .theme)) ?? d.theme
        remindersOn = try c.decodeIfPresent(Bool.self, forKey: .remindersOn) ?? d.remindersOn
        reminderInterval = try c.decodeIfPresent(Int.self, forKey: .reminderInterval) ?? d.reminderInterval
        soundsOn = try c.decodeIfPresent(Bool.self, forKey: .soundsOn) ?? d.soundsOn
        hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? d.hapticsOn
        caffeineLimit = try c.decodeIfPresent(Double.self, forKey: .caffeineLimit) ?? d.caffeineLimit
    }

    private static let blank = UserProfile()
}

// MARK: - Persistence model

struct AppData: Codable {
    var profile = UserProfile()
    var entries: [DrinkEntry] = []
    var hasOnboarded = false
    /// Challenges the user has joined, keyed by `ChallengeKind.rawValue`, with their start day.
    var challenges: [String: Date] = [:]

    init(profile: UserProfile = UserProfile(), entries: [DrinkEntry] = [], hasOnboarded: Bool = false, challenges: [String: Date] = [:]) {
        self.profile = profile
        self.entries = entries
        self.hasOnboarded = hasOnboarded
        self.challenges = challenges
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile = (try? c.decodeIfPresent(UserProfile.self, forKey: .profile)) ?? UserProfile()
        // Skip entries that can't be read instead of losing the whole log.
        if let raw = try? c.decodeIfPresent([FailableEntry].self, forKey: .entries) {
            entries = raw.compactMap(\.entry)
        } else {
            entries = []
        }
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? false
        challenges = (try? c.decodeIfPresent([String: Date].self, forKey: .challenges)) ?? [:]
    }

    private struct FailableEntry: Decodable {
        var entry: DrinkEntry?
        init(from decoder: Decoder) throws {
            entry = try? DrinkEntry(from: decoder)
        }
    }
}

// MARK: - Insights helpers

struct DayTotal: Identifiable, Hashable {
    var date: Date
    var amount: Double
    var id: Date { date }
}

struct KindAmount: Identifiable, Hashable {
    var kind: DrinkKind
    var amount: Double
    var id: DrinkKind { kind }
}

struct KindShare: Identifiable, Hashable {
    var kind: DrinkKind
    var amount: Double
    var share: Double
    var id: DrinkKind { kind }
}

// MARK: - Achievements

enum Achievement: String, CaseIterable, Identifiable {
    case firstSip, streak3, streak7, streak30, earlyBird, rainbow, overachiever, liters10, liters100

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSip: "First Sip"
        case .streak3: "Warming Up"
        case .streak7: "Week of Dew"
        case .streak30: "Hydro Hero"
        case .earlyBird: "Early Bird"
        case .rainbow: "Taste Rainbow"
        case .overachiever: "Overflowing"
        case .liters10: "Splash Starter"
        case .liters100: "Ocean Soul"
        }
    }

    var detail: String {
        switch self {
        case .firstSip: "Log your very first drink."
        case .streak3: "Hit your goal 3 days in a row."
        case .streak7: "Hit your goal 7 days in a row."
        case .streak30: "Hit your goal 30 days in a row."
        case .earlyBird: "Sip something before 8 AM."
        case .rainbow: "Try 5 different drinks."
        case .overachiever: "Reach 150% of your goal in a day."
        case .liters10: "Drink 10 liters in total."
        case .liters100: "Drink 100 liters in total."
        }
    }

    /// The glyph stamped on the medal.
    var symbol: String {
        switch self {
        case .firstSip: "drop.fill"
        case .streak3: "flame.fill"
        case .streak7: "rainbow"
        case .streak30: "trophy.fill"
        case .earlyBird: "sunrise.fill"
        case .rainbow: "paintpalette.fill"
        case .overachiever: "water.waves"
        case .liters10: "bubbles.and.sparkles.fill"
        case .liters100: "fish.fill"
        }
    }

    var emoji: String {
        switch self {
        case .firstSip: "💧"
        case .streak3: "🔥"
        case .streak7: "🌈"
        case .streak30: "🏆"
        case .earlyBird: "🐣"
        case .rainbow: "🎨"
        case .overachiever: "🌊"
        case .liters10: "🪣"
        case .liters100: "🐳"
        }
    }

    /// The medal color.
    var tint: Color {
        switch self {
        case .firstSip: Color(hex: 0x3AAEFF)
        case .streak3: Color(hex: 0xFF7A45)
        case .streak7: Color(hex: 0x8C6BFF)
        case .streak30: Color(hex: 0xFFB020)
        case .earlyBird: Color(hex: 0xFFC42E)
        case .rainbow: Color(hex: 0x2CC17C)
        case .overachiever: Color(hex: 0x1FC3E6)
        case .liters10: Color(hex: 0xFF6FA5)
        case .liters100: Color(hex: 0x4D6BFE)
        }
    }
}

// MARK: - Dewy friends

/// Collectible Dewy variants, unlocked by growing the garden (days the goal was reached).
enum DewyFriend: String, CaseIterable, Identifiable {
    case classic, sunny, sprout, berry, frosty, royal, cocoa, starry, blaze

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: "Dewy"
        case .sunny: "Sunny"
        case .sprout: "Sprout"
        case .berry: "Berry"
        case .frosty: "Frosty"
        case .royal: "Royal"
        case .cocoa: "Cocoa"
        case .starry: "Starry"
        case .blaze: "Blaze"
        }
    }

    var bio: String {
        switch self {
        case .classic: "Always up for a sip."
        case .sunny: "Beach days only."
        case .sprout: "Grows with every glass."
        case .berry: "Sweet on you."
        case .frosty: "Keeps it cool."
        case .royal: "Hydration royalty."
        case .cocoa: "Warm and snuggly."
        case .starry: "Sips by moonlight."
        case .blaze: "Hot streak energy."
        }
    }

    /// Flowers needed to unlock this friend.
    var flowersNeeded: Int {
        switch self {
        case .classic: 0
        case .sunny: 3
        case .sprout: 7
        case .berry: 14
        case .frosty: 21
        case .royal: 30
        case .cocoa: 50
        case .starry: 75
        case .blaze: 100
        }
    }

    var liquid: Color {
        switch self {
        case .classic: Color(hex: 0x4DB4FF)
        case .sunny: Color(hex: 0xFFC23D)
        case .sprout: Color(hex: 0x7FD05F)
        case .berry: Color(hex: 0xFF7DB0)
        case .frosty: Color(hex: 0x8FE6FF)
        case .royal: Color(hex: 0xA88BFF)
        case .cocoa: Color(hex: 0xC48A62)
        case .starry: Color(hex: 0x6C7BFF)
        case .blaze: Color(hex: 0xFF7A4D)
        }
    }

    /// The tile behind the friend.
    var tile: Color {
        switch self {
        case .classic: Color(hex: 0x2FAEFF)
        case .sunny: Color(hex: 0xFF9F43)
        case .sprout: Color(hex: 0x2EBF7A)
        case .berry: Color(hex: 0xF0558E)
        case .frosty: Color(hex: 0x4F8BFF)
        case .royal: Color(hex: 0x7A55F5)
        case .cocoa: Color(hex: 0xD98C5F)
        case .starry: Color(hex: 0x2B2F7A)
        case .blaze: Color(hex: 0xFF6B4A)
        }
    }

    var accessory: MascotAccessory {
        switch self {
        case .classic: .none
        case .sunny: .sunglasses
        case .sprout: .sprout
        case .berry: .bow
        case .frosty: .snowflakes
        case .royal: .crown
        case .cocoa: .hearts
        case .starry: .nightcap
        case .blaze: .flame
        }
    }

    var mood: DewyMood {
        switch self {
        case .frosty, .cocoa, .starry: .okay
        case .classic, .sprout: .happy
        default: .ecstatic
        }
    }
}

// MARK: - Challenges

/// Week-long mini quests, in the spirit of a habit "challenge": each has a daily rule.
enum ChallengeKind: String, CaseIterable, Identifiable, Codable {
    case morningGlass, perfectWeek, sodaFree, caffeineCut, teaRitual, rainbow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morningGlass: "Morning Glass"
        case .perfectWeek: "Perfect Week"
        case .sodaFree: "Soda Detox"
        case .caffeineCut: "Caffeine Cut"
        case .teaRitual: "Tea Ritual"
        case .rainbow: "Taste Rainbow"
        }
    }

    var rule: String {
        switch self {
        case .morningGlass: "A glass of water before 9 AM"
        case .perfectWeek: "Hit your goal every day"
        case .sodaFree: "No soda at all"
        case .caffeineCut: "Under 200 mg of caffeine a day"
        case .teaRitual: "A cup of tea every day"
        case .rainbow: "3 different drinks a day"
        }
    }

    var days: Int {
        switch self {
        case .teaRitual, .rainbow: 5
        default: 7
        }
    }

    var tint: Color {
        switch self {
        case .morningGlass: Color(hex: 0xFFB13D)
        case .perfectWeek: Color(hex: 0x2FAEFF)
        case .sodaFree: Color(hex: 0xFF6470)
        case .caffeineCut: Color(hex: 0x9C6ADE)
        case .teaRitual: Color(hex: 0x4CBF6B)
        case .rainbow: Color(hex: 0xFF6FA5)
        }
    }

    var accessory: MascotAccessory {
        switch self {
        case .morningGlass: .sunglasses
        case .perfectWeek: .crown
        case .sodaFree: .sprout
        case .caffeineCut: .nightcap
        case .teaRitual: .bow
        case .rainbow: .hearts
        }
    }

    var liquid: Color {
        switch self {
        case .morningGlass: Color(hex: 0x6FC6FF)
        case .perfectWeek: Color(hex: 0x4DB4FF)
        case .sodaFree: Color(hex: 0x7FD3FF)
        case .caffeineCut: Color(hex: 0xC6B3FF)
        case .teaRitual: Color(hex: 0x9DDB74)
        case .rainbow: Color(hex: 0xFF9CC4)
        }
    }

    /// Whether a day's drinks keep the challenge going.
    func passes(_ entries: [DrinkEntry], goal: Double) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .morningGlass:
            return entries.contains { $0.kind == .water && calendar.component(.hour, from: $0.date) < 9 }
        case .perfectWeek:
            return entries.reduce(0) { $0 + $1.effective } >= goal
        case .sodaFree:
            return !entries.contains { $0.kind == .soda }
        case .caffeineCut:
            return entries.reduce(0) { $0 + $1.caffeine } < 200
        case .teaRitual:
            return entries.contains { $0.kind == .tea || $0.kind == .matcha }
        case .rainbow:
            return Set(entries.map(\.kind)).count >= 3
        }
    }
}

struct ChallengeProgress: Hashable {
    enum State: Hashable { case notStarted, active, completed, failed }
    var state: State
    var daysDone: Int
    var total: Int

    var fraction: Double { total == 0 ? 0 : Double(daysDone) / Double(total) }
}

// MARK: - Tips

enum HydrationTips {
    static let all: [String] = [
        "Starting your morning with a glass of water wakes up your metabolism.",
        "Feeling hungry? You might just be thirsty. Try a sip first.",
        "Keep a bottle in sight. Out of sight really is out of mind!",
        "Fruits like watermelon and oranges count towards hydration too.",
        "A glass of water before each meal is an easy habit to stack.",
        "Even mild dehydration can make you feel tired and foggy.",
        "Add a slice of lemon or cucumber for a fancy spa vibe.",
        "Hot day or workout? Your body needs a little extra today.",
        "Sip slowly through the day rather than chugging all at once.",
        "Herbal teas are a cozy, caffeine-free way to hydrate in the evening."
    ]

    static func tip(for date: Date = .now) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return all[day % all.count]
    }
}
