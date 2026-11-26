import SwiftUI

// MARK: - Drinks

enum DrinkKind: String, Codable, CaseIterable, Identifiable {
    case water, sparkling, tea, coffee, juice, milk, smoothie, soda

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
        }
    }

    var color: Color {
        switch self {
        case .water: Color(hex: 0x2EA8FF)
        case .sparkling: Color(hex: 0x3FD3E0)
        case .tea: Color(hex: 0x43C068)
        case .coffee: Color(hex: 0x9A6340)
        case .juice: Color(hex: 0xFFA41F)
        case .milk: Color(hex: 0xB4A8F0)
        case .smoothie: Color(hex: 0xFF5C93)
        case .soda: Color(hex: 0xEC3B53)
        }
    }

    /// The cup each drink is served in.
    var vessel: VesselStyle {
        switch self {
        case .water, .sparkling, .milk: .glass
        case .tea, .coffee: .mug
        case .juice, .smoothie, .soda: .straw
        }
    }

    var strawColor: Color {
        switch self {
        case .juice: Color(hex: 0xFF5A4E)
        case .smoothie: Color(hex: 0xFFC83D)
        default: Color(hex: 0x1E2340)
        }
    }

    /// How much of the volume counts towards hydration.
    var hydration: Double {
        switch self {
        case .water, .sparkling: 1.0
        case .tea, .milk: 0.9
        case .juice: 0.85
        case .coffee, .smoothie: 0.8
        case .soda: 0.6
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
        case .juice, .milk: 250
        case .smoothie, .soda: 330
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

    var recommendedGoal: Double {
        UserProfile.recommendedGoal(weightKg: weightKg, activity: activity, climate: climate)
    }

    static func recommendedGoal(weightKg: Double, activity: ActivityLevel, climate: Climate) -> Double {
        let base = weightKg * 33 + activity.bonus + climate.bonus
        let rounded = (base / 50).rounded() * 50
        return min(max(rounded, 1_200), 5_000)
    }
}

// MARK: - Persistence model

struct AppData: Codable {
    var profile = UserProfile()
    var entries: [DrinkEntry] = []
    var hasOnboarded = false
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

    /// The bold tile color of the badge.
    var tint: Color {
        switch self {
        case .firstSip: Color(hex: 0x2EA8FF)
        case .streak3: Color(hex: 0xFF7A45)
        case .streak7: Color(hex: 0x8C6BFF)
        case .streak30: Color(hex: 0xFFB020)
        case .earlyBird: Color(hex: 0xF5C400)
        case .rainbow: Color(hex: 0x2CC17C)
        case .overachiever: Color(hex: 0x15BEEC)
        case .liters10: Color(hex: 0xFF5C93)
        case .liters100: Color(hex: 0x3D5AFE)
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
        case .classic: Color(hex: 0x2EA8FF)
        case .sunny: Color(hex: 0xFFB020)
        case .sprout: Color(hex: 0x43C068)
        case .berry: Color(hex: 0xFF5C93)
        case .frosty: Color(hex: 0x7FE3FF)
        case .royal: Color(hex: 0x8C6BFF)
        case .cocoa: Color(hex: 0x9A6340)
        case .starry: Color(hex: 0x3D4BC9)
        case .blaze: Color(hex: 0xFF5A3C)
        }
    }

    var tile: Color {
        switch self {
        case .classic: Color(hex: 0x15BEEC)
        case .sunny: Color(hex: 0xFF7A45)
        case .sprout: Color(hex: 0x1FA463)
        case .berry: Color(hex: 0xC2185B)
        case .frosty: Color(hex: 0x3D7BFF)
        case .royal: Color(hex: 0x5B3FD6)
        case .cocoa: Color(hex: 0xE7A65C)
        case .starry: Color(hex: 0x1E2340)
        case .blaze: Color(hex: 0xFFC83D)
        }
    }

    var accessory: MascotAccessory {
        switch self {
        case .classic: .none
        case .sunny: .sunglasses
        case .sprout: .leaf
        case .berry: .heart
        case .frosty: .snowflake
        case .royal: .crown
        case .cocoa: .star
        case .starry: .moon
        case .blaze: .flame
        }
    }

    var mood: DewyMood {
        switch self {
        case .frosty, .cocoa: .okay
        case .classic, .sprout, .starry: .happy
        default: .ecstatic
        }
    }
}

// MARK: - Tips

enum HydrationTips {
    static let all: [String] = [
        "Starting your morning with a glass of water wakes up your metabolism. ☀️",
        "Feeling hungry? You might just be thirsty — try a sip first.",
        "Keep a bottle in sight. Out of sight really is out of mind!",
        "Fruits like watermelon and oranges count towards hydration too. 🍉",
        "A glass of water before each meal is an easy habit to stack.",
        "Even mild dehydration can make you feel tired and foggy.",
        "Add a slice of lemon or cucumber for a fancy spa vibe. 🍋",
        "Hot day or workout? Your body needs a little extra today.",
        "Sip slowly through the day rather than chugging all at once.",
        "Herbal teas are a cozy way to hydrate in the evening. 🍵"
    ]

    static func tip(for date: Date = .now) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return all[day % all.count]
    }
}
