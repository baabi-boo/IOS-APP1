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

    private static let petals: [Color] = [
        Color(hex: 0xFF8FB1), Color(hex: 0xC3A8FF), Color(hex: 0xFF9E7A),
        Color(hex: 0x8ED8FF), Color(hex: 0xFFB5E8), Color(hex: 0x9EDDB8)
    ]

    var body: some View {
        let totals = store.totalsByDay()
        let unlocked = store.unlockedAchievements()

        ScrollView {
            VStack(spacing: 18) {
                header.floatIn(appeared, index: 0)
                levelCard(flowers: store.goalMetDays).floatIn(appeared, index: 1)
                gardenCard(totals: totals).floatIn(appeared, index: 2)
                badgesSection(unlocked: unlocked).floatIn(appeared, index: 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { appeared = true }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(achievement: badge, isUnlocked: unlocked.contains(badge))
                .presentationDetents([.height(360)])
                .presentationCornerRadius(36)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("EVERY GOAL BLOOMS")
                .font(.dewy(13, .bold))
                .tracking(1.2)
                .foregroundStyle(theme.inkSoft)
            Text("Dew Garden")
                .font(.dewy(30, .heavy))
                .foregroundStyle(theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Level

    private func levelCard(flowers: Int) -> some View {
        let levels = Self.levels
        let index = levels.lastIndex { flowers >= $0.threshold } ?? 0
        let current = levels[index]
        let next = index + 1 < levels.count ? levels[index + 1] : nil
        let progress: Double = {
            guard let next else { return 1 }
            return Double(flowers - current.threshold) / Double(next.threshold - current.threshold)
        }()

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(flowers)")
                        .font(.dewy(44, .heavy))
                        .foregroundStyle(theme.ink)
                    Text("flowers")
                        .font(.dewy(17, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
                Text("\(current.emoji) \(current.name)")
                    .font(.dewy(16, .bold))
                    .foregroundStyle(theme.accent)
                ProgressCapsule(progress: progress)
                    .frame(height: 10)
                if let next {
                    Text("\(next.threshold - flowers) more to \(next.name)")
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(theme.inkSoft)
                } else {
                    Text("Your garden is legendary ✨")
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(Palette.soil.opacity(0.35))
                        .frame(width: 110, height: 22)
                    HStack(alignment: .bottom, spacing: -10) {
                        FlowerView(color: Self.petals[1], size: 40, sway: sin(t * 1.4 + 1) * 6)
                        FlowerView(color: Self.petals[0], size: 58, sway: sin(t * 1.2) * 5)
                        FlowerView(color: Self.petals[3], size: 44, sway: sin(t * 1.5 + 2) * 6)
                    }
                    .padding(.bottom, 8)
                }
            }
            .frame(width: 116, height: 110)
        }
        .glassCard()
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
            SectionHeader(title: "Last 5 weeks", trailing: "🌸 bloom · 🌱 halfway")
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.dewy(12, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        let amount = totals[day] ?? 0
                        GardenPlot(
                            ratio: amount / store.goal,
                            isFuture: day > today,
                            isToday: day == today,
                            petal: Self.petals[(calendar.ordinality(of: .day, in: .era, for: day) ?? index) % Self.petals.count],
                            sway: sin(t * 1.6 + Double(index) * 0.8) * 6
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: Badges

    private func badgesSection(unlocked: Set<Achievement>) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Badges", trailing: "\(unlocked.count)/\(Achievement.allCases.count) unlocked")
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Achievement.allCases) { achievement in
                    Button {
                        Haptics.tap()
                        selectedBadge = achievement
                    } label: {
                        BadgeView(achievement: achievement, isUnlocked: unlocked.contains(achievement), size: 64)
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
            .glassCard()
        }
    }
}

// MARK: - Pieces

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
                    .strokeBorder(theme.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            Ellipse()
                .fill(Palette.soil.opacity(isFuture ? 0.12 : 0.32))
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

struct BadgeView: View {
    @Environment(\.dewyTheme) private var theme
    var achievement: Achievement
    var isUnlocked: Bool
    var size: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                        ? LinearGradient(colors: achievement.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [theme.inkSoft.opacity(0.18), theme.inkSoft.opacity(0.28)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(Circle().strokeBorder(Color.white.opacity(isUnlocked ? 0.85 : 0.4), lineWidth: 2.5))
                    .shadow(color: isUnlocked ? (achievement.colors.last ?? .clear).opacity(0.4) : .clear, radius: 10, x: 0, y: 6)
                Circle()
                    .fill(Color.white.opacity(isUnlocked ? 0.35 : 0))
                    .frame(width: size * 0.25, height: size * 0.25)
                    .offset(x: -size * 0.2, y: -size * 0.2)
                    .blur(radius: 2)
                Text(achievement.emoji)
                    .font(.system(size: size * 0.44))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.45)
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.14, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: size * 0.32, height: size * 0.32)
                        .background(theme.inkSoft, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .offset(x: size * 0.34, y: size * 0.34)
                }
            }
            .frame(width: size, height: size)
            Text(achievement.title)
                .font(.dewy(12, .bold))
                .foregroundStyle(isUnlocked ? theme.ink : theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
            DreamyBackground()
            VStack(spacing: 14) {
                BadgeView(achievement: achievement, isUnlocked: isUnlocked, size: 110)
                    .scaleEffect(pop ? 1 : 0.6)
                    .rotationEffect(.degrees(pop ? 0 : -15))
                Text(isUnlocked ? "Unlocked ✨" : "Keep sipping to unlock")
                    .font(.dewy(14, .bold))
                    .foregroundStyle(isUnlocked ? theme.accent : theme.inkSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((isUnlocked ? theme.accent : theme.inkSoft).opacity(0.12), in: Capsule())
                Text(achievement.detail)
                    .font(.dewy(17, .semibold))
                    .foregroundStyle(theme.ink)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { pop = true }
            if isUnlocked { Haptics.success() }
        }
    }
}
