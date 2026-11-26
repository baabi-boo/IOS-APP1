import SwiftUI

// MARK: - Dew Drops
//
// Drops are earned, never sold. They are computed from the drink log every time,
// so they can't drift out of sync, and only what was spent is stored.
//
// - 50 as a welcome gift
// - 2 per sip, up to 8 sips a day
// - 3 per adventure beat (4 beats a day, at 25/50/75/100% of the goal)
// - 15 for reaching the goal (30 with Dewy+, from the day Dewy+ started)
// - +1 per streak day on goal days, up to +10
// - 40 per finished challenge, 25 per badge

struct DropBreakdown: Equatable {
    var gift = 50
    var sips = 0
    var adventures = 0
    var goals = 0
    var streaks = 0
    var challenges = 0
    var badges = 0

    var total: Int { gift + sips + adventures + goals + streaks + challenges + badges }
}

enum DropRules {
    static let gift = 50
    static let perSip = 2
    static let sipCap = 8
    static let perBeat = 3
    static let goal = 15
    static let streakCap = 10
    static let challenge = 40
    static let badge = 25
}

extension HydrationStore {
    var dropBreakdown: DropBreakdown {
        let calendar = Calendar.current
        var result = DropBreakdown()
        var byDay: [Date: [DrinkEntry]] = [:]
        for entry in entries {
            byDay[calendar.startOfDay(for: entry.date), default: []].append(entry)
        }
        let premiumStart = collection.premiumSince.map { calendar.startOfDay(for: $0) }
        var run = 0
        var previousGoalDay: Date?
        for day in byDay.keys.sorted() {
            let list = byDay[day] ?? []
            result.sips += min(list.count, DropRules.sipCap) * DropRules.perSip
            let total = list.reduce(0) { $0 + $1.effective }
            let progress = min(total / goal, 1)
            result.adventures += Int(floor(progress * 4)) * DropRules.perBeat
            guard total >= goal else { continue }
            if let previousGoalDay, calendar.dateComponents([.day], from: previousGoalDay, to: day).day == 1 {
                run += 1
            } else {
                run = 1
            }
            previousGoalDay = day
            var reward = DropRules.goal
            if isPremium, let premiumStart, day >= premiumStart { reward *= 2 }
            result.goals += reward
            result.streaks += min(run, DropRules.streakCap)
        }
        result.challenges = ChallengeKind.allCases.filter { progress(of: $0).state == .completed }.count * DropRules.challenge
        result.badges = unlockedAchievements().count * DropRules.badge
        return result
    }

    var dropsEarned: Int { dropBreakdown.total }

    var dropBalance: Int { max(dropsEarned - collection.spentDrops, 0) }

    /// Drops earned from today's drinking so far.
    var todayDrops: Int {
        let list = entries(on: .now)
        let total = list.reduce(0) { $0 + $1.effective }
        var drops = min(list.count, DropRules.sipCap) * DropRules.perSip
        drops += Int(floor(min(total / goal, 1) * 4)) * DropRules.perBeat
        if total >= goal {
            drops += goalReward + min(currentStreak, DropRules.streakCap)
        }
        return drops
    }

    /// What reaching today's goal pays.
    var goalReward: Int { isPremium ? DropRules.goal * 2 : DropRules.goal }

    /// Keeps the 2× bonus from ever applying to days before Dewy+.
    func notePremium(_ premium: Bool) {
        isPremium = premium
        if premium, collection.premiumSince == nil, !LaunchOptions.isDemo {
            collection.premiumSince = .now
            save()
        }
    }

    /// Demo mode: a steady, believable balance for screenshots, whatever the generated history earned.
    func settleDemoBalance() {
        guard LaunchOptions.isDemo else { return }
        collection.spentDrops = max(dropsEarned - DemoData.balance, 0)
    }

    // MARK: Shop

    func canAfford(_ price: Int) -> Bool { dropBalance >= price }

    func owns(_ friend: Friend) -> Bool { collection.friends.contains(friend) }

    /// Outfits bought with drops, plus the ones won by finishing challenges.
    func owns(_ outfit: Outfit) -> Bool {
        collection.outfits.contains(outfit) || challengeRewards.contains(outfit)
    }

