import SwiftUI

/// The Journey tab: every day the goal is reached, Dewy travels somewhere new.
/// Today's place fills the top of the screen, with its four story moments, the trail,
/// past adventures, week-long challenges and badges below.
struct JourneyView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme

    @State private var appeared = false
    @State private var selectedBadge: Achievement?
    @State private var confetti = 0

    /// Visible height of the scene above the sheet.
    private let heroHeight: CGFloat = 452
    /// Extra art drawn above the scroll view so the scene runs under the status bar.
    private let heroBleed: CGFloat = 130
    /// The sheet tucks over the bottom of the scene.
    private let sheetOverlap: CGFloat = 40
    /// Art aspect ratio (1290×1728).
    private let artAspect: CGFloat = 1290.0 / 1728.0
    /// Where the open ground sits in every journey picture.
    private let groundY: CGFloat = 0.785

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: -sheetOverlap) {
                    hero
                    sheet
                        .floatIn(appeared, index: 2)
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                appeared = true
                runDemoHooks(reader)
            }
        }
        .overlay {
            ConfettiView(trigger: confetti, origin: UnitPoint(x: 0.5, y: 0.45))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge, unlocked: store.unlockedAchievements().contains(badge))
                .presentationDetents([.height(430)])
                .presentationCornerRadius(38)
                .presentationBackground(theme.canvas)
        }
    }

    // MARK: Hero

    private var hero: some View {
        let chapter = store.todayChapter
        let unlocked = store.beatsUnlocked
        return GeometryReader { proxy in
            let width = proxy.size.width
            let artHeight = max(heroHeight + heroBleed, width / artAspect)
            let artWidth = artHeight * artAspect
            let feet = heroHeight - artHeight * (1 - groundY)

            ZStack(alignment: .top) {
                // The place, anchored to the bottom so the ground always lines up with Dewy.
                Image(chapter.imageName)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: max(artWidth, width), height: artHeight)
                    .frame(width: width, height: heroHeight + heroBleed, alignment: .bottom)
                    .clipped()
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0)], startPoint: .top, endPoint: .bottom)
                            .frame(height: heroBleed + 200)
                    }
                    // Taller than its frame: the extra art spills up under the status bar.
                    .frame(width: width, height: heroHeight, alignment: .bottom)

                header(chapter: chapter, unlocked: unlocked)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .floatIn(appeared, index: 0)

                travellers
                    .position(x: width / 2, y: feet)
                    .floatIn(appeared, index: 1)
            }
            .frame(width: width, height: heroHeight)
        }
        .frame(height: heroHeight)
        .background(alignment: .top) {
            // Overscrolling past the top shows more sky, never a gap.
            chapter.tint.blended(with: .white, by: 0.55)
                .frame(height: 900)
                .offset(y: -900)
        }
    }

    private func header(chapter: Chapter, unlocked: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    ClayIcon(glyph: .map, size: 20)
                    CapsLabel(text: "Lap \(store.journeyLap) · Stop \(stopNumber(chapter)) of \(Chapter.allCases.count)", color: theme.inkSoft, size: 10.5)
                }
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(height: 32)
                .background { ClaySurface(shape: Capsule(), fill: .white.opacity(0.92), glow: chapter.tint, elevation: 0.45) }
                Spacer(minLength: 0)
                CountPill(glyph: .drop, value: store.dropBalance, tint: Palette.coral, compact: true)
            }
            Text(chapter.title)
                .font(.display(36, .bold))
                .foregroundStyle(Ink.primary)
                .shadow(color: .white.opacity(0.9), radius: 10, x: 0, y: 0)
            MomentsMeter(unlocked: unlocked, tint: chapter.tint)
        }
    }

    /// Dewy (and the first companion) standing on the path.
    private var travellers: some View {
        let size: CGFloat = 132
        let height = size * DewyGeometry.canvas.height / DewyGeometry.canvas.width
        return HStack(alignment: .bottom, spacing: -6) {
            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: size,
                outfits: store.outfits,
                sparkles: store.todayProgress >= 1,
                bands: store.todayBands,
                showsShadow: false
            )
            if let friend = store.companions.first {
                ArtImage(name: friend.imageName, fallback: "pawprint.fill", tint: friend.tint, size: 78)
                    .offset(y: 2)
            }
        }
        .background(alignment: .bottom) {
            Ellipse()
                .fill(Color(hex: 0x3E5A3A).opacity(0.22))
                .frame(width: store.companions.isEmpty ? 110 : 180, height: 20)
                .blur(radius: 5)
                .offset(y: 6)
        }
        .frame(height: height, alignment: .bottom)
        // `.position` places the center; lift by half so the feet land on the ground line.
        .offset(y: -height / 2 + 6)
    }

    private func stopNumber(_ chapter: Chapter) -> Int {
        (Chapter.allCases.firstIndex(of: chapter) ?? 0) + 1
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 30) {
            story
            trail
            archive
            challenges
                .id("challenges")
            badges
                .id("badges")
        }
        .padding(.top, 26)
        .padding(.bottom, 130)
        .frame(maxWidth: .infinity)
        .canvasSheet()
    }

    // MARK: Story

    private var story: some View {
        let chapter = store.todayChapter
        let unlocked = store.beatsUnlocked
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's story", trailing: "\(unlocked)/4 moments")
                .padding(.horizontal, 20)
            VStack(spacing: 0) {
                ForEach(Array(chapter.beats.enumerated()), id: \.offset) { index, beat in
                    BeatRow(
                        index: index,
                        text: beat,
                        isUnlocked: index < unlocked,
                        isLast: index == chapter.beats.count - 1,
                        tint: chapter.tint
                    )
                }
            }
            .dewyCard(padding: 16, glow: chapter.tint)
            .padding(.horizontal, 20)
        }
    }

    // MARK: Trail

    private var trail: some View {
        let current = store.todayChapter
        let currentIndex = Chapter.allCases.firstIndex(of: current) ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "The trail", trailing: "Lap \(store.journeyLap)")
                .padding(.horizontal, 20)
            ScrollViewReader { reader in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(Chapter.allCases.enumerated()), id: \.element) { index, chapter in
                            TrailStop(
                                chapter: chapter,
                                number: index + 1,
                                state: index < currentIndex ? .visited : (index == currentIndex ? .here : .ahead),
                                progress: store.todayProgress,
                                mood: store.mood,
                                outfits: store.outfits,
                                bands: store.todayBands
                            )
                            .id(chapter)
                            if index < Chapter.allCases.count - 1 {
                                TrailDots(done: index < currentIndex)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .onAppear { reader.scrollTo(current, anchor: .center) }
            }
        }
    }

    // MARK: Archive

    private var archive: some View {
        let stops = Array(store.journeyArchive.prefix(14))
        let premium = purchases.isPremium
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: .now)) ?? .now
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Past adventures", trailing: stops.isEmpty ? nil : "\(store.journeyArchive.count) places")
                .padding(.horizontal, 20)
            if stops.isEmpty {
                HStack(spacing: 14) {
                    ClayIcon(glyph: .chest, size: 52)
                    Text("Reach your goal and every place Dewy visits will be kept here.")
                        .font(.dewy(14.5, .semibold))
                        .foregroundStyle(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .dewyCard(padding: 16)
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(stops) { stop in
                            let locked = !premium && stop.date < cutoff
                            Button {
                                Haptics.tap()
                                if locked { router.showPaywall = true }
                            } label: {
                                ArchiveCard(stop: stop, locked: locked)
                            }
                            .buttonStyle(SquishyButtonStyle(scale: 0.96))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
    }

    // MARK: Challenges

    private var challenges: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Challenges", trailing: "Win outfits")
                .padding(.horizontal, 20)
            VStack(spacing: 14) {
                ForEach(ChallengeKind.allCases) { challenge in
                    ChallengeCard(
                        challenge: challenge,
                        progress: store.progress(of: challenge),
                        rewardOwned: store.collection.outfits.contains(challenge.reward)
                    ) {
                        toggle(challenge)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func toggle(_ challenge: ChallengeKind) {
        let state = store.progress(of: challenge).state
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            switch state {
            case .notStarted:
                Haptics.success()
                store.join(challenge)
                confetti += 1
            case .failed:
                // Start again from today.
                Haptics.success()
                store.join(challenge)
            case .active:
                Haptics.tap()
                store.leave(challenge)
            case .completed:
                Haptics.tap()
                router.tab = .friends
            }
        }
    }

    // MARK: Badges

    private var badges: some View {
        let unlocked = store.unlockedAchievements()
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Badges", trailing: "\(unlocked.count) of \(Achievement.allCases.count)")
                .padding(.horizontal, 20)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Achievement.allCases) { badge in
                    Button {
                        Haptics.tap()
                        selectedBadge = badge
                    } label: {
                        BadgeTile(badge: badge, unlocked: unlocked.contains(badge))
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.94))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Demo

    private func runDemoHooks(_ reader: ScrollViewProxy) {
        let target: String? = switch LaunchOptions.screenshot {
        case "challenges": "challenges"
        case "badges": "badges"
        default: nil
        }
        guard let target else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            reader.scrollTo(target, anchor: .top)
        }
    }
}

// MARK: - Moments meter

/// Four little clay stones that light up as the day's story unfolds.
private struct MomentsMeter: View {
    var unlocked: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                let lit = index < unlocked
                ZStack {
                    Circle()
                        .fill(lit ? AnyShapeStyle(LinearGradient(colors: [Palette.butterSoft, Palette.butter], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.white.opacity(0.75)))
                    if lit {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Palette.butterDeep)
                    } else {
                        Text("\(index + 1)")
                            .font(.display(12))
                            .foregroundStyle(Ink.faint)
                    }
                }
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: (lit ? Palette.butterDeep : Palette.shadow).opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(lit ? 1 : 0.9)
            }
            Text(unlocked == 4 ? "Adventure complete!" : "\(unlocked) of 4 moments")
                .font(.dewy(13.5, .heavy))
                .foregroundStyle(Ink.primary.opacity(0.75))
                .padding(.leading, 4)
                .shadow(color: .white, radius: 6)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.65), value: unlocked)
    }
}

