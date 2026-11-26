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
        case .water: Color(hex: 0x5EC6F4)
        case .sparkling: Color(hex: 0x62D8E0)
        case .tea: Color(hex: 0x9FD777)
        case .coffee: Color(hex: 0xD9A57E)
        case .juice: Color(hex: 0xFFB45A)
        case .milk: Color(hex: 0xC1B5FF)
        case .smoothie: Color(hex: 0xFF92BC)
        case .soda: Color(hex: 0xFF8189)
        case .lemonade: Color(hex: 0xFFD862)
        case .cocoa: Color(hex: 0xC48F70)
        case .coconut: Color(hex: 0x97DDC8)
        case .matcha: Color(hex: 0x92CE7E)
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
    /// Mirror logged drinks into Apple Health and read body weight from it.
    var healthSyncOn = false
    /// Show today's progress on the Lock Screen and in the Dynamic Island.
    var liveActivityOn = true

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
        healthSyncOn = try c.decodeIfPresent(Bool.self, forKey: .healthSyncOn) ?? d.healthSyncOn
        liveActivityOn = try c.decodeIfPresent(Bool.self, forKey: .liveActivityOn) ?? d.liveActivityOn
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
    /// Dew Drops spent, friends, wardrobe and decor.
    var collection = CollectionState()

    init(profile: UserProfile = UserProfile(), entries: [DrinkEntry] = [], hasOnboarded: Bool = false, challenges: [String: Date] = [:], collection: CollectionState = CollectionState()) {
        self.profile = profile
        self.entries = entries
        self.hasOnboarded = hasOnboarded
        self.challenges = challenges
        self.collection = collection
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
        collection = (try? c.decodeIfPresent(CollectionState.self, forKey: .collection)) ?? CollectionState()
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

// MARK: - Friends

/// The collectible cast: little droplet creatures who hang out with Dewy.
/// Bought with Dew Drops in the Friends tab; a few are Dewy+ exclusives.
enum Friend: String, CaseIterable, Identifiable, Codable {
    case cat, bunny, frog, axolotl, bear, penguin, fox, chick, panda, unicorn, dino, octopus

    var id: String { rawValue }

    var name: String {
        switch self {
        case .cat: "Mochi"
        case .bunny: "Lulu"
        case .frog: "Pip"
        case .axolotl: "Coral"
        case .bear: "Honey"
        case .penguin: "Pebble"
        case .fox: "Clem"
        case .chick: "Sunny"
        case .panda: "Bao"
        case .unicorn: "Stella"
        case .dino: "Sprout"
        case .octopus: "Inky"
        }
    }

    var species: String {
        switch self {
        case .cat: "Ginger tabby"
        case .bunny: "Meadow hare"
        case .frog: "Pond tree-frog"
        case .axolotl: "Coral axolotl"
        case .bear: "Honey bear"
        case .penguin: "Coastal penguin"
        case .fox: "Woodland fox"
        case .chick: "Dawn songbird"
        case .panda: "Bamboo panda"
        case .unicorn: "Cloud kirin"
        case .dino: "Moss stegosaur"
        case .octopus: "Tidepool octopus"
        }
    }

    var bio: String {
        switch self {
        case .cat: "Naps in sunbeams, sips in between."
        case .bunny: "Hops to the fountain every hour."
        case .frog: "Lives for rainy days."
        case .axolotl: "Smiles underwater. And above it."
        case .bear: "Swaps honey for herbal tea."
        case .penguin: "Prefers it ice cold."
        case .fox: "Clever about sneaking in a glass."
        case .chick: "Up at dawn with a tiny cup."
        case .panda: "Bamboo tea connoisseur."
        case .unicorn: "Sparkling water only, darling."
        case .dino: "Roars for refills."
        case .octopus: "Holds eight glasses at once."
        }
    }

    /// The friend's signature color: card wash, glow and accents.
    var tint: Color {
        switch self {
        case .cat: Color(hex: 0xFFB48F)
        case .bunny: Color(hex: 0xC3A8FF)
        case .frog: Color(hex: 0x8EDDB0)
        case .axolotl: Color(hex: 0xFF9FC6)
        case .bear: Color(hex: 0xE9B07A)
        case .penguin: Color(hex: 0x9CB2FF)
        case .fox: Color(hex: 0xFFA36B)
        case .chick: Color(hex: 0xFFD866)
        case .panda: Color(hex: 0xB9C1D6)
        case .unicorn: Color(hex: 0xF2B8FF)
        case .dino: Color(hex: 0xA9D58C)
        case .octopus: Color(hex: 0xB7A3F5)
        }
    }

    /// Price in Dew Drops. Mochi is Dewy's first friend and comes free.
    var price: Int {
        switch self {
        case .cat: 0
        case .bunny, .chick: 180
        case .frog, .bear: 240
        case .penguin, .fox: 300
        case .axolotl, .panda: 380
        case .unicorn, .dino, .octopus: 450
        }
    }

    var isPremium: Bool {
        switch self {
        case .unicorn, .dino, .octopus: true
        default: false
        }
    }
}

// MARK: - Wardrobe

enum OutfitSlot: String, CaseIterable, Codable, Identifiable {
    case head, face, neck
    var id: String { rawValue }

    var title: String {
        switch self {
        case .head: "Hats"
        case .face: "Glasses"
        case .neck: "Neckwear"
        }
    }
}

/// Things Dewy can wear. Drawn natively in SwiftUI Canvas over and behind the mascot.
enum Outfit: String, CaseIterable, Codable, Identifiable {
    case beanie, crown, flowercrown, bow, sunglasses, partyhat, headphones, froghat, strawhat, wizardhat, chefhat, scarf, bowtie, leafhat

    var id: String { rawValue }

    var name: String {
        switch self {
        case .beanie: "Cozy Beanie"
        case .crown: "Royal Crown"
        case .flowercrown: "Flower Crown"
        case .bow: "Big Bow"
        case .sunglasses: "Heart Shades"
        case .partyhat: "Party Hat"
        case .headphones: "Lo-fi Phones"
        case .froghat: "Froggy Hat"
        case .strawhat: "Sun Hat"
        case .wizardhat: "Wizard Hat"
        case .chefhat: "Chef Toque"
        case .scarf: "Knit Scarf"
        case .bowtie: "Bow Tie"
        case .leafhat: "Leaf Hat"
        }
    }

    var slot: OutfitSlot {
        switch self {
        case .sunglasses: .face
        case .scarf, .bowtie: .neck
        default: .head
        }
    }

    /// Solid hats that completely cover Dewy's upper crown, tucking the droplet curl cleanly inside.
    var coversCrown: Bool {
        switch self {
        case .beanie, .strawhat, .froghat, .wizardhat, .chefhat, .leafhat: true
        case .crown, .flowercrown, .bow, .partyhat, .headphones, .sunglasses, .scarf, .bowtie: false
        }
    }

    var price: Int {
        switch self {
        case .bow, .bowtie, .leafhat: 60
        case .beanie, .partyhat, .sunglasses: 90
        case .flowercrown, .strawhat, .scarf: 120
        case .headphones, .froghat, .chefhat: 160
        case .crown, .wizardhat: 220
        }
    }

    var isPremium: Bool { self == .crown || self == .wizardhat }

    var tint: Color {
        switch self {
        case .beanie: Color(hex: 0x6FD3C8)
        case .crown: Color(hex: 0xFFCF5C)
        case .flowercrown: Color(hex: 0xFFB3CF)
        case .bow: Color(hex: 0xFF9CC2)
        case .sunglasses: Color(hex: 0xFF9DB8)
        case .partyhat: Color(hex: 0x9BE3C3)
        case .headphones: Color(hex: 0xFFC2A1)
        case .froghat: Color(hex: 0x9EDFA6)
        case .strawhat: Color(hex: 0xF5CF8E)
        case .wizardhat: Color(hex: 0x9C95F2)
        case .chefhat: Color(hex: 0xD9E0EC)
        case .scarf: Color(hex: 0xFF9B8A)
        case .bowtie: Color(hex: 0xFFD866)
        case .leafhat: Color(hex: 0x8ED39A)
        }
    }

    /// Where the item sits on Dewy, in the mascot's 200×220 design box:
    /// the center point, the drawn width and a little tilt.
    var placement: (x: CGFloat, y: CGFloat, width: CGFloat, rotation: Double) {
        switch self {
        case .beanie: (102, 42, 104, -4)
        case .crown: (106, 26, 72, 8)
        case .flowercrown: (102, 46, 114, -4)
        case .bow: (142, 58, 64, 18)
        case .sunglasses: (100, 134, 124, 0)
        case .partyhat: (108, 14, 58, 10)
        case .headphones: (100, 88, 178, 0)
        case .froghat: (101, 48, 110, -3)
        case .strawhat: (100, 46, 150, -5)
        case .wizardhat: (108, 24, 104, 8)
        case .chefhat: (102, 26, 84, 0)
        case .scarf: (102, 214, 122, 0)
        case .bowtie: (100, 182, 52, 0)
        case .leafhat: (102, 46, 118, 6)
        }
    }
}

// MARK: - Decor

/// Little things placed around Dewy's pond on the Today screen.
enum Decor: String, CaseIterable, Codable, Identifiable {
    case flowers, duck, mushroom, lantern, umbrella, swan, blossom, fountain, balloon, rainbow

    var id: String { rawValue }

    var name: String {
        switch self {
        case .flowers: "Tulip Patch"
        case .duck: "Rubber Duck"
        case .mushroom: "Toadstools"
        case .lantern: "Paper Lantern"
        case .umbrella: "Beach Umbrella"
        case .swan: "Swan Float"
        case .blossom: "Blossom Tree"
        case .fountain: "Little Fountain"
        case .balloon: "Hot-air Balloon"
        case .rainbow: "Rainbow"
        }
    }

    var imageName: String { "decor-\(rawValue)" }

    var price: Int {
        switch self {
        case .flowers, .duck: 80
        case .mushroom, .lantern: 110
        case .umbrella, .swan: 150
        case .blossom, .fountain: 200
        case .balloon, .rainbow: 260
        }
    }

    var isPremium: Bool { self == .rainbow || self == .balloon }

    var tint: Color {
        switch self {
        case .flowers: Color(hex: 0xFFB3CF)
        case .duck: Color(hex: 0xFFD866)
        case .mushroom: Color(hex: 0xFF8E8E)
        case .lantern: Color(hex: 0xFFB98A)
        case .umbrella: Color(hex: 0xFF9B8A)
        case .swan: Color(hex: 0xC9D6EA)
        case .blossom: Color(hex: 0xFFB8D6)
        case .fountain: Color(hex: 0x8EDFE0)
        case .balloon: Color(hex: 0xC3A8FF)
        case .rainbow: Color(hex: 0xFFC48F)
        }
    }

    /// Floats on the water instead of standing on the shore.
    var floats: Bool { self == .duck || self == .swan }

    /// Drifts high in the sky.
    var flies: Bool { self == .balloon || self == .rainbow }
}

// MARK: - Journey

/// The places Dewy visits. Every day the goal is reached, Dewy travels to the next one.
enum Chapter: String, CaseIterable, Codable, Identifiable {
    case spring, brook, meadow, falls, cove, peak, grove, lake

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spring: "Misty Spring"
        case .brook: "Bubble Brook"
        case .meadow: "Lily Meadow"
        case .falls: "Rainbow Falls"
        case .cove: "Coral Cove"
        case .peak: "Cloud Peak"
        case .grove: "Lantern Grove"
        case .lake: "Starlight Lake"
        }
    }

    var tint: Color {
        switch self {
        case .spring: Color(hex: 0x8ED6B8)
        case .brook: Color(hex: 0x7FCBEB)
        case .meadow: Color(hex: 0xA9DC8E)
        case .falls: Color(hex: 0x9CC3FF)
        case .cove: Color(hex: 0xFFB59C)
        case .peak: Color(hex: 0xFFCB86)
        case .grove: Color(hex: 0xE3A8F0)
        case .lake: Color(hex: 0x8F9BF0)
        }
    }

    /// Four little story beats, revealed at 25%, 50%, 75% and 100% of the day's goal.
    var beats: [String] {
        switch self {
        case .spring: [
            "Dewy wakes beside a mossy spring. The air smells like rain.",
            "A shy frog points to a path of glittering pebbles.",
            "The spring bubbles a little song. Dewy hums along.",
            "Dewy fills a tiny acorn cup and makes a wish."
        ]
        case .brook: [
            "Bubbles drift down the brook like little moons.",
            "Dewy hops the stepping stones. One, two, wobble, three!",
            "A family of ducks shares their picnic spot.",
            "Dewy catches the biggest bubble of the day. Pop!"
        ]
        case .meadow: [
            "Lily pads stretch across the pond like stepping clouds.",
            "Dewy naps on a pad while dragonflies dance.",
            "A lotus opens just as Dewy says hello.",
            "The whole pond sparkles. Dewy feels brand new."
        ]
        case .falls: [
            "The roar of Rainbow Falls echoes through the hills.",
            "Mist tickles Dewy's cheeks. Everything glows.",
            "Dewy finds the exact spot where the rainbow begins.",
            "Standing in the spray, Dewy shines in seven colors."
        ]
        case .cove: [
            "Warm sand, cool waves. Dewy dips a toe in.",
            "A hermit crab trades Dewy a pearly shell.",
            "Dewy builds a castle with a moat full of seawater.",
            "The tide sings goodnight to the little castle."
        ]
        case .peak: [
            "Up, up, up the soft green mountain trail.",
            "Clouds roll beneath Dewy like a fluffy sea.",
            "Dewy shares a thermos of tea with a friendly goat.",
            "At the top, the golden sun gives Dewy a warm hug."
        ]
        case .grove: [
            "Paper lanterns flicker on in the blossom grove.",
            "Petals swirl around Dewy like pink snow.",
            "An old tree tells stories of a thousand springs.",
            "Dewy hangs a lantern of their own. It glows aqua."
        ]
        case .lake: [
            "Fireflies wake as the sky turns velvet blue.",
            "The lake holds the stars like a mirror.",
            "Dewy floats on a lily boat and counts constellations.",
            "A shooting star! Dewy wishes for tomorrow's adventure."
        ]
        }
    }
}

