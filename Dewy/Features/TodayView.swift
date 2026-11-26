import SwiftUI

/// Frames measured for the pour-in animation. A plain reference so scrolling never re-renders the screen.
private final class PourGeometry {
    var tiles: [DrinkKind: CGRect] = [:]
    var dewy: CGRect = .zero
    var screen: CGRect = .zero
}

/// A drink pouring from its tile into Dewy.
private struct Flight: Identifiable, Equatable {
    let id = UUID()
    var kind: DrinkKind
    var amount: Double
    var from: CGPoint
    var to: CGPoint
}

/// A "+N drops" badge that floats up after a sip lands.
private struct DropPop: Identifiable, Equatable {
    let id = UUID()
    var value: Int
}

struct TodayView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showShare = false
    @State private var bounce = 0
    @State private var ripple = 0
    @State private var splash = 0
    @State private var companionCheer = 0
    @State private var lastPouredColor: Color = Palette.aqua
    @State private var celebrate = 0
    @State private var showCelebration = false
    @State private var celebrationReward = 0
    @State private var toast: DrinkEntry?
    @State private var toastTask: Task<Void, Never>?
    @State private var appeared = false
    @State private var flights: [Flight] = []
    @State private var pops: [DropPop] = []
    @State private var geometry = PourGeometry()

    private let quickKinds: [DrinkKind] = [.water, .tea, .coffee, .juice, .sparkling, .matcha, .lemonade, .smoothie]

    // Balanced hero metrics keep the header, whisper caption, Dewy, companions and readout collision-free.
    private let headerHeight: CGFloat = 118
    private let stageHeight: CGFloat = 264
    private let mascotTop: CGFloat = 38
    private let mascotSize: CGFloat = 184
    private let padWidth: CGFloat = 158
    private var mascotHeight: CGFloat { mascotSize * DewyGeometry.canvas.height / DewyGeometry.canvas.width }
    /// Top of the lily pad canvas inside the stage so Dewy's feet land cleanly on the pad.
    private var padTop: CGFloat { mascotTop + mascotHeight * 0.925 - padWidth * 0.232 }
    /// The pond shore begins behind Dewy's lower silhouette.
    private var horizonY: CGFloat { headerHeight + 138 }

    private var phase: SkyPhase { theme.phase() }

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

            // Gouache liquid streams pouring from tapped drink tiles into Dewy.
            ForEach(flights) { flight in
                GouachePourStream(
                    from: flight.from,
                    to: flight.to,
                    color: flight.kind.color,
                    kind: flight.kind
                ) {
                    land(flight)
                }
            }
            .allowsHitTesting(false)

            ConfettiView(trigger: celebrate, origin: UnitPoint(x: 0.5, y: 0.3))
                .ignoresSafeArea()

            if showCelebration {
                CelebrationOverlay(
                    reward: celebrationReward,
                    streak: store.currentStreak,
                    goal: store.format(store.goal),
                    outfits: store.outfits,
                    bands: store.todayBands
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { showCelebration = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                .zIndex(3)
            }
        }
        .coordinateSpace(name: "today")
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { geometry.screen = proxy.frame(in: .named("today")) }
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                UndoToast(entry: toast, label: store.format(toast.amount)) {
                    undo(toast)
                }
                .padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.92)))
            }
        }
        .sheet(isPresented: $showShare) {
            ShareDaySheet()
                .preferredColorScheme(.light)
        }
        .task(id: router.queuedDrink) {
            guard let queued = router.queuedDrink else { return }
            // Give the drink sheet a moment to dismiss so the pour stream is visible.
            try? await Task.sleep(for: .seconds(0.4))
            router.queuedDrink = nil
            let start = CGPoint(x: geometry.screen.midX, y: geometry.screen.maxY - 40)
            pour(queued.kind, amount: queued.amount, from: start)
        }
        .onAppear {
            appeared = true
            runDemoHooks()
        }
    }

    // MARK: Hero

    private var greeting: String {
        let name = store.profile.name.isEmpty ? "" : ", \(store.profile.name)"
        return phase.greeting + name
    }

    private var hero: some View {
        VStack(spacing: 0) {
            header
                .frame(height: headerHeight, alignment: .top)
                .padding(.horizontal, 20)
                .floatIn(appeared, index: 0)

            stage
                .frame(height: stageHeight, alignment: .top)
                .floatIn(appeared, index: 1)

            amountReadout
                .padding(.top, 10)
                .padding(.bottom, 30)
                .floatIn(appeared, index: 2)
        }
        .padding(.top, 4)
        .background(alignment: .top) {
            GeometryReader { proxy in
                let bgHeight = proxy.size.height + 68
                VStack(spacing: 0) {
                    theme.sky[0]
                        .frame(height: 600)
                    ClayWorld(
                        horizon: horizonY,
                        decor: store.placedDecor,
                        interactive: true,
                        headerSafeTop: 168,
                        floatingDecorY: horizonY + 182
                    )
                    .frame(width: proxy.size.width, height: bgHeight)
                }
                .frame(width: proxy.size.width, height: bgHeight, alignment: .bottom)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    CapsLabel(
                        text: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                        color: theme.onHeroSoft,
                        size: 11
                    )
                    Text(greeting)
                        .font(.display(30, .semibold))
                        .tracking(-0.4)
                        .foregroundStyle(theme.onHero)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 8)
                avatarButton
            }
            HStack(spacing: 8) {
                Button {
                    Haptics.tap()
                    router.tab = .friends
                } label: {
                    CountPill(glyph: .drop, value: store.dropBalance, tint: Palette.coral)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel("\(store.dropBalance) Dew Drops")

                CountPill(glyph: .flame, value: store.currentStreak, tint: Palette.butter)
                    .accessibilityLabel("\(store.currentStreak) day streak")

                Spacer(minLength: 0)

                CircleIconButton(systemImage: "square.and.arrow.up", size: 36, onHero: true) {
                    Haptics.tap()
                    showShare = true
                }
                .accessibilityLabel("Share your day")
            }
        }
    }

    private var avatarButton: some View {
        Button {
            Haptics.tap()
            router.showMe = true
        } label: {
            MascotView(
                progress: store.todayProgress,
                mood: .happy,
                size: 38,
                outfits: store.outfits,
                bands: store.todayBands,
                backdrop: .light,
                animated: false,
                showsShadow: false
            )
            .offset(y: 2)
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .background {
                PaperSurface(shape: Circle(), fill: Palette.paper, tint: Palette.aqua, elevation: 0.5)
            }
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Me and settings")
    }

    private var stage: some View {
        ZStack(alignment: .top) {
            // Editorial mood caption tucked cleanly in open sky above Dewy's crown.
            MoodWhisperPill(text: store.mood.line(), isNight: phase.isNight)
                .padding(.top, 2)

            LilyPad(width: padWidth, rippleTrigger: ripple)
                .offset(y: padTop)

            companions

            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: mascotSize,
                bounceTrigger: bounce,
                sipTrigger: splash,
                outfits: store.outfits,
                bands: store.todayBands,
                isNight: phase.isNight
            )
            .liveMeniscusGlow(strength: 0.13)
            .background {
                GeometryReader { proxy in
                    let frame = proxy.frame(in: .named("today"))
                    Color.clear
                        .onAppear { geometry.dewy = frame }
                        .onChange(of: frame) { _, new in geometry.dewy = new }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                bounce += 1
                companionCheer += 1
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.3)
            }
            .padding(.top, mascotTop)

            WatercolorSplashBurst(trigger: splash, color: lastPouredColor)
                .frame(width: 260, height: 200)
                .offset(y: mascotTop + mascotHeight * 0.08)

            ForEach(pops) { pop in
                DropPopView(value: pop.value)
                    .offset(x: 72, y: mascotTop + 26)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Up to two live animated friends perched on miniature botanical lily pads beside Dewy.
    private var companions: some View {
        let friends = Array(store.companions.prefix(2))
        return ZStack(alignment: .top) {
            ForEach(Array(friends.enumerated()), id: \.element) { index, friend in
                CompanionPad(
                    friend: friend,
                    index: index,
                    cheerTrigger: companionCheer,
                    isNight: phase.isNight
                )
                .offset(x: index == 0 ? -122 : 122, y: padTop - 22)
            }
        }
    }

    private var amountReadout: some View {
        let usesLightPondInk = phase == .dusk || phase == .night
        let inkColor: Color = usesLightPondInk ? Ink.starlight : Ink.primary
        let subColor: Color = usesLightPondInk ? Ink.starlight.opacity(0.86) : Ink.primary.opacity(0.78)
        let shadowColor: Color = usesLightPondInk
            ? Color(hex: 0x1A1335).opacity(0.64)
            : Palette.paper.opacity(0.78)

        return VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(store.format(store.todayTotal, withUnit: false))
                    .font(.display(58, .bold))
                    .tracking(-1.0)
                    .monospacedDigit()
                    .foregroundStyle(inkColor)
                    .contentTransition(.numericText(value: store.displayValue(store.todayTotal)))
                Text(store.profile.unit.label)
                    .font(.display(22, .medium))
                    .foregroundStyle(subColor)
            }
            .shadow(color: shadowColor, radius: usesLightPondInk ? 8 : 10, x: 0, y: usesLightPondInk ? 2 : 0)
            .shadow(color: shadowColor.opacity(0.65), radius: 2, x: 0, y: 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.todayTotal)

            Text("of your \(store.format(store.goal)) daily goal")
                .font(.editorialItalic(14.5))
                .foregroundStyle(subColor)
                .shadow(color: shadowColor, radius: 6, x: 0, y: 1)

            ClayProgressBar(progress: store.todayProgress, isNight: usesLightPondInk)
                .frame(width: 214, height: 26)
                .padding(.top, 5)
        }
        .frame(maxWidth: 236)
        .background {
            if !usesLightPondInk {
                Ellipse()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Palette.paper.opacity(0.46), location: 0.0),
                                .init(color: Palette.paper.opacity(0.22), location: 0.52),
                                .init(color: Palette.paper.opacity(0.0), location: 1.0)
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 122
                        )
                    )
                    .frame(width: 248, height: 118)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 26) {
            quickAdd
            adventureCard
            summary
            logSection
            tipCard
        }
        .padding(.top, 24)
        .padding(.bottom, 128)
        .frame(maxWidth: .infinity)
        .canvasSheet()
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick sips", trailing: "All drinks") {
                Haptics.tap()
                router.showAddDrink = true
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(quickKinds) { kind in
                        let locked = kind.isPremium && !purchases.isPremium
                        QuickSipTile(kind: kind, amount: store.format(kind.defaultAmount), isLocked: locked) {
                            if locked {
                                Haptics.warning()
                                router.showPaywall = true
                            } else {
                                let frame = geometry.tiles[kind] ?? .zero
                                pour(kind, amount: kind.defaultAmount, from: CGPoint(x: frame.midX, y: frame.midY - 10))
                            }
                        }
                        .background {
                            GeometryReader { proxy in
                                let frame = proxy.frame(in: .named("today"))
                                Color.clear
                                    .onAppear { geometry.tiles[kind] = frame }
                                    .onChange(of: frame) { _, new in geometry.tiles[kind] = new }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private var adventureCard: some View {
        let chapter = store.todayChapter
        let unlocked = store.beatsUnlocked
        let line = unlocked == 0 ? "Take your first sip to set off." : chapter.beats[min(unlocked, 4) - 1]
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { router.tab = .journey }
        } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .bottom) {
                    JourneySceneView(chapter: chapter, animated: false)
                    MascotView(
                        progress: store.todayProgress,
                        mood: store.mood,
                        size: 32,
                        outfits: store.outfits,
                        bands: store.todayBands,
                        animated: false,
                        showsShadow: false,
                        isNight: chapter == .grove || chapter == .lake
                    )
                    .offset(y: -8)
                }
                .frame(width: 90, height: 102)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Ink.hairlineStrong, lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        ClayIcon(glyph: .map, size: 16)
                        CapsLabel(text: "Today's adventure", color: theme.inkSoft, size: 10)
                    }
                    Text(chapter.title)
                        .font(.display(20, .semibold))
                        .foregroundStyle(theme.ink)
                    Text(line)
                        .font(.editorialItalic(13.5))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(index < unlocked ? Palette.aqua : theme.well)
                                .overlay {
                                    Capsule().stroke(index < unlocked ? Palette.aquaDeep.opacity(0.3) : Ink.hairline, lineWidth: 0.75)
                                }
                                .frame(height: 7)
                        }
                        Text("\(unlocked)/4")
                            .font(.dewy(12, .bold))
                            .monospacedDigit()
                            .foregroundStyle(theme.inkSoft)
                            .padding(.leading, 2)
                    }
                    .animation(.spring(response: 0.48, dampingFraction: 0.76), value: unlocked)
                }
                Spacer(minLength: 0)
            }
            .dewyCard(padding: 13, glow: chapter.tint)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
        .padding(.horizontal, 20)
    }

    private var summary: some View {
        HStack(spacing: 10) {
            StatTile(
                glyph: .drop,
                tint: Palette.aqua,
                value: store.todayRemaining > 0 ? store.format(store.todayRemaining) : "Done!",
                label: store.todayRemaining > 0 ? "to go" : "goal met",
                usesWaterIcon: true
            )
            StatTile(
                glyph: .cup,
                tint: Palette.lilac,
                value: "\(Int(store.todayCaffeine.rounded())) mg",
                label: "caffeine",
                progress: store.todayCaffeine / max(store.profile.caffeineLimit, 1)
            )
            StatTile(
                glyph: .drop,
                tint: Palette.coral,
                value: "+\(store.todayDrops)",
                label: "drops today"
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
                    MascotView(progress: 0, mood: .thirsty, size: 54, backdrop: .light, animated: false, showsShadow: false)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No sips yet")
                            .font(.display(18, .semibold))
                            .foregroundStyle(theme.ink)
                        Text("Tap a drink above and watch Dewy fill up.")
                            .font(.editorialItalic(14))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
                .dewyCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        SipRow(entry: entry, amount: store.format(entry.amount), effective: store.format(entry.effective))
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation(.spring) { store.delete(entry) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity.combined(with: .scale(scale: 0.92))
                            ))
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(theme.line)
                                .frame(height: 1)
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
            ClayIcon(glyph: .star, size: 38)
                .frame(width: 48, height: 48)
                .background(Palette.paper.opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.butterDeep.opacity(0.22), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 4) {
                CapsLabel(text: "Field note", color: Palette.butterDeep, size: 10.5)
                Text(HydrationTips.tip())
                    .font(.editorialItalic(16))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dewyCard(padding: 16, fill: Palette.butterSoft, glow: Palette.butter)
        .padding(.horizontal, 20)
    }

    // MARK: Actions

    /// Streams the drink into Dewy; it's logged upon splashdown.
    private func pour(_ kind: DrinkKind, amount: Double, from start: CGPoint) {
        Haptics.tap()
        let dewy = geometry.dewy
        let target = CGPoint(x: dewy.midX, y: dewy.minY + dewy.height * 0.42)
        guard start != .zero, dewy != .zero, !LaunchOptions.freezesMotion else {
            add(kind, amount: amount)
            return
        }
        flights.append(Flight(kind: kind, amount: amount, from: start, to: target))
    }

    private func land(_ flight: Flight) {
        add(flight.kind, amount: flight.amount)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.22))
            flights.removeAll { $0.id == flight.id }
        }
    }

    private func add(_ kind: DrinkKind, amount: Double) {
        let wasBelowGoal = store.todayProgress < 1
        let dropsBefore = store.todayDrops
        let instant = LaunchOptions.freezesMotion || reduceMotion

        // t = 0.00s: liquid pours in, Dewy gulps & fizzes, watercolor splash bursts.
        lastPouredColor = kind.color
        var entry: DrinkEntry?
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            entry = store.add(kind, amount: amount)
        }
        splash += 1
        Haptics.splash()
        SoundFX.play(.pour)

        let gained = store.todayDrops - dropsBefore
        if instant {
            bounce += 1
            ripple += 1
            companionCheer += 1
            emitDropPop(gained)
        } else {
            // Organic Pixar follow-through: recoil+ripple -> companion cheer -> +drops pop.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(40))
                bounce += 1
                ripple += 1
                try? await Task.sleep(for: .milliseconds(80))
                companionCheer += 1
                try? await Task.sleep(for: .milliseconds(60))
                emitDropPop(gained)
            }
        }

        if wasBelowGoal && store.todayProgress >= 1 {
            celebrationReward = store.goalReward + min(store.currentStreak, DropRules.streakCap)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.6))
                celebrate += 1
                Haptics.success()
                SoundFX.play(.goal, volume: 0.6)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { showCelebration = true }
                if LaunchOptions.isDemo {
                    try? await Task.sleep(for: .seconds(5.5))
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { showCelebration = false }
                }
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

    private func emitDropPop(_ gained: Int) {
        guard gained > 0 else { return }
        let pop = DropPop(value: gained)
        pops.append(pop)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            pops.removeAll { $0.id == pop.id }
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

    private func runDemoHooks() {
        switch LaunchOptions.screenshot {
        case "share":
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                showShare = true
            }
        case "celebrate":
            // Demo recording: two visible drinks pour in, the second reaching the goal.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.5))
                let first = geometry.tiles[.tea] ?? geometry.tiles[.water] ?? .zero
                pour(.tea, amount: 500, from: CGPoint(x: first.midX, y: first.midY))
                try? await Task.sleep(for: .seconds(3))
                let second = geometry.tiles[.water] ?? .zero
                pour(.water, amount: 550, from: CGPoint(x: second.midX, y: second.midY))
            }
        default:
            break
        }
    }
}

