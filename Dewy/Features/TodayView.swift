import SwiftUI

/// Frames measured for the pour-in animation. A plain reference so scrolling never re-renders the screen.
private final class PourGeometry {
    var tiles: [DrinkKind: CGRect] = [:]
    var dewy: CGRect = .zero
    var screen: CGRect = .zero
}

/// A drink flying from its tile into Dewy.
private struct Flight: Identifiable, Equatable {
    let id = UUID()
    var kind: DrinkKind
    var amount: Double
    var from: CGPoint
    var to: CGPoint
}

/// A little "+N drops" that floats up after a sip lands.
private struct DropPop: Identifiable, Equatable {
    let id = UUID()
    var value: Int
}

struct TodayView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme

    @State private var showShare = false
    @State private var bounce = 0
    @State private var ripple = 0
    @State private var splash = 0
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

    // Fixed hero metrics keep Dewy's lily pad lined up with the pond.
    private let headerHeight: CGFloat = 112
    private let stageHeight: CGFloat = 262
    private let amountHeight: CGFloat = 124
    private let mascotSize: CGFloat = 196
    private let padWidth: CGFloat = 164
    private var mascotHeight: CGFloat { mascotSize * DewyGeometry.canvas.height / DewyGeometry.canvas.width }
    /// Top of the lily pad canvas inside the stage, so Dewy's feet land on the pad's top surface.
    private var padTop: CGFloat { mascotHeight * 0.925 - padWidth * 0.232 }
    /// The scene runs under the sheet so its rounded corners show pond, not canvas.
    private var sceneHeight: CGFloat { headerHeight + stageHeight + amountHeight + 96 }
    /// The pond starts behind Dewy's lower half.
    private var horizonY: CGFloat { headerHeight + 118 }

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

            // Drinks in flight, above the scroll view.
            ForEach(flights) { flight in
                FlyingDrink(flight: flight) {
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
                .transition(.opacity.combined(with: .scale(scale: 1.06)))
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
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
            }
        }
        .sheet(isPresented: $showShare) {
            ShareDaySheet()
        }
        .task(id: router.queuedDrink) {
            guard let queued = router.queuedDrink else { return }
            // Give the drink sheet a moment to slide away so the pour is visible.
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
            amount
                .frame(height: amountHeight, alignment: .top)
                .floatIn(appeared, index: 2)
        }
        .padding(.top, 6)
        .padding(.bottom, 18)
        .background(alignment: .top) {
            VStack(spacing: 0) {
                phase.sky[0].frame(height: 800)
                ClayWorld(horizon: horizonY, decor: store.placedDecor, interactive: true)
                    .frame(height: sceneHeight)
            }
            .frame(height: sceneHeight, alignment: .bottom)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    CapsLabel(text: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()), color: phase.onSkySoft, size: 11.5)
                    Text(greeting)
                        .font(.display(30))
                        .foregroundStyle(phase.onSky)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
                CircleIconButton(systemImage: "square.and.arrow.up", size: 38, onHero: true) {
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
            MascotView(progress: store.todayProgress, mood: .happy, size: 40, outfits: store.outfits, bands: store.todayBands, backdrop: .light, animated: false, showsShadow: false)
                .offset(y: 2)
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .background {
                    ClaySurface(shape: Circle(), fill: .white, glow: Palette.aqua, elevation: 0.6)
                }
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Me and settings")
    }

    private var stage: some View {
        ZStack(alignment: .top) {
            LilyPad(width: padWidth, rippleTrigger: ripple)
                .offset(y: padTop)

            companions

            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: mascotSize,
                bounceTrigger: bounce,
                outfits: store.outfits,
                bands: store.todayBands
            )
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
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.3)
            }

            SplashBurst(trigger: splash)
                .frame(width: 260, height: 200)
                .offset(y: mascotHeight * 0.1)

            ForEach(pops) { pop in
                DropPopView(value: pop.value)
                    .offset(x: 70, y: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            SpeechBubble(text: store.mood.line())
                .padding(.trailing, 16)
                .padding(.top, 2)
        }
    }

    /// Friends hang out on their own little pads beside Dewy.
    private var companions: some View {
        let friends = store.companions
        return ZStack(alignment: .top) {
            ForEach(Array(friends.prefix(2).enumerated()), id: \.element) { index, friend in
                CompanionView(friend: friend, index: index)
                    .offset(x: index == 0 ? -128 : 128, y: padTop - 28)
            }
        }
    }

    private var amount: some View {
        let ink: Color = phase.isNight ? .white : theme.ink
        return VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(store.format(store.todayTotal, withUnit: false))
                    .font(.display(64, .bold))
                    .foregroundStyle(ink)
                    .contentTransition(.numericText(value: store.displayValue(store.todayTotal)))
                Text(store.profile.unit.label)
                    .font(.display(24))
                    .foregroundStyle(ink.opacity(0.6))
            }
            .shadow(color: .white.opacity(phase.isNight ? 0 : 0.6), radius: 0, x: 0, y: 2)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.todayTotal)

            Text("of your \(store.format(store.goal)) goal")
                .font(.display(17, .medium))
                .foregroundStyle(ink.opacity(0.65))

            ClayProgressBar(progress: store.todayProgress)
                .frame(width: 272, height: 30)
                .padding(.top, 8)
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
        .padding(.bottom, 120)
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
                .padding(.bottom, 14)
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
            withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) { router.tab = .journey }
        } label: {
            HStack(spacing: 14) {
                Image(chapter.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white, lineWidth: 3)
                    }
                    .overlay(alignment: .bottom) {
                        MascotView(progress: store.todayProgress, mood: store.mood, size: 34, outfits: store.outfits, bands: store.todayBands, animated: false, showsShadow: false)
                            .offset(y: -8)
                    }
                    .shadow(color: chapter.tint.opacity(0.45), radius: 10, x: 0, y: 6)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        ClayIcon(glyph: .map, size: 18)
                        CapsLabel(text: "Today's adventure", color: theme.inkSoft, size: 10.5)
                    }
                    Text(chapter.title)
                        .font(.display(20))
                        .foregroundStyle(theme.ink)
                    Text(line)
                        .font(.dewy(13.5, .medium))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(index < unlocked ? AnyShapeStyle(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(theme.well))
                                .frame(height: 8)
                        }
                        Text("\(unlocked)/4")
                            .font(.display(13))
                            .foregroundStyle(theme.inkSoft)
                            .padding(.leading, 2)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: unlocked)
                }
                Spacer(minLength: 0)
            }
            .dewyCard(padding: 12, glow: chapter.tint)
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
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        if index < entries.count - 1 {
                            Capsule()
                                .fill(theme.line)
                                .frame(height: 1.5)
                                .padding(.leading, 64)
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
            ClayIcon(glyph: .star, size: 44)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                CapsLabel(text: "Daily dew tip", color: Color(hex: 0x9A6B12).opacity(0.75), size: 11)
                Text(HydrationTips.tip())
                    .font(.display(17, .medium))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dewyCard(padding: 16, fill: Palette.butterSoft, glow: Palette.butter)
        .padding(.horizontal, 20)
    }

    // MARK: Actions

    /// Sends the drink flying into Dewy; it's logged when it lands.
    private func pour(_ kind: DrinkKind, amount: Double, from start: CGPoint) {
        Haptics.tap()
        let dewy = geometry.dewy
        let target = CGPoint(x: dewy.midX, y: dewy.minY + dewy.height * 0.4)
        guard start != .zero, dewy != .zero, !LaunchOptions.freezesMotion else {
            add(kind, amount: amount)
            return
        }
        flights.append(Flight(kind: kind, amount: amount, from: start, to: target))
    }

    private func land(_ flight: Flight) {
        flights.removeAll { $0.id == flight.id }
        add(flight.kind, amount: flight.amount)
    }

    private func add(_ kind: DrinkKind, amount: Double) {
        let wasBelowGoal = store.todayProgress < 1
        let dropsBefore = store.todayDrops
        var entry: DrinkEntry?
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            entry = store.add(kind, amount: amount)
        }
        bounce += 1
        ripple += 1
        splash += 1
        Haptics.splash()
        SoundFX.play(.pour)
        let gained = store.todayDrops - dropsBefore
        if gained > 0 {
            let pop = DropPop(value: gained)
            pops.append(pop)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.4))
                pops.removeAll { $0.id == pop.id }
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
            // Demo recording: two visible drinks fly in, the second one reaches the goal.
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

