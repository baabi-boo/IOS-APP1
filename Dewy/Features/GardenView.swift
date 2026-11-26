import SwiftUI

struct GardenView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme

    @State private var appeared = false
    @State private var selectedBadge: Achievement?

    private let calendar = Calendar.current

    private static let levels: [(threshold: Int, name: String, symbol: String)] = [
        (0, "Seedling Patch", "leaf.fill"),
        (7, "Cozy Garden", "camera.macro"),
        (21, "Blooming Meadow", "sun.max.fill"),
        (50, "Enchanted Grove", "tree.fill"),
        (100, "Dew Paradise", "sparkles")
    ]

    private let sceneHeight: CGFloat = 470

    var body: some View {
        let totals = store.totalsByDay()
        let unlocked = store.unlockedAchievements()
        let flowers = store.goalMetDays

        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    header(flowers: flowers)
                        .padding(.horizontal, 22)
                        .padding(.top, 6)
                        .frame(height: sceneHeight - 30, alignment: .top)
                        .floatIn(appeared, index: 0)
                        .background(alignment: .top) {
                            GardenScene(flowers: flowers, height: sceneHeight)
                        }
                    VStack(spacing: 24) {
                        levelCard(flowers: flowers).floatIn(appeared, index: 1)
                        challengesSection.floatIn(appeared, index: 2).id("challenges")
                        friendsSection(flowers: flowers).floatIn(appeared, index: 3)
                        gardenCard(totals: totals).floatIn(appeared, index: 4)
                        badgesSection(unlocked: unlocked).floatIn(appeared, index: 5)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                    .canvasSheet()
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                appeared = true
                if LaunchOptions.screenshot == "challenges" {
                    // Demo screenshot: show the challenges and friends.
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.6))
                        reader.scrollTo("challenges", anchor: .top)
                    }
                }
            }
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(achievement: badge, isUnlocked: unlocked.contains(badge))
                .presentationDetents([.height(400)])
                .presentationCornerRadius(36)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private func currentLevel(_ flowers: Int) -> (index: Int, name: String, symbol: String, threshold: Int) {
        let levels = Self.levels
        let index = levels.lastIndex { flowers >= $0.threshold } ?? 0
        return (index, levels[index].name, levels[index].symbol, levels[index].threshold)
    }

    private func header(flowers: Int) -> some View {
        let level = currentLevel(flowers)
        return VStack(alignment: .leading, spacing: 8) {
            CapsLabel(text: "Every goal blooms", color: Color.white.opacity(0.85), size: 12)
            Text("Dew Garden")
                .font(.display(36))
                .foregroundStyle(.white)
                .shadow(color: theme.sky[0].opacity(0.35), radius: 0, x: 0, y: 3)
            HStack(spacing: 7) {
                IconTile(systemImage: level.symbol, color: Palette.leafDeep, size: 24)
                Text(level.name)
                    .font(.display(16))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.leading, 6)
            .padding(.trailing, 13)
            .frame(height: 36)
            .background(Color.white, in: Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Level

    private func levelCard(flowers: Int) -> some View {
        let levels = Self.levels
        let level = currentLevel(flowers)
        let next = level.index + 1 < levels.count ? levels[level.index + 1] : nil
        let progress: Double = {
            guard let next else { return 1 }
            return Double(flowers - level.threshold) / Double(next.threshold - level.threshold)
        }()

        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x2E9E4F))
                    .offset(y: 4)
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0x6FD66F), Palette.leaf], startPoint: .top, endPoint: .bottom))
                Circle()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 4)
                    .padding(6)
                VStack(spacing: -3) {
                    Text("\(flowers)")
                        .font(.display(32))
                        .foregroundStyle(.white)
                    Text("flowers")
                        .font(.display(12, .medium))
                        .foregroundStyle(Color.white.opacity(0.88))
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 7) {
                CapsLabel(text: "Garden level \(level.index + 1)", color: theme.inkSoft, size: 11)
                Text(level.name)
                    .font(.display(22))
                    .foregroundStyle(theme.ink)
                ProgressCapsule(progress: progress, tint: Palette.leaf)
                    .frame(height: 12)
                if let next {
                    Text("\(next.threshold - flowers) more flowers to \(next.name)")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                } else {
                    Text("Your garden is legendary")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
        }
        .dewyCard()
        .padding(.horizontal, 20)
    }

    // MARK: Challenges

    private var challengesSection: some View {
        let joined = ChallengeKind.allCases.filter { store.isJoined($0) }.count
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Challenges", trailing: joined == 0 ? "Pick one!" : "\(joined) active")
                .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(sortedChallenges) { challenge in
                        ChallengeCard(challenge: challenge, progress: store.progress(of: challenge)) {
                            Haptics.success()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                store.join(challenge)
                            }
                        }
                        .contextMenu {
                            if store.isJoined(challenge) {
                                Button(role: .destructive) {
                                    withAnimation(.spring) { store.leave(challenge) }
                                } label: {
                                    Label("Leave challenge", systemImage: "xmark.circle")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    /// Active challenges first, then the ones you can join, then finished ones.
    private var sortedChallenges: [ChallengeKind] {
        func rank(_ challenge: ChallengeKind) -> Int {
            switch store.progress(of: challenge).state {
            case .active: 0
            case .notStarted, .failed: 1
            case .completed: 2
            }
        }
        return ChallengeKind.allCases.sorted { rank($0) < rank($1) }
    }

    // MARK: Friends

    private func friendsSection(flowers: Int) -> some View {
        let count = DewyFriend.allCases.filter { flowers >= $0.flowersNeeded }.count
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Dewy & friends", trailing: "\(count)/\(DewyFriend.allCases.count) found")
                .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(DewyFriend.allCases) { friend in
                        FriendTile(friend: friend, isUnlocked: flowers >= friend.flowersNeeded)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    // MARK: Garden grid

    private func gardenCard(totals: [Date: Double]) -> some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let gridStart = calendar.date(byAdding: .day, value: -28, to: weekStart) ?? weekStart
        let days: [Date] = (0..<35).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let weekdays = Array(symbols[first...] + symbols[..<first])
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Last 5 weeks", trailing: "flower = goal")
            VStack(spacing: 8) {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.display(13))
                            .foregroundStyle(theme.inkSoft)
                    }
                }
                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: LaunchOptions.freezesMotion)) { timeline in
                    let t = LaunchOptions.freezesMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                            let amount = totals[day] ?? 0
                            GardenPlot(
                                ratio: amount / store.goal,
                                isFuture: day > today,
                                isToday: day == today,
                                petal: GardenPalette.petals[(calendar.ordinality(of: .day, in: .era, for: day) ?? index) % GardenPalette.petals.count],
                                sway: sin(t * 1.6 + Double(index) * 0.8) * 6
                            )
                        }
                    }
                }
            }
            .dewyCard(padding: 16)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Badges

    private func badgesSection(unlocked: Set<Achievement>) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Badges", trailing: "\(unlocked.count)/\(Achievement.allCases.count) earned")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Achievement.allCases) { achievement in
                    Button {
                        Haptics.tap()
                        selectedBadge = achievement
                    } label: {
                        BadgeTile(achievement: achievement, isUnlocked: unlocked.contains(achievement))
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Garden scene

enum GardenPalette {
    static let petals: [Color] = [
        Color(hex: 0xFF6FA5), Color(hex: 0x9C7BFF), Color(hex: 0xFF9447),
        Color(hex: 0x3AAEFF), Color(hex: 0xFF5C6E), Color(hex: 0xFFC83D)
    ]
}

/// Rolling hills under the world's sky, a flower for every goal day,
/// and Dewy with the friends you've found, hanging out in the meadow.
private struct GardenScene: View {
    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var flowers: Int
    var height: CGFloat

    private let far = HillShape(left: 0.6, peakX: 0.22, peakY: 0.5, right: 0.66)
    private let mid = HillShape(left: 0.76, peakX: 0.76, peakY: 0.6, right: 0.66)
    private let near = HillShape(left: 0.84, peakX: 0.36, peakY: 0.76, right: 0.86)

    /// Flower spots as (hill, x, size): 0 = middle hill, 1 = near hill.
    private let spots: [(Int, CGFloat, CGFloat)] = [
        (0, 0.5, 24), (0, 0.6, 28), (0, 0.7, 30), (0, 0.8, 26), (0, 0.9, 24), (0, 0.42, 22),
        (1, 0.06, 38), (1, 0.14, 44), (1, 0.31, 40), (1, 0.4, 36), (1, 0.6, 38),
        (1, 0.68, 42), (1, 0.88, 44), (1, 0.96, 38)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            SkyHeaderBackground(height: height, sunY: 60)

            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: reduceMotion || LaunchOptions.freezesMotion)) { timeline in
                let t = reduceMotion || LaunchOptions.freezesMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { proxy in
                    let w = proxy.size.width
                    let h = proxy.size.height
                    ZStack(alignment: .topLeading) {
                        far.fill(LinearGradient(colors: theme.isDark ? [Color(hex: 0x24527A), Color(hex: 0x1E4568)] : [Color(hex: 0xB4ECC0), Color(hex: 0x9BE0AB)], startPoint: .top, endPoint: .bottom))
                        mid.fill(LinearGradient(colors: theme.isDark ? [Color(hex: 0x1E6E5A), Color(hex: 0x185A4A)] : [Color(hex: 0x7EDB93), Color(hex: 0x5FCB7C)], startPoint: .top, endPoint: .bottom))

                        ForEach(0..<spots.count, id: \.self) { index in
                            if spots[index].0 == 0 {
                                plant(index: index, width: w, height: h, time: t)
                            }
                        }

                        near.fill(LinearGradient(colors: theme.isDark ? [Color(hex: 0x1A5E48), Color(hex: 0x134A39)] : [Color(hex: 0x58C978), Color(hex: 0x3DB563)], startPoint: .top, endPoint: .bottom))

                        // Dewy and friends stand on the near hill.
                        resident(.classic, x: 0.5, size: 104, width: w, height: h)
                        if flowers >= DewyFriend.sunny.flowersNeeded {
                            resident(.sunny, x: 0.23, size: 70, width: w, height: h)
                        }
                        if flowers >= DewyFriend.sprout.flowersNeeded {
                            resident(.sprout, x: 0.79, size: 70, width: w, height: h)
                        }

                        ForEach(0..<spots.count, id: \.self) { index in
                            if spots[index].0 == 1 {
                                plant(index: index, width: w, height: h, time: t)
                            }
                        }
                    }
                }
            }
            .frame(height: height)
        }
        .frame(height: height, alignment: .top)
        .allowsHitTesting(false)
    }

    private func resident(_ friend: DewyFriend, x: CGFloat, size: CGFloat, width w: CGFloat, height h: CGFloat) -> some View {
        let figureHeight = size * DewyGeometry.canvas.height / DewyGeometry.canvas.width
        let ground = h * near.surface(x)
        return MascotView(
            progress: 0.7,
            mood: friend.mood,
            size: size,
            accessory: friend.accessory,
            liquid: friend.liquid,
            animated: friend == .classic
        )
        .position(x: w * x, y: ground - figureHeight * 0.43 + 4)
    }

    @ViewBuilder
    private func plant(index: Int, width w: CGFloat, height h: CGFloat, time t: Double) -> some View {
        let spot = spots[index]
        let hill = spot.0 == 0 ? mid : near
        let x = w * spot.1
        let y = h * hill.surface(spot.1)
        let sway = sin(t * 1.5 + Double(index) * 0.9) * 6
        // Fill the near hill first so even a small garden looks lush up front.
        let order = spot.0 == 1 ? index - 6 : index + 8
        if order < flowers {
            FlowerView(color: GardenPalette.petals[index % GardenPalette.petals.count], size: spot.2, sway: sway)
                .position(x: x, y: y - spot.2 * 0.5)
        } else {
            SproutView(size: spot.2 * 0.55, sway: sway * 0.6)
                .position(x: x, y: y - spot.2 * 0.26)
        }
    }
}