// MARK: - Drop Pop & Mood Whisper

private struct MoodWhisperPill: View {
    var text: String
    var isNight: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isNight ? Color(hex: 0xF5D57A) : Palette.aqua)
                .frame(width: 5, height: 5)
            Text(text)
                .font(.editorialItalic(13.5))
                .foregroundStyle(isNight ? Ink.starlight : Ink.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .frame(height: 28)
        .background {
            Capsule()
                .fill(isNight ? Color(hex: 0x1D2550).opacity(0.72) : Palette.paper.opacity(0.84))
                .overlay {
                    Capsule().stroke(
                        isNight ? Ink.starlight.opacity(0.22) : Ink.hairline,
                        lineWidth: 1
                    )
                }
        }
        .shadow(color: Palette.shadow.opacity(isNight ? 0.18 : 0.07), radius: 6, x: 0, y: 2)
        .id(text)
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }
}

private struct DropPopView: View {
    var value: Int
    @State private var risen = false

    var body: some View {
        HStack(spacing: 4) {
            ClayIcon(glyph: .drop, size: 18)
            Text("+\(value)")
                .font(.dewy(15, .bold))
                .monospacedDigit()
                .foregroundStyle(Palette.coralDeep)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background {
            PaperSurface(shape: Capsule(), fill: Palette.paper, tint: Palette.coral, elevation: 0.5)
        }
        .offset(y: risen ? -46 : 0)
        .opacity(risen ? 0 : 1)
        .scaleEffect(risen ? 1 : 0.65)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { risen = false }
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) { risen = true }
        }
    }
}

