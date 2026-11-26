import SwiftUI

struct GardenView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme

    @State private var appeared = false
    @State private var selectedBadge: Achievement?

    private let calendar = Calendar.current

    private static let levels: [(threshold: Int, name: String, emoji: String)] = [
        (0, "Seedling Patch", "🌱"),
        (7, "Cozy Garden", "🌷"),
        (21, "Blooming Meadow", "🌼"),
        (50, "Enchanted Grove", "🌳"),
        (100, "Dew Paradise", "🏝️")
    ]

    var body: some View {
        let totals = store.totalsByDay()
        let unlocked = store.unlockedAchievements()
        let flowers = store.goalMetDays

        ZStack(alignment: .top) {
            theme.canvas.ignoresSafeArea()

            GardenLandscape(flowers: flowers)
                .frame(height: 520)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 0) {
                    header(flowers: flowers)
                        .padding(.horizontal, 22)
                        .floatIn(appeared, index: 0)
                    // Leaves a window onto the hills and flowers drawn behind the scroll view.
                    Color.clear
                        .frame(height: 272)
                    VStack(spacing: 22) {
                        friendsSection(flowers: flowers).floatIn(appeared, index: 1)
                        levelCard(flowers: flowers).floatIn(appeared, index: 2)
                        gardenCard(totals: totals).floatIn(appeared, index: 3)
                        badgesSection(unlocked: unlocked).floatIn(appeared, index: 4)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                    .canvasSheet()
                }
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { appeared = true }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(achievement: badge, isUnlocked: unlocked.contains(badge))
                .presentationDetents([.height(380)])
                .presentationCornerRadius(38)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private func currentLevel(_ flowers: Int) -> (index: Int, name: String, emoji: String, threshold: Int) {
        let levels = Self.levels
        let index = levels.lastIndex { flowers >= $0.threshold } ?? 0
        return (index, levels[index].name, levels[index].emoji, levels[index].threshold)
    }

    private func header(flowers: Int) -> some View {
        let level = currentLevel(flowers)
        return VStack(alignment: .leading, spacing: 8) {
            CapsLabel(text: "Every goal blooms", color: Color.white.opacity(0.85), size: 12)
            Text("Dew Garden")
                .font(.dewy(34, .black))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.12), radius: 0, x: 0, y: 3)
            HStack(spacing: 6) {
                Text(level.emoji)
                Text(level.name)
                    .font(.dewy(15, .heavy))
                    .foregroundStyle(Color(hex: 0x1E2340))
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
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
                    .fill(Palette.leaf)
                Circle()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 4)
                    .padding(5)
                VStack(spacing: -2) {
                    Text("\(flowers)")
                        .font(.dewy(30, .black))
                        .foregroundStyle(.white)
                    CapsLabel(text: "flowers", color: Color.white.opacity(0.85), size: 9)
                }
            }
            .frame(width: 88, height: 88)
            .shadow(color: Palette.leaf.opacity(0.4), radius: 10, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 8) {
                CapsLabel(text: "Garden level \(level.index + 1)", color: theme.inkSoft, size: 11)
                Text(level.name)
                    .font(.dewy(21, .black))
                    .foregroundStyle(theme.ink)
                ProgressCapsule(progress: progress, tint: Palette.leafDeep)
                    .frame(height: 12)
                if let next {
                    Text("\(next.threshold - flowers) more to \(next.emoji) \(next.name)")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                } else {
                    Text("Your garden is legendary ✨")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
        }
        .dewyCard()
        .padding(.horizontal, 20)
    }

    // MARK: Friends

    private func friendsSection(flowers: Int) -> some View {
        let count = DewyFriend.allCases.filter { flowers >= $0.flowersNeeded }.count
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Dewy & friends", trailing: "\(count)/\(DewyFriend.allCases.count) unlocked")
                .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(DewyFriend.allCases) { friend in
                        FriendTile(friend: friend, isUnlocked: flowers >= friend.flowersNeeded)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
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

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Last 5 weeks", trailing: "🌸 goal · 🌱 halfway")
            VStack(spacing: 8) {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.dewy(12, .heavy))
                            .foregroundStyle(theme.inkSoft)
                    }
                }
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                            let amount = totals[day] ?? 0
                            GardenPlot(
                                ratio: amount / store.goal,
                                isFuture: day > today,
                                isToday: day == today,
                                petal: GardenLandscape.petals[(calendar.ordinality(of: .day, in: .era, for: day) ?? index) % GardenLandscape.petals.count],
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
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Badges", trailing: "\(unlocked.count)/\(Achievement.allCases.count) unlocked")
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

// MARK: - Pieces

/// A collectible friend card, in the spirit of a sticker album.
private struct FriendTile: View {
    @Environment(\.dewyTheme) private var theme
    var friend: DewyFriend
    var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            MascotView(
                progress: 0.74,
                mood: friend.mood,
                size: 72,
                accessory: isUnlocked ? friend.accessory : .none,
                liquid: isUnlocked ? friend.liquid : theme.inkSoft.opacity(0.35),
                backdrop: isUnlocked ? .tile : .light,
                animated: false
            )
            .opacity(isUnlocked ? 1 : 0.6)
            .frame(height: 100)

            VStack(spacing: 2) {
                Text(friend.name)
                    .font(.dewy(17, .black))
                    .foregroundStyle(isUnlocked ? Color.white : theme.ink)
                if isUnlocked {
                    CapsLabel(text: "Unlocked", color: Color.white.opacity(0.8), size: 10)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .black))
                        Text("\(friend.flowersNeeded) FLOWERS")
                            .font(.dewy(10, .heavy))
                            .tracking(0.8)
                    }
                    .foregroundStyle(theme.inkSoft)
                }
            }
        }
        .frame(width: 126)
        .padding(.vertical, 16)
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
                .shadow(color: isUnlocked ? friend.tile.opacity(0.35) : theme.shadow, radius: 12, x: 0, y: 7)
        }
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

