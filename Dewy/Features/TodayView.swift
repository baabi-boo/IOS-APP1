import SwiftUI

struct TodayView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme

    @State private var showPaywall = false
    @State private var showShare = false
    @State private var bounce = 0
    @State private var ripple = 0
    @State private var celebrate = 0
    @State private var toast: DrinkEntry?
    @State private var toastTask: Task<Void, Never>?
    @State private var appeared = false
    @State private var showGoalBanner = false

    private let quickKinds: [DrinkKind] = [.water, .tea, .coffee, .juice, .sparkling, .matcha, .lemonade, .smoothie]

    // Fixed hero metrics keep Dewy's lily pad lined up with the horizon of the scene.
    private let headerHeight: CGFloat = 72
    private let stageHeight: CGFloat = 250
    private let amountHeight: CGFloat = 132
    private let mascotSize: CGFloat = 200
    /// The scene runs 60 points under the sheet so its rounded corners show sky, not canvas.
    private var sceneHeight: CGFloat { headerHeight + stageHeight + amountHeight + 94 }
    /// The sea starts behind Dewy's lower half, so the lily pad floats on it.
    private var horizonY: CGFloat { headerHeight + 154 }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    sheet
                        .floatIn(appeared, index: 3)
                }
            }
            .scrollIndicators(.hidden)

            ConfettiView(trigger: celebrate)
                .ignoresSafeArea()

            if showGoalBanner {
                GoalBanner(goal: store.format(store.goal), streak: store.currentStreak)
                    .padding(.horizontal, 24)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(entry: toast, label: store.format(toast.amount)) {
                    undo(toast)
                }
                .padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShare) {
            ShareDaySheet()
        }
        .task(id: router.queuedDrink) {
            guard let queued = router.queuedDrink else { return }
            // Give the drink sheet a moment to slide away so the pour is visible.
            try? await Task.sleep(for: .seconds(0.45))
            router.queuedDrink = nil
            add(queued.kind, amount: queued.amount)
        }
        .onAppear {
            appeared = true
            if LaunchOptions.screenshot == "share" {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.8))
                    showShare = true
                }
            }
            if LaunchOptions.screenshot == "paywall" {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.8))
                    showPaywall = true
                }
            }
            if LaunchOptions.screenshot == "celebrate" {
                // Demo recording: two drinks, the second one reaches the goal.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2.5))
                    add(.sparkling, amount: 500)
                    try? await Task.sleep(for: .seconds(3))
                    add(.water, amount: 500)
                }
            }
        }
    }

    // MARK: Hero

    private var greeting: String {
        let hour = LaunchOptions.isDemo ? 14 : Calendar.current.component(.hour, from: .now)
        let name = store.profile.name.isEmpty ? "" : ", \(store.profile.name)"
        switch hour {
        case 5..<12: return "Morning\(name)"
        case 12..<17: return "Hi\(name)"
        case 17..<22: return "Evening\(name)"
        default: return "Hey night owl"
        }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            header
                .frame(height: headerHeight)
                .padding(.horizontal, 22)
                .floatIn(appeared, index: 0)
            stage
                .frame(height: stageHeight)
                .floatIn(appeared, index: 1)
            amount
                .frame(height: amountHeight, alignment: .top)
                .floatIn(appeared, index: 2)
        }
        .padding(.top, 4)
        .padding(.bottom, 30)
        .background(alignment: .top) {
            // The sea starts behind Dewy's lower half, so the lily pad floats on it.
            SkyHeaderBackground(height: sceneHeight, horizon: horizonY, sunY: 150, sunX: 0.16, drawsHorizonClouds: true)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()), color: theme.onHeroSoft, size: 12)
                Text(greeting)
                    .font(.display(31))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            CircleIconButton(systemImage: "square.and.arrow.up", size: 42, onHero: true) {
                Haptics.tap()
                showShare = true
            }
            .accessibilityLabel("Share your day")
            StreakPill(days: store.currentStreak)
        }
    }

    private var stage: some View {
        ZStack(alignment: .top) {
            // Dewy's feet rest at 93% of the figure's height, right on the pad.
            let mascotHeight = mascotSize * DewyGeometry.canvas.height / DewyGeometry.canvas.width
            LilyPad(width: 150, rippleTrigger: ripple)
                .offset(y: mascotHeight * 0.935 - 31.5)
            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: mascotSize,
                bounceTrigger: bounce,
                bands: store.todayBands
            )
            .contentShape(Rectangle())
            .onTapGesture {
                bounce += 1
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            SpeechBubble(text: store.mood.line())
                .padding(.trailing, 18)
                .padding(.top, 4)
        }
    }

    private var amount: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(store.format(store.todayTotal, withUnit: false))
                    .font(.display(68))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: store.displayValue(store.todayTotal)))
                Text(store.profile.unit.label)
                    .font(.display(24))
                    .foregroundStyle(theme.onHeroSoft)
            }
            .shadow(color: theme.sea[1].opacity(0.45), radius: 0, x: 0, y: 3)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.todayTotal)

            HStack(spacing: 8) {
                Text("\(Int((store.todayProgress * 100).rounded()))%")
                    .font(.display(16))
                    .foregroundStyle(theme.isDark ? Palette.ink : theme.accent)
                    .contentTransition(.numericText())
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Color.white, in: Capsule())
                Text("of your \(store.format(store.goal)) goal")
                    .font(.display(17, .medium))
                    .foregroundStyle(.white)
            }
            .animation(.spring, value: store.todayTotal)

            DrinkStripe(bands: store.todayBands)
                .frame(width: 236, height: 12)
                .padding(.top, 6)
        }
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 26) {
            quickAdd
            summary
            logSection
            tipCard
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .canvasSheet()
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Quick sips", trailing: "All drinks") {
                Haptics.tap()
                router.showAddDrink = true
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(quickKinds) { kind in
                        let locked = kind.isPremium && !purchases.isPremium
                        QuickDrinkTile(kind: kind, amount: store.format(kind.defaultAmount), isLocked: locked) {
                            if locked {
                                Haptics.warning()
                                showPaywall = true
                            } else {
                                add(kind, amount: kind.defaultAmount)
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

    private var summary: some View {
        HStack(spacing: 10) {
            SummaryTile(
                symbol: "drop.fill",
                tint: theme.water,
                value: store.todayRemaining > 0 ? store.format(store.todayRemaining) : "Done!",
                label: store.todayRemaining > 0 ? "to go" : "goal met"
            )
            SummaryTile(
                symbol: "bolt.fill",
                tint: Color(hex: 0xB07CF0),
                value: "\(Int(store.todayCaffeine.rounded())) mg",
                label: "caffeine",
                progress: store.todayCaffeine / max(store.profile.caffeineLimit, 1)
            )
            SummaryTile(
                symbol: "cube.fill",
                tint: Color(hex: 0xFF8FB1),
                value: "\(Int(store.todaySugar.rounded())) g",
                label: "sugar",
                progress: store.todaySugar / 50
            )
        }
        .padding(.horizontal, 20)
    }

    private var logSection: some View {
        let entries = Array(store.todayEntries.prefix(8))
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's sips", trailing: entries.isEmpty ? nil : "\(store.todayEntries.count) drinks")

            if entries.isEmpty {
                HStack(spacing: 14) {
                    MascotView(progress: 0, mood: .thirsty, size: 56, backdrop: .light, animated: false, showsShadow: false)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No sips yet")
                            .font(.display(18))
                            .foregroundStyle(theme.ink)
                        Text("Tap a drink above and watch Dewy fill up!")
                            .font(.dewy(14, .semibold))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
                .dewyCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        EntryRow(entry: entry, amount: store.format(entry.amount), effective: store.format(entry.effective))
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation(.spring) { store.delete(entry) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(theme.line)
                                .frame(height: 1.5)
                                .padding(.leading, 62)
                        }
                    }
                }
                .dewyCard(padding: 14)
            }
        }
        .padding(.horizontal, 20)
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Palette.sunshine)
                .frame(width: 46, height: 46)
                .background(Palette.ink, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                CapsLabel(text: "Daily dew tip", color: Palette.ink.opacity(0.55), size: 11)
                Text(HydrationTips.tip())
                    .font(.display(17, .medium))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: 0xFFD45C))
                .overlay(alignment: .bottomTrailing) {
                    DewyShape()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 70, height: 88)
                        .rotationEffect(.degrees(-14))
                        .offset(x: 14, y: 26)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(hex: 0xF2B52E))
                        .offset(y: 5)
                }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Actions

    private func add(_ kind: DrinkKind, amount: Double) {
        let wasBelowGoal = store.todayProgress < 1
        var entry: DrinkEntry?
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            entry = store.add(kind, amount: amount)
        }
        bounce += 1
        ripple += 1
        Haptics.splash()
        SoundFX.play(.pour)
        if wasBelowGoal && store.todayProgress >= 1 {
            celebrate += 1
            Haptics.success()
            SoundFX.play(.goal, volume: 0.6)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { showGoalBanner = true }
                try? await Task.sleep(for: .seconds(3.2))
                withAnimation(.easeInOut(duration: 0.35)) { showGoalBanner = false }
            }
        }
        guard let entry else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            toast = entry
        }
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { toast = nil }
        }
    }

    private func undo(_ entry: DrinkEntry) {
        toastTask?.cancel()
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            store.delete(entry)
            toast = nil
        }
    }
}