// MARK: - Celebration

/// Full-screen storybook celebration when the daily hydration goal is reached.
private struct CelebrationOverlay: View {
    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var reward: Int
    var streak: Int
    var goal: String
    var outfits: [Outfit]
    var bands: [LiquidBand]
    var onDone: () -> Void

    @State private var jump = 0
    @State private var shown = false

    private var raysLive: Bool { !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Palette.cream.opacity(0.78))
                .ignoresSafeArea()
                .onTapGesture(perform: onDone)

            BubbleField(count: 14)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ZStack {
                    CelebrationSunRays(animated: raysLive)
                        .frame(width: 340, height: 340)
                        .scaleEffect(shown ? 1 : 0.55)
                        .opacity(shown ? 1 : 0)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Palette.butter.opacity(0.36), Palette.butter.opacity(0)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                        .scaleEffect(shown ? 1 : 0.45)

                    MascotView(
                        progress: 1.05,
                        mood: .ecstatic,
                        size: 196,
                        bounceTrigger: jump,
                        outfits: outfits,
                        sparkles: true,
                        bands: bands,
                        showsShadow: false
                    )
                    .liveMeniscusGlow(strength: 0.16)
                    .keyframeAnimator(initialValue: CelebrationJump(), trigger: jump) { view, value in
                        view
                            .rotation3DEffect(.degrees(value.spin), axis: (x: 0, y: 1, z: 0))
                            .offset(y: value.lift)
                    } keyframes: { _ in
                        KeyframeTrack(\.lift) {
                            CubicKeyframe(14, duration: 0.14)
                            SpringKeyframe(-86, duration: 0.36)
                            SpringKeyframe(0, duration: 0.6, spring: .bouncy)
                        }
                        KeyframeTrack(\.spin) {
                            LinearKeyframe(0, duration: 0.16)
                            CubicKeyframe(360, duration: 0.6)
                            LinearKeyframe(360, duration: 0.3)
                        }
                    }
                }
                .frame(height: 250)