// MARK: - Story beats

private struct BeatRow: View {
    @Environment(\.dewyTheme) private var theme
    var index: Int
    var text: String
    var isUnlocked: Bool
    var isLast: Bool
    var tint: Color

    private var milestone: Int { (index + 1) * 25 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isUnlocked
                              ? AnyShapeStyle(LinearGradient(colors: [tint.blended(with: .white, by: 0.25), tint], startPoint: .top, endPoint: .bottom))
                              : AnyShapeStyle(theme.well))
                    if isUnlocked {
                        Text("\(index + 1)")
                            .font(.display(16, .bold))
                            .foregroundStyle(.white)
                            .shadow(color: tint.blended(with: .black, by: 0.3).opacity(0.4), radius: 0, x: 0, y: 1)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Ink.faint)
                    }
                }
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(.white, lineWidth: 2.5))
                .shadow(color: (isUnlocked ? tint : Palette.shadow).opacity(0.3), radius: 5, x: 0, y: 3)
                if !isLast {
                    Capsule()
                        .fill(isUnlocked ? tint.opacity(0.45) : theme.line)
                        .frame(width: 4)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    CapsLabel(text: "At \(milestone)%", color: isUnlocked ? tint.blended(with: .black, by: 0.35) : Ink.faint, size: 10.5)
                    Spacer(minLength: 0)
                    HStack(spacing: 2) {
                        ClayIcon(glyph: .drop, size: 14)
                        Text("+\(DropRules.perBeat)")
                            .font(.display(13))
                            .foregroundStyle(isUnlocked ? Palette.coralDeep : Ink.faint)
                    }
                    .opacity(isUnlocked ? 1 : 0.6)
                }
                if isUnlocked {
                    Text(text)
                        .font(.dewy(15.5, .semibold))
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading)))
                } else {
                    // A soft placeholder hints at the moment without spoiling it.
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule().fill(theme.well).frame(height: 10)
                        Capsule().fill(theme.well).frame(width: 150, height: 10)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, isLast ? 0 : 18)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Trail