// MARK: - Pieces

/// A week-long challenge card, with Dewy dressed for the occasion.
private struct ChallengeCard: View {
    var challenge: ChallengeKind
    var progress: ChallengeProgress
    var onJoin: () -> Void

    private var deep: Color { challenge.tint.blended(with: .black, by: 0.18) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(challenge.days) days")
                    .font(.display(13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(Color.white.opacity(0.24), in: Capsule())
                Spacer()
                if progress.state == .completed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            Text(challenge.title)
                .font(.display(22))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(challenge.rule)
                .font(.dewy(13, .bold))
                .foregroundStyle(Color.white.opacity(0.88))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    pips
                    action
                }
                Spacer(minLength: 0)
                MascotView(
                    progress: progress.state == .completed ? 1.1 : 0.45 + 0.5 * progress.fraction,
                    mood: progress.state == .completed ? .ecstatic : .happy,
                    size: 84,
                    accessory: challenge.accessory,
                    liquid: challenge.liquid,
                    backdrop: .tile,
                    animated: false,
                    showsShadow: false
                )
                .offset(x: 8, y: 6)
            }
        }
        .padding(16)
        .frame(width: 228, height: 226)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(challenge.tint)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 120, height: 120)
                        .offset(x: 40, y: -50)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.16), .clear], startPoint: .top, endPoint: .center))
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(deep)
                        .offset(y: 5)
                }
        }
        .padding(.bottom, 5)
    }

    private var pips: some View {
        HStack(spacing: 4) {
            ForEach(0..<challenge.days, id: \.self) { index in
                Capsule()
                    .fill(index < progress.daysDone ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 13, height: 8)
            }
        }
    }

    @ViewBuilder
    private var action: some View {
        switch progress.state {
        case .notStarted, .failed:
            Button(action: onJoin) {
                Text(progress.state == .failed ? "Try again" : "Join")
                    .font(.display(16))
                    .foregroundStyle(challenge.tint)
                    .padding(.horizontal, 18)
                    .frame(height: 36)
            }
            .buttonStyle(CandyButtonStyle(fill: .white, lip: Color.white.opacity(0.55), depth: 3))
        case .active:
            Text("Day \(min(progress.daysDone + 1, progress.total)) of \(progress.total)")
                .font(.display(16))
                .foregroundStyle(.white)
                .frame(height: 36)
        case .completed:
            Text("Completed!")
                .font(.display(16))
                .foregroundStyle(.white)
                .frame(height: 36)
        }
    }
}