// MARK: - Pour

/// The drink art arcs from its tile into Dewy, shrinking and tipping as it pours, with a few
/// droplets trailing behind it.
private struct FlyingDrink: View {
    var flight: Flight
    var onLand: () -> Void

    @State private var start = Date.now
    private let duration: Double = 0.62

    var body: some View {
        TimelineView(.animation) { timeline in
            let raw = min(max(timeline.date.timeIntervalSince(start) / duration, 0), 1)
            let p = easeInOut(raw)
            ZStack {
                ForEach(1..<4, id: \.self) { index in
                    let q = max(p - Double(index) * 0.07, 0)
                    Image(systemName: "drop.fill")
                        .font(.system(size: CGFloat(12 - index * 2), weight: .black))
                        .foregroundStyle(flight.kind.color.opacity(0.8 - Double(index) * 0.18))
                        .position(point(q))
                        .opacity(q > 0.02 ? 1 : 0)
                }
                DrinkIcon(kind: flight.kind, size: 64)
                    .scaleEffect(1 - 0.5 * p)
                    .rotationEffect(.degrees(-30 * p))
                    .opacity(raw > 0.92 ? (1 - raw) / 0.08 : 1)
                    .shadow(color: flight.kind.color.opacity(0.4), radius: 10, x: 0, y: 6)
                    .position(point(p))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(duration))
            onLand()
        }
    }