    func owns(_ decor: Decor) -> Bool { collection.decor.contains(decor) }

    var challengeRewards: Set<Outfit> {
        Set(ChallengeKind.allCases.filter { progress(of: $0).state == .completed }.map(\.reward))
    }

    @discardableResult
    func buy(_ friend: Friend) -> Bool {
        guard !owns(friend), canAfford(friend.price) else { return false }
        collection.spentDrops += friend.price
        collection.friends.append(friend)
        if collection.companions.count < 2 { collection.companions.append(friend) }
        save()
        return true
    }

    @discardableResult
    func buy(_ outfit: Outfit) -> Bool {
        guard !owns(outfit), canAfford(outfit.price) else { return false }
        collection.spentDrops += outfit.price
        collection.outfits.append(outfit)
        collection.wearing[outfit.slot] = outfit
        save()
        return true
    }

    @discardableResult
    func buy(_ decor: Decor) -> Bool {
        guard !owns(decor), canAfford(decor.price) else { return false }
        collection.spentDrops += decor.price
        collection.decor.append(decor)
        if collection.placed.count < 3 { collection.placed.append(decor) }
        save()
        return true
    }

    func isWearing(_ outfit: Outfit) -> Bool { collection.wearing[outfit.slot] == outfit }

    func toggleWear(_ outfit: Outfit) {
        guard owns(outfit) else { return }
        if isWearing(outfit) {
            collection.wearing[outfit.slot] = nil
        } else {
            collection.wearing[outfit.slot] = outfit
        }
        save()
    }

    func isCompanion(_ friend: Friend) -> Bool { collection.companions.contains(friend) }

    /// Up to two friends hang out with Dewy; adding a third replaces the oldest.
    func toggleCompanion(_ friend: Friend) {
        guard owns(friend) else { return }
        if let index = collection.companions.firstIndex(of: friend) {
            collection.companions.remove(at: index)
        } else {
            if collection.companions.count >= 2 { collection.companions.removeFirst() }
            collection.companions.append(friend)
        }
        save()
    }

    func isPlaced(_ decor: Decor) -> Bool { collection.placed.contains(decor) }

    /// Up to three decorations around the pond; adding a fourth replaces the oldest.
    func togglePlaced(_ decor: Decor) {
        guard owns(decor) else { return }
        if let index = collection.placed.firstIndex(of: decor) {
            collection.placed.remove(at: index)
        } else {
            if collection.placed.count >= 3 { collection.placed.removeFirst() }
            collection.placed.append(decor)
        }
        save()
    }

    /// What Dewy is wearing right now.
    var outfits: [Outfit] { collection.wornOutfits.filter { owns($0) } }

    /// Friends shown beside Dewy on the Today screen.
    var companions: [Friend] { collection.companions.filter { owns($0) } }

    var placedDecor: [Decor] { collection.placed.filter { owns($0) } }
}

// MARK: - Journey

struct JourneyStop: Identifiable, Hashable {
    var date: Date
    var chapter: Chapter
    var id: Date { date }
}

extension HydrationStore {
    /// Goal days before today, which decide where today's adventure takes place.
    private var goalDaysBeforeToday: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return totalsByDay().filter { $0.key < today && $0.value >= goal }.count
    }

    /// Where Dewy is today. Every day the goal is reached, Dewy moves on to the next place.
    var todayChapter: Chapter {
        Chapter.allCases[goalDaysBeforeToday % Chapter.allCases.count]
    }

    /// How many laps of the eight places Dewy has finished.
    var journeyLap: Int { goalDaysBeforeToday / Chapter.allCases.count + 1 }

    /// Story beats revealed today (0…4).
    var beatsUnlocked: Int { Int(floor(min(todayProgress, 1) * 4)) }

    /// Past adventures, newest first.
    var journeyArchive: [JourneyStop] {
        let days = totalsByDay().filter { $0.value >= goal }.keys.sorted()
        let today = Calendar.current.startOfDay(for: .now)
        var stops: [JourneyStop] = []
        for (index, day) in days.enumerated() where day < today {
            stops.append(JourneyStop(date: day, chapter: Chapter.allCases[index % Chapter.allCases.count]))
        }
        return stops.reversed()
    }
}