// MARK: - Pieces

/// The moment you reach your goal: Dewy celebrates and a new flower is planted.
struct GoalBanner: View {
    @Environment(\.dewyTheme) private var theme
    var goal: String
    var streak: Int

    var body: some View {
        VStack(spacing: 6) {
            MascotView(progress: 1.1, mood: .ecstatic, size: 120, accessory: .sparkles, showsShadow: false)
            Text("Goal smashed!")
                .font(.display(32))
                .foregroundStyle(theme.ink)
            Text("You drank your \(goal) today.")
                .font(.dewy(15, .bold))
                .foregroundStyle(theme.inkSoft)
            HStack(spacing: 8) {
                bannerPill(symbol: "camera.macro", text: "+1 flower", tint: Palette.berry)
                bannerPill(symbol: "flame.fill", text: "\(streak) day streak", tint: Color(hex: 0xFF7A3D))
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 26)
        .background {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(theme.card)
                .shadow(color: Color.black.opacity(0.22), radius: 30, x: 0, y: 16)
        }
        .accessibilityElement(children: .combine)
    }

    private func bannerPill(symbol: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 12, weight: .heavy))
            Text(text).font(.display(15))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(tint.opacity(0.13), in: Capsule())
    }
}

/// A drink tile in the quick-add row: one tap logs the drink's usual serving.
struct QuickDrinkTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var amount: String
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                DrinkIcon(kind: kind, size: 58)
                Text(kind.name)
                    .font(.display(14))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(amount)
                    .font(.dewy(12, .bold))
                    .foregroundStyle(Palette.ink.opacity(0.5))
            }
            .frame(width: 84, height: 108)
            .overlay(alignment: .topTrailing) {
                Image(systemName: isLocked ? "lock.fill" : "plus")
                    .font(.system(size: isLocked ? 9 : 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 21, height: 21)
                    .background(isLocked ? Palette.ink.opacity(0.75) : kind.color, in: Circle())
                    .padding(7)
            }
            .opacity(isLocked ? 0.82 : 1)
        }
        .buttonStyle(CandyButtonStyle(fill: kind.light, lip: kind.color.opacity(0.32), shape: AnyShape(RoundedRectangle(cornerRadius: 24, style: .continuous)), depth: 4))
        .accessibilityLabel(isLocked ? "\(kind.name), Dewy+ only" : "Add \(amount) of \(kind.name)")
    }
}