/// A collectible friend card, in the spirit of a sticker album.
private struct FriendTile: View {
    @Environment(\.dewyTheme) private var theme
    var friend: DewyFriend
    var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            MascotView(
                progress: 0.74,
                mood: isUnlocked ? friend.mood : .okay,
                size: 86,
                accessory: isUnlocked ? friend.accessory : .none,
                liquid: isUnlocked ? friend.liquid : theme.inkSoft.opacity(0.3),
                backdrop: isUnlocked ? .tile : .light,
                animated: false,
                showsShadow: false
            )
            .opacity(isUnlocked ? 1 : 0.55)
            .frame(height: 100)

            VStack(spacing: 1) {
                Text(friend.name)
                    .font(.display(18))
                    .foregroundStyle(isUnlocked ? Color.white : theme.ink)
                if isUnlocked {
                    Text(friend.bio)
                        .font(.dewy(11.5, .bold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .black))
                        Text("\(friend.flowersNeeded) flowers")
                            .font(.dewy(11.5, .heavy))
                    }
                    .foregroundStyle(theme.inkSoft)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 128)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(isUnlocked ? friend.tile : theme.card)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(isUnlocked ? 0.14 : 0))
                        .frame(width: 90, height: 90)
                        .offset(x: 30, y: -30)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(isUnlocked ? friend.tile.blended(with: .black, by: 0.2) : theme.line)
                        .offset(y: 5)
                }
        }
        .padding(.bottom, 5)
    }
}