                HStack(spacing: 6) {
                    StarletShape()
                        .fill(Palette.butterDeep)
                        .frame(width: 9, height: 9)
                    CapsLabel(text: "Daily goal met", color: Palette.butterDeep, size: 10.5)
                    StarletShape()
                        .fill(Palette.butterDeep)
                        .frame(width: 9, height: 9)
                }
                .padding(.horizontal, 13)
                .frame(height: 26)
                .background {
                    PaperSurface(shape: Capsule(), fill: Palette.butterSoft, tint: Palette.butter, elevation: 0.35)
                }

                Text("Goal reached!")
                    .font(.display(36, .bold))
                    .foregroundStyle(theme.ink)
                Text("You drank your \(goal) today.\nDewy is overflowing with joy.")
                    .font(.editorialItalic(16.5))
                    .foregroundStyle(theme.inkSoft)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        ClayIcon(glyph: .drop, size: 30)
                        RollingNumber(value: reward, font: .display(28, .bold), color: Palette.coralDeep, delay: 0.7)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background { PaperSurface(shape: Capsule(), fill: Palette.paper, tint: Palette.coral) }

                    HStack(spacing: 6) {
                        ClayIcon(glyph: .flame, size: 28)
                        Text("\(streak)")
                            .font(.display(26, .bold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.butterDeep)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background { PaperSurface(shape: Capsule(), fill: Palette.paper, tint: Palette.butter) }
                }
                .padding(.top, 6)

                PrimaryButton(title: "Yay, Dewy!", style: .reward, action: onDone)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .scaleEffect(shown ? 1 : 0.88)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.74)) { shown = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.35))
                jump += 1
                try? await Task.sleep(for: .seconds(1.6))
                jump += 1
            }
        }
    }
}