/// A small stat card in the summary row.
struct SummaryTile: View {
    @Environment(\.dewyTheme) private var theme
    var symbol: String
    var tint: Color
    var value: String
    var label: String
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            IconTile(systemImage: symbol, color: tint, size: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.display(18))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.dewy(12, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            if let progress {
                ProgressCapsule(progress: progress, tint: tint)
                    .frame(height: 6)
            } else {
                Spacer().frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dewyCard(padding: 14, radius: 22)
    }
}

/// A slim capsule striped with today's drink colors.
struct DrinkStripe: View {
    var bands: [LiquidBand]
    var track: Color = Color.white.opacity(0.3)

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let total = max(bands.last?.upTo ?? 0, 1)
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                HStack(spacing: 2) {
                    ForEach(Array(bands.enumerated()), id: \.offset) { index, band in
                        let previous = index == 0 ? 0 : bands[index - 1].upTo
                        Rectangle()
                            .fill(band.color)
                            .frame(width: max(2, width * CGFloat((band.upTo - previous) / total) - 2))
                    }
                }
                .clipShape(Capsule())
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: bands.count)
    }
}

/// The streak counter: a little flame on a white pill.
struct StreakPill: View {
    var days: Int

    var body: some View {
        HStack(spacing: 5) {
            FlameGlyph()
                .frame(width: 20, height: 24)
            Text("\(days)")
                .font(.display(20))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText(value: Double(days)))
        }
        .padding(.leading, 11)
        .padding(.trailing, 14)
        .frame(height: 42)
        .background(Color.white, in: Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) day streak")
    }
}