private struct TrailStop: View {
    enum Status { case visited, here, ahead }

    var chapter: Chapter
    var number: Int
    var state: Status
    var progress: Double
    var mood: DewyMood
    var outfits: [Outfit]
    var bands: [LiquidBand]

    var body: some View {
        let isHere = state == .here
        let size: CGFloat = isHere ? 96 : 76
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Image(chapter.imageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .saturation(state == .ahead ? 0.25 : 1)
                    .opacity(state == .ahead ? 0.7 : 1)
                    .overlay(Circle().stroke(.white, lineWidth: isHere ? 4 : 3))
                    .shadow(color: (state == .ahead ? Palette.shadow : chapter.tint).opacity(0.45), radius: isHere ? 12 : 6, x: 0, y: isHere ? 8 : 4)
                if isHere {
                    MascotView(progress: progress, mood: mood, size: 40, outfits: outfits, bands: bands, animated: false, showsShadow: false)
                        .offset(y: 10)
                }
                if state == .visited {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Palette.mint))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: size * 0.34, y: -size * 0.68)
                }
                if state == .ahead {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 3)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: size, height: size)
            VStack(spacing: 1) {
                Text(chapter.title)
                    .font(.display(isHere ? 14 : 12.5))
                    .foregroundStyle(state == .ahead ? Ink.soft : Ink.primary)
                    .lineLimit(1)
                Text(isHere ? "You are here" : "Stop \(number)")
                    .font(.dewy(11, .heavy))
                    .foregroundStyle(isHere ? chapter.tint.blended(with: .black, by: 0.35) : Ink.faint)
            }
            .frame(width: 100)
        }
        .frame(height: 150, alignment: .bottom)
    }
}