private struct GardenPlot: View {
    @Environment(\.dewyTheme) private var theme
    var ratio: Double
    var isFuture: Bool
    var isToday: Bool
    var petal: Color
    var sway: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            if isToday {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }
            Ellipse()
                .fill(Palette.soil.opacity(isFuture ? 0.12 : 0.35))
                .frame(width: 30, height: 8)
                .padding(.bottom, 5)
            plant
                .padding(.bottom, 8)
        }
        .frame(height: 50)
    }

    @ViewBuilder
    private var plant: some View {
        if isFuture {
            EmptyView()
        } else if ratio >= 1 {
            FlowerView(color: petal, size: 30, sway: sway)
        } else if ratio >= 0.5 {
            SproutView(size: 24, sway: sway * 0.7)
        } else if ratio > 0 {
            Circle()
                .fill(Palette.soil)
                .frame(width: 7, height: 7)
                .padding(.bottom, 1)
        }
    }
}

/// A candy medal for an achievement.
struct MedalView: View {
    var achievement: Achievement
    var isUnlocked: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(isUnlocked ? achievement.tint.blended(with: .black, by: 0.2) : Color(hex: 0xC9CDDB))
                .offset(y: size * 0.06)
            Circle()
                .fill(isUnlocked
                      ? LinearGradient(colors: [achievement.tint.blended(with: .white, by: 0.25), achievement.tint], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(hex: 0xEEF0F6), Color(hex: 0xDDE1EC)], startPoint: .top, endPoint: .bottom))
            Circle()
                .strokeBorder(Color.white.opacity(isUnlocked ? 0.45 : 0.8), lineWidth: size * 0.05)
                .padding(size * 0.09)
            Image(systemName: isUnlocked ? achievement.symbol : "lock.fill")
                .font(.system(size: size * (isUnlocked ? 0.36 : 0.28), weight: .heavy))
                .foregroundStyle(isUnlocked ? Color.white : Color(hex: 0xA9AEC2))
                .shadow(color: Color.black.opacity(isUnlocked ? 0.15 : 0), radius: 0, x: 0, y: 2)
        }
        .frame(width: size, height: size)
    }
}