/// Dewy's illustrated flame, used for streaks.
struct FlameGlyph: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x / 22 * w, y: y / 24 * h) }
            var outer = Path()
            outer.move(to: p(11, 1))
            outer.addCurve(to: p(20, 15.5), control1: p(14, 6), control2: p(20, 9))
            outer.addCurve(to: p(2, 15.5), control1: p(20, 26), control2: p(2, 26))
            outer.addCurve(to: p(6.5, 6), control1: p(2, 11), control2: p(5, 9))
            outer.addCurve(to: p(10, 9), control1: p(8, 8.5), control2: p(9, 9))
            outer.addCurve(to: p(11, 1), control1: p(10, 6), control2: p(10, 3.5))
            outer.closeSubpath()
            context.fill(outer, with: .linearGradient(Gradient(colors: [Color(hex: 0xFF9F43), Color(hex: 0xFF5A3D)]), startPoint: p(11, 1), endPoint: p(11, 24)))
            var inner = Path()
            inner.move(to: p(11, 10))
            inner.addCurve(to: p(16, 17.5), control1: p(13, 13), control2: p(16, 14.5))
            inner.addCurve(to: p(6, 17.5), control1: p(16, 23.5), control2: p(6, 23.5))
            inner.addCurve(to: p(11, 10), control1: p(6, 15), control2: p(8, 13.5))
            inner.closeSubpath()
            context.fill(inner, with: .color(Color(hex: 0xFFD23F)))
        }
    }
}

struct SpeechBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.display(15, .medium))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 116)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .overlay(alignment: .bottomLeading) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .offset(x: 4, y: 9)
                    }
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
            }
            .rotationEffect(.degrees(4))
            .id(text)
            .transition(.scale.combined(with: .opacity))
    }
}

struct ProgressCapsule: View {
    @Environment(\.dewyTheme) private var theme
    var progress: Double
    var tint: Color?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.well)
                Capsule()
                    .fill(tint ?? theme.accent)
                    .frame(width: max(proxy.size.height, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
    }
}

struct EntryRow: View {
    @Environment(\.dewyTheme) private var theme
    var entry: DrinkEntry
    var amount: String
    var effective: String

    private var detail: String {
        if entry.caffeine >= 1 {
            return "\(entry.date.formatted(date: .omitted, time: .shortened)) · \(Int(entry.caffeine.rounded())) mg caffeine"
        }
        if entry.kind.hydration < 1 {
            return "\(entry.date.formatted(date: .omitted, time: .shortened)) · counts \(effective)"
        }
        return entry.date.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            DrinkBadge(kind: entry.kind, size: 48)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.kind.name)
                    .font(.display(17))
                    .foregroundStyle(theme.ink)
                Text(detail)
                    .font(.dewy(12.5, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text("+\(amount)")
                .font(.display(17))
                .foregroundStyle(theme.isDark ? entry.kind.color : entry.kind.deep)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct ToastView: View {
    @Environment(\.dewyTheme) private var theme
    var entry: DrinkEntry
    var label: String
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            DrinkIcon(kind: entry.kind, size: 30)
            Text("Added \(label) \(entry.kind.name.lowercased())")
                .font(.display(16, .medium))
                .foregroundStyle(Palette.ink)
            Button(action: onUndo) {
                Text("Undo")
                    .font(.display(15))
                    .foregroundStyle(theme.isDark ? Color(hex: 0x5B4BE0) : theme.accent)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(theme.isDark ? Color(hex: 0xEEE8FF) : theme.accentSoft, in: Capsule())
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: 50)
        .background(Color.white, in: Capsule())
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
    }
}