    private func easeInOut(_ t: Double) -> Double { t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2 }

    private func point(_ t: Double) -> CGPoint {
        let a = flight.from
        let b = flight.to
        let control = CGPoint(x: (a.x + b.x) / 2 + (a.x < b.x ? -30 : 30), y: min(a.y, b.y) - 170)
        let u = 1 - t
        let x = u * u * a.x + 2 * u * t * control.x + t * t * b.x
        let y = u * u * a.y + 2 * u * t * control.y + t * t * b.y
        return CGPoint(x: x, y: y)
    }
}

/// Droplets spraying up and out of Dewy when a drink lands.
private struct SplashBurst: View {
    var trigger: Int
    @State private var start: Date?

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                draw(in: &context, size: size, time: timeline.date.timeIntervalSince(start))
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            start = .now
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                start = nil
            }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        guard t >= 0, t < 0.9 else { return }
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.28)
        context.opacity = max(0, 1 - t / 0.9)
        for index in 0..<12 {
            let spread = Double(index) / 11.0 - 0.5
            let angle = -Double.pi / 2.0 + spread * 2.2
            let speed = 150.0 + Double(index % 3) * 50.0
            let dx = CGFloat(cos(angle) * speed * t)
            let dy = CGFloat(sin(angle) * speed * t + 420.0 * t * t)
            let x = origin.x + dx
            let y = origin.y + dy
            let r = CGFloat(4.0 + Double(index % 3) * 1.5)
            let dropRect = CGRect(x: x - r, y: y - r * 1.3, width: r * 2, height: r * 2.6)
            let glintRect = CGRect(x: x - r * 0.45, y: y - r * 0.2, width: r * 0.6, height: r * 0.6)
            context.fill(DewyShape().path(in: dropRect), with: .color(Palette.aquaLight))
            context.fill(Path(ellipseIn: glintRect), with: .color(.white.opacity(0.9)))
        }
    }
}

private struct DropPopView: View {
    var value: Int
    @State private var risen = false