struct BadgeTile: View {
    @Environment(\.dewyTheme) private var theme
    var achievement: Achievement
    var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            MedalView(achievement: achievement, isUnlocked: isUnlocked, size: 62)
            Text(achievement.title)
                .font(.display(14))
                .foregroundStyle(isUnlocked ? theme.ink : theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.card)
                .shadow(color: theme.shadow, radius: 10, x: 0, y: 6)
        }
    }
}

private struct BadgeDetailSheet: View {
    @Environment(\.dewyTheme) private var theme
    var achievement: Achievement
    var isUnlocked: Bool
    @State private var pop = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isUnlocked ? [achievement.tint.blended(with: .white, by: 0.15), achievement.tint] : [Color(hex: 0x9AA0B8), Color(hex: 0x7E849E)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 14) {
                MedalView(achievement: achievement, isUnlocked: isUnlocked, size: 128)
                    .scaleEffect(pop ? 1 : 0.6)
                    .rotationEffect(.degrees(pop ? 0 : -15))
                Text(achievement.title)
                    .font(.display(30))
                    .foregroundStyle(.white)
                Text(achievement.detail)
                    .font(.dewy(17, .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                Text(isUnlocked ? "Earned" : "Keep sipping to unlock")
                    .font(.display(15))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Color.white, in: Capsule())
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { pop = true }
            if isUnlocked { Haptics.success() }
        }
    }
}