/// A dotted path between two trail stops.
private struct TrailDots: View {
    var done: Bool

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(done ? Palette.aqua.opacity(0.65) : Color(hex: 0xE9DCD0))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(width: 22)
        .padding(.bottom, 60)
        .frame(height: 150, alignment: .center)
    }
}

// MARK: - Archive

private struct ArchiveCard: View {
    var stop: JourneyStop
    var locked: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(stop.chapter.imageName)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: 128, height: 164)
                .clipped()
                .blur(radius: locked ? 6 : 0)
                .saturation(locked ? 0.6 : 1)
            LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 1) {
                Text(stop.chapter.title)
                    .font(.display(15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(stop.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.dewy(12, .bold))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
            .padding(12)
            if locked {
                VStack(spacing: 6) {
                    ClayIcon(glyph: .crown, size: 34)
                    PlusBadge()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 128, height: 164)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white, lineWidth: 3)
        }
        .shadow(color: stop.chapter.tint.opacity(0.45), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Challenges

private struct ChallengeCard: View {
    @Environment(\.dewyTheme) private var theme
    var challenge: ChallengeKind
    var progress: ChallengeProgress
    var rewardOwned: Bool
    var action: () -> Void

    private var stateLine: String {
        switch progress.state {
        case .notStarted: "\(challenge.days) days · \(challenge.rule)"
        case .active: "Day \(min(progress.daysDone + 1, progress.total)) of \(progress.total) · \(challenge.rule)"
        case .completed: "Finished! The \(challenge.reward.name) is yours."
        case .failed: "So close. Try again from today?"
        }
    }

    private var buttonTitle: String {
        switch progress.state {
        case .notStarted: "Join"
        case .active: "Leave"
        case .completed: "Wear it"
        case .failed: "Retry"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                IconTile(systemImage: challenge.symbol, color: challenge.tint, size: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.display(19))
                        .foregroundStyle(theme.ink)
                    Text(stateLine)
                        .font(.dewy(13.5, .semibold))
                        .foregroundStyle(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                // The prize: a wardrobe item plus drops.
                VStack(spacing: 2) {
                    ArtImage(name: challenge.reward.imageName, fallback: "tshirt.fill", tint: challenge.reward.tint, size: 50)
                        .background {
                            Circle().fill(challenge.reward.tint.opacity(0.22)).frame(width: 58, height: 58)
                        }
                    HStack(spacing: 2) {
                        ClayIcon(glyph: .drop, size: 13)
                        Text("+\(DropRules.challenge)")
                            .font(.display(12))
                            .foregroundStyle(Palette.coralDeep)
                    }
                }
            }
            HStack(spacing: 12) {
                ChallengeDays(progress: progress, tint: challenge.tint)
                Spacer(minLength: 0)
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.display(15))
                        .foregroundStyle(buttonIsQuiet ? theme.ink : .white)
                        .padding(.horizontal, 18)
                        .frame(height: 38)
                }
                .buttonStyle(CandyButtonStyle(
                    fill: buttonIsQuiet ? .white : challenge.tint,
                    lip: buttonIsQuiet ? Color(hex: 0xEEDFD3) : challenge.tint.blended(with: .black, by: 0.2),
                    depth: 3
                ))
            }
        }
        .dewyCard(padding: 16, glow: progress.state == .notStarted ? nil : challenge.tint)
        .overlay(alignment: .topLeading) {
            if progress.state == .completed {
                CapsLabel(text: "Done", color: .white, size: 10)
                    .padding(.horizontal, 10)
                    .frame(height: 22)
                    .background(Palette.mint, in: Capsule())
                    .offset(x: 14, y: -10)
            }
        }
    }

    private var buttonIsQuiet: Bool { progress.state == .active }
}

/// One pebble per day of the challenge, filled as days pass.
private struct ChallengeDays: View {
    var progress: ChallengeProgress
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<progress.total, id: \.self) { day in
                let done = day < progress.daysDone
                Capsule()
                    .fill(done
                          ? AnyShapeStyle(LinearGradient(colors: [tint.blended(with: .white, by: 0.25), tint], startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(Color(hex: 0xF4EAE0)))
                    .frame(width: 18, height: 12)
                    .overlay(alignment: .top) {
                        if done {
                            Capsule().fill(.white.opacity(0.45)).frame(height: 3).padding(.horizontal, 4).padding(.top, 2)
                        }
                    }
            }
        }
        .opacity(progress.state == .failed ? 0.5 : 1)
    }
}