    var body: some View {
        HStack(spacing: 3) {
            ClayIcon(glyph: .drop, size: 20)
            Text("+\(value)")
                .font(.display(17))
                .foregroundStyle(Palette.coralDeep)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background {
            ClaySurface(shape: Capsule(), fill: .white, glow: Palette.coral, elevation: 0.5)
        }
        .offset(y: risen ? -46 : 0)
        .opacity(risen ? 0 : 1)
        .scaleEffect(risen ? 1 : 0.6)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { risen = false }
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) { risen = true }
        }
    }
}

// MARK: - Celebration

/// The moment the goal is reached: a full-screen party with Dewy jumping and spinning,
/// clay confetti and bubbles, and the Dew Drops reward rolling up.
private struct CelebrationOverlay: View {
    @Environment(\.dewyTheme) private var theme
    var reward: Int
    var streak: Int
    var goal: String
    var outfits: [Outfit]
    var bands: [LiquidBand]
    var onDone: () -> Void

    @State private var jump = 0
    @State private var shown = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Palette.cream.opacity(0.72))
                .ignoresSafeArea()
                .onTapGesture(perform: onDone)

            BubbleField(count: 16)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Palette.butter.opacity(0.55), Palette.butter.opacity(0)], center: .center, startRadius: 10, endRadius: 170))
                        .frame(width: 340, height: 340)
                        .scaleEffect(shown ? 1 : 0.4)
                    MascotView(progress: 1.05, mood: .ecstatic, size: 200, bounceTrigger: jump, outfits: outfits, sparkles: true, bands: bands, showsShadow: false)
                        .keyframeAnimator(initialValue: CelebrationJump(), trigger: jump) { view, value in
                            view
                                .rotation3DEffect(.degrees(value.spin), axis: (x: 0, y: 1, z: 0))
                                .offset(y: value.lift)
                        } keyframes: { _ in
                            KeyframeTrack(\.lift) {
                                CubicKeyframe(14, duration: 0.14)
                                SpringKeyframe(-90, duration: 0.36)
                                SpringKeyframe(0, duration: 0.6, spring: .bouncy)
                            }
                            KeyframeTrack(\.spin) {
                                LinearKeyframe(0, duration: 0.16)
                                CubicKeyframe(360, duration: 0.6)
                                LinearKeyframe(360, duration: 0.3)
                            }
                        }
                }
                .frame(height: 260)

                Text("Goal reached!")
                    .font(.display(38, .bold))
                    .foregroundStyle(theme.ink)
                Text("You drank your \(goal) today.\nDewy is overflowing with joy.")
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        ClayIcon(glyph: .drop, size: 34)
                        RollingNumber(value: reward, font: .display(30, .bold), color: Palette.coralDeep, delay: 0.7)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background { ClaySurface(shape: Capsule(), fill: .white, glow: Palette.coral) }

                    HStack(spacing: 6) {
                        ClayIcon(glyph: .flame, size: 30)
                        Text("\(streak)")
                            .font(.display(26, .bold))
                            .foregroundStyle(Color(hex: 0xB9781A))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background { ClaySurface(shape: Capsule(), fill: .white, glow: Palette.butter) }
                }
                .padding(.top, 6)

                PrimaryButton(title: "Yay, Dewy!", style: .reward, action: onDone)
                    .padding(.horizontal, 40)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .scaleEffect(shown ? 1 : 0.85)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { shown = true }
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

// MARK: - Pieces

/// A friend hanging out beside Dewy on a little lily pad, bobbing gently.
private struct CompanionView: View {
    var friend: Friend
    var index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let live = !reduceMotion && !LaunchOptions.freezesMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !live)) { timeline in
            let t = live ? timeline.date.timeIntervalSinceReferenceDate : 0
            let bob = CGFloat(sin(t * 1.6 + Double(index) * 1.7)) * 3
            VStack(spacing: -18) {
                ArtImage(name: friend.imageName, fallback: "pawprint.fill", tint: friend.tint, size: 74)
                    .scaleEffect(x: index == 0 ? 1 : -1, y: 1)
                    .offset(y: bob)
                    .zIndex(1)
                if Art.exists("prop-lilypad") {
                    Image("prop-lilypad")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84)
                }
            }
        }
        .frame(width: 96)
        .accessibilityHidden(true)
    }
}