private struct CelebrationJump {
    var lift: CGFloat = 0
    var spin: Double = 0
}

/// Slowly rotating translucent golden botanical sun-rays radiating softly behind celebrating Dewy.
private struct CelebrationSunRays: View {
    var animated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            let angle = animated ? timeline.date.timeIntervalSinceReferenceDate * 0.14 : 0.22
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let radius = min(size.width, size.height) * 0.5
                let rays = 12
                let halfSpread = 0.085
                let grad = Gradient(stops: [
                    .init(color: Palette.butter.opacity(0.30), location: 0.12),
                    .init(color: Palette.butterSoft.opacity(0.18), location: 0.62),
                    .init(color: Palette.butter.opacity(0.0), location: 1.0)
                ])

                for index in 0..<rays {
                    let theta = angle + Double(index) * (Double.pi * 2.0 / Double(rays))
                    let innerR = radius * 0.18
                    let a1 = theta - halfSpread
                    let a2 = theta + halfSpread
                    var ray = Path()
                    ray.move(to: CGPoint(x: center.x + CGFloat(cos(theta)) * innerR, y: center.y + CGFloat(sin(theta)) * innerR))
                    ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(a1)) * radius, y: center.y + CGFloat(sin(a1)) * radius))
                    ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(a2)) * radius, y: center.y + CGFloat(sin(a2)) * radius))
                    ray.closeSubpath()
                    context.fill(ray, with: .radialGradient(grad, center: center, startRadius: innerR, endRadius: radius))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Pieces