/// A bold square badge tile.
struct BadgeTile: View {
    @Environment(\.dewyTheme) private var theme
    var achievement: Achievement
    var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.emoji)
                .font(.system(size: 34))
                .grayscale(isUnlocked ? 0 : 1)
                .opacity(isUnlocked ? 1 : 0.4)
                .frame(width: 58, height: 58)
                .background(Color.white.opacity(isUnlocked ? 0.25 : 0), in: Circle())
            Text(achievement.title)
                .font(.dewy(12, .black))
                .foregroundStyle(isUnlocked ? Color.white : theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isUnlocked ? achievement.tint : theme.card)
                .shadow(color: isUnlocked ? achievement.tint.opacity(0.35) : theme.shadow, radius: 10, x: 0, y: 6)
        }
        .overlay(alignment: .topTrailing) {
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(theme.inkSoft)
                    .padding(10)
            }
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
            HeroBackdrop(top: isUnlocked ? achievement.tint : theme.inkSoft, bottom: isUnlocked ? achievement.tint : theme.inkSoft, rays: true, rayCenter: UnitPoint(x: 0.5, y: 0.34))
            VStack(spacing: 14) {
                Text(achievement.emoji)
                    .font(.system(size: 64))
                    .grayscale(isUnlocked ? 0 : 1)
                    .frame(width: 124, height: 124)
                    .background(Color.white.opacity(0.25), in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 4))
                    .scaleEffect(pop ? 1 : 0.6)
                    .rotationEffect(.degrees(pop ? 0 : -15))
                Text(achievement.title)
                    .font(.dewy(28, .black))
                    .foregroundStyle(.white)
                Text(achievement.detail)
                    .font(.dewy(17, .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                CapsLabel(text: isUnlocked ? "Unlocked ✨" : "Keep sipping to unlock", color: Color(hex: 0x1E2340), size: 12)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
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