// MARK: - Badges

private struct BadgeTile: View {
    @Environment(\.dewyTheme) private var theme
    var badge: Achievement
    var unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ArtImage(name: "badge-\(badge.rawValue)", fallback: badge.symbol, tint: badge.tint, size: 74)
                .saturation(unlocked ? 1 : 0)
                .opacity(unlocked ? 1 : 0.38)
                .overlay(alignment: .bottomTrailing) {
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Ink.faint))
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            Text(badge.title)
                .font(.display(13))
                .foregroundStyle(unlocked ? theme.ink : theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background {
            ClaySurface(
                shape: RoundedRectangle(cornerRadius: 24, style: .continuous),
                fill: unlocked ? .white : Color(hex: 0xFBF5EF),
                glow: unlocked ? badge.tint : Palette.shadow,
                elevation: unlocked ? 0.8 : 0.35
            )
        }
    }
}

private struct BadgeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var badge: Achievement
    var unlocked: Bool
    @State private var pop = false

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Ink.faint.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 10)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [badge.tint.opacity(unlocked ? 0.35 : 0.12), .clear], center: .center, startRadius: 10, endRadius: 110))
                    .frame(width: 220, height: 220)
                ArtImage(name: "badge-\(badge.rawValue)", fallback: badge.symbol, tint: badge.tint, size: 150)
                    .saturation(unlocked ? 1 : 0)
                    .opacity(unlocked ? 1 : 0.45)
                    .scaleEffect(pop ? 1 : 0.6)
                    .rotationEffect(.degrees(pop ? 0 : -12))
            }
            .frame(height: 170)
            VStack(spacing: 6) {
                Text(badge.title)
                    .font(.display(26, .bold))
                    .foregroundStyle(Ink.primary)
                Text(badge.detail)
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(Ink.soft)
                    .multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    ClayIcon(glyph: .drop, size: 16)
                    Text(unlocked ? "Earned \(DropRules.badge) drops" : "Worth \(DropRules.badge) drops")
                        .font(.display(14))
                        .foregroundStyle(Palette.coralDeep)
                }
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Palette.coralSoft, in: Capsule())
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
            Spacer(minLength: 0)
            PrimaryButton(title: unlocked ? "Yay!" : "Keep going", style: unlocked ? .accent : .light, height: 54) {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { pop = true }
            if unlocked { Haptics.success() }
        }
    }
}