/// A live animated pond companion resting on a miniature handcrafted botanical lily pad.
private struct CompanionPad: View {
    var friend: Friend
    var index: Int
    var cheerTrigger: Int
    var isNight: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LilyPad(width: 78, rippleTrigger: cheerTrigger)
                .offset(y: 12)
            FriendView(
                friend: friend,
                size: 72,
                animated: true,
                celebrateTrigger: cheerTrigger,
                isNight: isNight,
                phaseOffset: Double(index) * 1.9
            )
            .scaleEffect(x: index == 0 ? 1 : -1, y: 1)
            .offset(y: -4)
        }
        .frame(width: 96, height: 84, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Matte watercolor-ink hydration progress bar with crisp hairline track and percentage pill.
struct ClayProgressBar: View {
    var progress: Double
    var tint: Color = Palette.aqua
    var isNight: Bool = false

    var body: some View {
        let clamped = min(max(progress, 0), 1)
        let pct = Int((progress * 100).rounded())
        let trackFill: Color = isNight ? Color(hex: 0x101634, opacity: 0.44) : Palette.creamDeep
        let trackBorder: Color = isNight ? Ink.starlight.opacity(0.28) : Ink.hairlineStrong
        let barGradient = isNight
            ? LinearGradient(
                colors: [Color(hex: 0x9BEBF5), Color(hex: 0x5EC7DF)],
                startPoint: .leading,
                endPoint: .trailing
            )
            : LinearGradient(
                colors: [tint.blended(with: .white, by: 0.14), tint, tint.blended(with: .black, by: 0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )

        HStack(spacing: 10) {
            GeometryReader { proxy in
                let h = proxy.size.height
                let w = max(h, proxy.size.width * clamped)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackFill)
                        .overlay { Capsule().stroke(trackBorder, lineWidth: 1) }

                    if progress > 0.001 {
                        Capsule()
                            .fill(barGradient)
                            .overlay {
                                Capsule().stroke(
                                    isNight
                                        ? Color(hex: 0xEEFCFF).opacity(0.60)
                                        : tint.blended(with: Ink.primary, by: 0.28).opacity(0.32),
                                    lineWidth: 0.85
                                )
                            }
                            .frame(width: min(w, proxy.size.width))
                            .padding(2.5)
                    }
                }
            }
            .frame(height: 14)

            Text("\(pct)%")
                .font(.dewy(12.5, .bold))
                .monospacedDigit()
                .foregroundStyle(isNight ? Ink.starlight : Palette.aquaDeep)
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(
                    isNight ? Color(hex: 0x101634, opacity: 0.44) : Palette.aquaSoft,
                    in: Capsule()
                )
                .overlay {
                    Capsule().stroke(
                        isNight ? Ink.starlight.opacity(0.28) : Palette.aqua.opacity(0.25),
                        lineWidth: 0.85
                    )
                }
                .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.72, dampingFraction: 0.78), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pct) percent of today's goal")
    }
}