// MARK: - Collection

/// Dew Drops spent, things owned and how Dewy is dressed. Stored with the rest of the app data.
struct CollectionState: Codable, Equatable {
    var spentDrops = 0
    var friends: [Friend] = [.cat]
    var outfits: [Outfit] = []
    var decor: [Decor] = []
    /// Equipped items, one per slot.
    var wearing: [OutfitSlot: Outfit] = [:]
    /// Friends who hang out next to Dewy on the Today screen (up to two).
    var companions: [Friend] = [.cat]
    /// Decor shown around the pond (up to three).
    var placed: [Decor] = []
    /// The day Dewy+ was first seen, so the 2× goal drops never apply retroactively.
    var premiumSince: Date?

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spentDrops = (try? c.decodeIfPresent(Int.self, forKey: .spentDrops)) ?? 0
        friends = Self.decodeList(Friend.self, c, .friends) ?? [.cat]
        outfits = Self.decodeList(Outfit.self, c, .outfits) ?? []
        decor = Self.decodeList(Decor.self, c, .decor) ?? []
        companions = Self.decodeList(Friend.self, c, .companions) ?? [.cat]
        placed = Self.decodeList(Decor.self, c, .placed) ?? []
        let rawWearing = (try? c.decodeIfPresent([String: String].self, forKey: .wearing)) ?? [:]
        var wearing: [OutfitSlot: Outfit] = [:]
        for (slot, item) in rawWearing {
            if let slot = OutfitSlot(rawValue: slot), let item = Outfit(rawValue: item) { wearing[slot] = item }
        }
        self.wearing = wearing
        premiumSince = try? c.decodeIfPresent(Date.self, forKey: .premiumSince)
        if !friends.contains(.cat) { friends.insert(.cat, at: 0) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(spentDrops, forKey: .spentDrops)
        try c.encode(friends.map(\.rawValue), forKey: .friends)
        try c.encode(outfits.map(\.rawValue), forKey: .outfits)
        try c.encode(decor.map(\.rawValue), forKey: .decor)
        try c.encode(companions.map(\.rawValue), forKey: .companions)
        try c.encode(placed.map(\.rawValue), forKey: .placed)
        var rawWearing: [String: String] = [:]
        for (slot, item) in wearing { rawWearing[slot.rawValue] = item.rawValue }
        try c.encode(rawWearing, forKey: .wearing)
        try c.encodeIfPresent(premiumSince, forKey: .premiumSince)
    }