/// A clay progress capsule with a glossy aqua fill and the percentage riding on it.
struct ClayProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let width = max(height, proxy.size.width * min(max(progress, 0), 1))
            ZStack(alignment: .leading) {
                ClaySurface(shape: Capsule(), fill: .white.opacity(0.92), glow: Palette.aqua, elevation: 0.5)
                Capsule()
                    .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.45))
                            .frame(height: height * 0.28)
                            .padding(.horizontal, height * 0.35)
                            .padding(.top, height * 0.12)
                    }
                    .frame(width: width)
                    .padding(4)
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.display(15))
                    .foregroundStyle(progress > 0.18 ? .white : Ink.primary)
                    .shadow(color: Palette.aquaDeep.opacity(progress > 0.18 ? 0.4 : 0), radius: 0, x: 0, y: 1)
                    .contentTransition(.numericText())
                    .frame(width: max(width - 8, 50), alignment: progress > 0.18 ? .trailing : .center)
                    .padding(.trailing, progress > 0.18 ? 10 : 0)
                    .padding(.leading, 4)
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.72), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int((progress * 100).rounded())) percent of today's goal")
    }
}

/// A drink tile in the quick-sip row: a white clay tile with a glow in the drink's color.
private struct QuickSipTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var amount: String
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                DrinkIcon(kind: kind, size: 62)
                    .padding(.top, 4)
                Text(kind.name)
                    .font(.display(14))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(amount)
                    .font(.dewy(12, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            .frame(width: 86, height: 116)
            .background {
                ClaySurface(shape: RoundedRectangle(cornerRadius: 26, style: .continuous), fill: .white, glow: kind.color)
            }
            .background {
                // A colored clay base peeking out under the tile, like the mockups.
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(kind.light)
                    .offset(x: 3, y: 5)
            }
            .overlay(alignment: .topTrailing) {
                Group {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Palette.gold, in: Circle())
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(LinearGradient(colors: [kind.color.blended(with: .white, by: 0.15), kind.deep], startPoint: .top, endPoint: .bottom), in: Circle())
                    }
                }
                .padding(7)
            }
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.9))
        .accessibilityLabel(isLocked ? "\(kind.name), Dewy+ only" : "Add \(amount) of \(kind.name)")
    }
}

/// A small stat card in the summary row.
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
                    DrinkIcon(kind: .water, size: 30)
                } else {
                    ClayIcon(glyph: glyph, size: 30)
                }
            }
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
            .frame(height: 6)
            .opacity(progress == nil ? 0 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dewyCard(padding: 14, radius: 24, glow: tint)
    }
}

private struct SpeechBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.display(15, .medium))
            .foregroundStyle(Ink.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 118)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background {
                ZStack(alignment: .bottomLeading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .offset(x: 2, y: 10)
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .offset(x: -6, y: 22)
                    ClaySurface(shape: RoundedRectangle(cornerRadius: 22, style: .continuous), fill: .white, glow: Palette.aqua, elevation: 0.6)
                }
            }
            .rotationEffect(.degrees(4))
            .id(text)
            .transition(.scale.combined(with: .opacity))
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
            DrinkBadge(kind: entry.kind, size: 50)
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
            DrinkIcon(kind: entry.kind, size: 32)
            Text("Added \(label) \(entry.kind.name.lowercased())")
                .font(.display(16, .medium))
                .foregroundStyle(theme.ink)
            Button(action: onUndo) {
                Text("Undo")
                    .font(.display(15))
                    .foregroundStyle(Palette.aquaDeep)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Palette.aquaSoft, in: Capsule())
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: 52)
        .background {
            ClaySurface(shape: Capsule(), fill: .white, glow: entry.kind.color)
        }
    }
}