/// Cotton-paper quick-sip tile with handcrafted drink art and matte letterpress action seal.
private struct QuickSipTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var amount: String
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(kind.light.blended(with: Palette.paper, by: 0.25))
                        .frame(width: 68, height: 58)
                    DrinkIcon(kind: kind, size: 54)
                }
                .padding(.top, 8)

                Text(kind.name)
                    .font(.display(13.5, .semibold))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(amount)
                    .font(.dewy(11.5, .bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.inkSoft)
                    .padding(.bottom, 8)
            }
            .frame(width: 88, height: 118)
            .background {
                PaperSurface(
                    shape: RoundedRectangle(cornerRadius: 22, style: .continuous),
                    fill: Palette.paper,
                    tint: kind.color,
                    elevation: 0.75
                )
            }
            .overlay(alignment: .topTrailing) {
                badge
                    .padding(6)
            }
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.92))
        .accessibilityLabel(isLocked ? "\(kind.name), Dewy+ only" : "Add \(amount) of \(kind.name)")
    }

    @ViewBuilder
    private var badge: some View {
        if isLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Palette.paper)
                .frame(width: 21, height: 21)
                .background(Palette.gold, in: Circle())
                .overlay(Circle().stroke(Color(hex: 0x7A5110).opacity(0.42), lineWidth: 0.85))
        } else {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Palette.paper)
                .frame(width: 21, height: 21)
                .background(kind.deep, in: Circle())
                .overlay(Circle().stroke(Palette.paper, lineWidth: 1.5))
                .overlay(Circle().stroke(Ink.primary.opacity(0.24), lineWidth: 0.75))
        }
    }
}