    private enum CodingKeys: String, CodingKey {
        case spentDrops, friends, outfits, decor, wearing, companions, placed, premiumSince
    }

    /// Reads a list of raw values, skipping anything this version doesn't know.
    private static func decodeList<T: RawRepresentable>(_ type: T.Type, _ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [T]? where T.RawValue == String {
        guard let raw = try? c.decodeIfPresent([String].self, forKey: key) else { return nil }
        return raw.compactMap(T.init(rawValue:))
    }

    /// Outfits Dewy is wearing, drawn back to front.
    var wornOutfits: [Outfit] {
        OutfitSlot.allCases.compactMap { wearing[$0] }
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

    /// The wardrobe item awarded for finishing the challenge.
    var reward: Outfit {
        switch self {
        case .morningGlass: .strawhat
        case .perfectWeek: .crown
        case .sodaFree: .leafhat
        case .caffeineCut: .headphones
        case .teaRitual: .bow
        case .rainbow: .flowercrown
        }
    }

    var symbol: String {
        switch self {
        case .morningGlass: "sunrise.fill"
        case .perfectWeek: "crown.fill"
        case .sodaFree: "leaf.fill"
        case .caffeineCut: "moon.zzz.fill"
        case .teaRitual: "cup.and.saucer.fill"
        case .rainbow: "paintpalette.fill"
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
