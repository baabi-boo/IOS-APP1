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
        case .water: Color(hex: 0x5AB4FF)
        case .sparkling: Color(hex: 0x6FD6E8)
        case .tea: Color(hex: 0x7CCB7E)
        case .coffee: Color(hex: 0xB08463)
        case .juice: Color(hex: 0xFFB347)
        case .milk: Color(hex: 0xB9B4E8)
        case .smoothie: Color(hex: 0xFF7FA3)
        case .soda: Color(hex: 0xFF8A65)
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

    var colors: [Color] {
        switch self {
        case .firstSip: [Color(hex: 0x9BE4FF), Color(hex: 0x4F9BFF)]
        case .streak3: [Color(hex: 0xFFD08A), Color(hex: 0xFF7A6B)]
        case .streak7: [Color(hex: 0xFFC4E4), Color(hex: 0xA98BFF)]
        case .streak30: [Color(hex: 0xFFE68A), Color(hex: 0xFFAA33)]
        case .earlyBird: [Color(hex: 0xFFF3A0), Color(hex: 0xFFC94D)]
        case .rainbow: [Color(hex: 0xB8F2C8), Color(hex: 0x5CC8C2)]
        case .overachiever: [Color(hex: 0x9EE7FF), Color(hex: 0x5D7CFF)]
        case .liters10: [Color(hex: 0xD7C8FF), Color(hex: 0x8D7BFF)]
        case .liters100: [Color(hex: 0xA8DBFF), Color(hex: 0x3D6FE0)]
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