/// Compact cotton-paper metric card in the summary row.
private struct StatTile: View {
    @Environment(\.dewyTheme) private var theme
    var glyph: ClayGlyph
    var tint: Color
    var value: String
    var label: String
    var progress: Double?
    var usesWaterIcon = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if usesWaterIcon {
                    DrinkIcon(kind: .water, size: 28)
                } else {
                    ClayIcon(glyph: glyph, size: 26)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.display(18, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.dewy(11.5, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.well)
                    if let progress {
                        Capsule()
                            .fill(tint)
                            .frame(width: max(proxy.size.height, proxy.size.width * min(max(progress, 0), 1)))
                    }
                }
            }
            .frame(height: 5)
            .opacity(progress == nil ? 0 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dewyCard(padding: 14, radius: 22, glow: tint)
    }
}

private struct SipRow: View {
    @Environment(\.dewyTheme) private var theme
    var entry: DrinkEntry
    var amount: String
    var effective: String

    private var detail: String {
        let time = entry.date.formatted(date: .omitted, time: .shortened)
        if entry.caffeine >= 1 {
            return "\(time) · \(Int(entry.caffeine.rounded())) mg caffeine"
        }
        if entry.kind.hydration < 1 {
            return "\(time) · counts \(effective)"
        }
        return time
    }

    var body: some View {
        HStack(spacing: 12) {
            DrinkBadge(kind: entry.kind, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.name)
                    .font(.display(16.5, .semibold))
                    .foregroundStyle(theme.ink)
                Text(detail)
                    .font(.dewy(12, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text("+\(amount)")
                .font(.dewy(14.5, .bold))
                .monospacedDigit()
                .foregroundStyle(entry.kind.deep)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct UndoToast: View {
    @Environment(\.dewyTheme) private var theme
    var entry: DrinkEntry
    var label: String
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            DrinkIcon(kind: entry.kind, size: 30)
            Text("Added \(label) \(entry.kind.name.lowercased())")
                .font(.dewy(14, .bold))
                .foregroundStyle(theme.ink)
            Button(action: onUndo) {
                Text("Undo")
                    .font(.dewy(13, .bold))
                    .foregroundStyle(Palette.aquaDeep)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(Palette.aquaSoft, in: Capsule())
                    .overlay(Capsule().stroke(Palette.aqua.opacity(0.24), lineWidth: 0.75))
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: 48)
        .background {
            PaperSurface(shape: Capsule(), fill: Palette.paper, tint: entry.kind.color, elevation: 0.85)
        }
    }
}
