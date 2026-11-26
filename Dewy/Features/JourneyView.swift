import SwiftUI

/// The Journey tab: every day the goal is reached, Dewy travels to a new illustrated chapter.
/// A live multi-layer storybook panorama fills the top, followed by the poetic story journal,
/// botanical trail, past adventure postcards, week-long challenges and cloisonné badges.
struct JourneyView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme

    @State private var appeared = false
    @State private var selectedBadge: Achievement?
    @State private var confetti = 0

    /// Visible height of the panorama above the sheet overlap.
    private let heroHeight: CGFloat = 446
    /// Extra panorama drawn above the scroll view so it bleeds seamlessly under the status bar.
    private let heroBleed: CGFloat = 130
    /// Rounded cotton-paper sheet overlaps the lower foreground border.
    private let sheetOverlap: CGFloat = 40

    private var isDarkChapter: Bool {
        store.todayChapter == .grove || store.todayChapter == .lake
    }

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
                .preferredColorScheme(.light)
                .presentationDetents([.height(436)])
                .presentationCornerRadius(34)
                .presentationBackground(theme.canvas)
        }
    }

    // MARK: Hero

    private var hero: some View {
        let chapter = store.todayChapter
        let unlocked = store.beatsUnlocked
        let dark = isDarkChapter
        let totalSceneHeight = heroHeight + heroBleed
        let feetY = totalSceneHeight * 0.835 - heroBleed

        return GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .top) {
                JourneySceneView(chapter: chapter)
                    .frame(width: width, height: totalSceneHeight)
                    .overlay(alignment: .top) {
                        headerScrim(isDark: dark)
                            .frame(height: heroBleed + (dark ? 185 : 165))
                    }
                    .frame(width: width, height: heroHeight, alignment: .bottom)

                header(chapter: chapter, unlocked: unlocked, isDark: dark)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .floatIn(appeared, index: 0)

                travellers(isDark: dark)
                    .position(x: width * 0.5, y: feetY)
                    .floatIn(appeared, index: 1)
            }
            .frame(width: width, height: heroHeight)
        }
        .frame(height: heroHeight)
        .background(alignment: .top) {
            overscrollSky(for: chapter)
                .frame(height: 600)
                .offset(y: -600)
        }
    }

    private func headerScrim(isDark: Bool) -> LinearGradient {
        if isDark {
            return LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x1D224E).opacity(0.76), location: 0),
                    .init(color: Color(hex: 0x262C60).opacity(0.42), location: 0.58),
                    .init(color: Color.clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            stops: [
                .init(color: Palette.paper.opacity(0.46), location: 0),
                .init(color: Palette.paper.opacity(0.14), location: 0.62),
                .init(color: Color.clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func overscrollSky(for chapter: Chapter) -> Color {
        switch chapter {
        case .spring: Color(hex: 0xE2F7EE)
        case .brook: Color(hex: 0xDDF4FF)
        case .meadow: Color(hex: 0xEFFBE8)
        case .falls: Color(hex: 0xDCEAFF)
        case .cove: Color(hex: 0xFFE9DB)
        case .peak: Color(hex: 0xFFEAD4)
        case .grove: Color(hex: 0x24244E)
        case .lake: Color(hex: 0x131B3E)
        }
    }

    private func header(chapter: Chapter, unlocked: Int, isDark: Bool) -> some View {
        let titleColor: Color = isDark ? Ink.starlight : Ink.primary
        let haloColor: Color = isDark ? Color(hex: 0x121638).opacity(0.55) : Palette.paper.opacity(0.75)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    ClayIcon(glyph: .map, size: 18)
                    CapsLabel(
                        text: "Lap \(store.journeyLap) · Stop \(stopNumber(chapter)) of \(Chapter.allCases.count)",
                        color: theme.inkSoft,
                        size: 10
                    )
                }
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(height: 32)
                .background {
                    PaperSurface(shape: Capsule(), fill: Palette.paper.opacity(0.94), tint: chapter.tint, elevation: 0.45)
                }

                Spacer(minLength: 0)

                CountPill(glyph: .drop, value: store.dropBalance, tint: Palette.coral, compact: true)
            }

            Text(chapter.title)
                .font(.display(36, .bold))
                .tracking(-0.5)
                .foregroundStyle(titleColor)
                .shadow(color: haloColor, radius: 10, x: 0, y: 1)

            MomentsMeter(unlocked: unlocked, tint: chapter.tint, isDark: isDark)
        }
    }

    /// Dewy and the first companion standing grounded on the chapter panorama's mossy foreground ledge.
    private func travellers(isDark: Bool) -> some View {
        let size: CGFloat = 128
        let height = size * DewyGeometry.canvas.height / DewyGeometry.canvas.width
        let shadowColor = isDark ? Color(hex: 0x101432).opacity(0.36) : Color(hex: 0x2F4432).opacity(0.24)

        return HStack(alignment: .bottom, spacing: -6) {
            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: size,
                outfits: store.outfits,
                sparkles: store.todayProgress >= 1,
                bands: store.todayBands,
                showsShadow: false,
                isNight: isDark
            )
            .liveMeniscusGlow(strength: 0.12)

            if let friend = store.companions.first {
                FriendView(
                    friend: friend,
                    size: 74,
                    animated: true,
                    isNight: isDark
                )
                .offset(y: 4)
            }
        }
        .background(alignment: .bottom) {
            Ellipse()
                .fill(shadowColor)
                .frame(width: store.companions.isEmpty ? 104 : 174, height: 18)
                .blur(radius: 5)
                .offset(y: 6)
        }
        .frame(height: height, alignment: .bottom)
        .offset(y: -height * 0.5 + 6)
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
        .padding(.bottom, 128)
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
            .dewyCard(padding: 18, glow: chapter.tint)
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
                    ClayIcon(glyph: .chest, size: 48)
                    Text("Reach your goal and every place Dewy visits will be kept here like a postcard.")
                        .font(.editorialItalic(14.5))
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
                    .padding(.bottom, 14)
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

/// Four antique-brass wax seal tokens that illuminate as the chapter's story unfolds.
private struct MomentsMeter: View {
    var unlocked: Int
    var tint: Color
    var isDark: Bool

    var body: some View {
        let labelInk: Color = isDark ? Ink.starlight.opacity(0.90) : Ink.primary.opacity(0.80)
        let unlitFill: Color = isDark ? Ink.starlight.opacity(0.18) : Palette.paper.opacity(0.84)
        let unlitInk: Color = isDark ? Ink.starlight.opacity(0.70) : Ink.soft

        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                let lit = index < unlocked
                ZStack {
                    Circle()
                        .fill(lit ? Palette.butter : unlitFill)
                    if lit {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(Palette.paper)
                    } else {
                        Text("\(index + 1)")
                            .font(.dewy(11.5, .bold))
                            .monospacedDigit()
                            .foregroundStyle(unlitInk)
                    }
                }
                .frame(width: 26, height: 26)
                .overlay {
                    Circle().stroke(
                        lit ? Palette.butterDeep.opacity(0.55) : (isDark ? Ink.starlight.opacity(0.28) : Ink.hairlineStrong),
                        lineWidth: 1.2
                    )
                }
                .shadow(color: Palette.shadow.opacity(lit ? 0.22 : 0.08), radius: 3, x: 0, y: 1.5)
                .scaleEffect(lit ? 1 : 0.92)
            }

            Text(unlocked == 4 ? "Chapter complete" : "\(unlocked) of 4 moments")
                .font(.dewy(13, .bold))
                .foregroundStyle(labelInk)
                .padding(.leading, 4)
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.72), value: unlocked)
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
    private var inkAccent: Color { tint.blended(with: Ink.primary, by: 0.36) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? inkAccent : theme.well)
                    if isUnlocked {
                        Text("\(index + 1)")
                            .font(.display(15, .bold))
                            .foregroundStyle(Palette.paper)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Ink.faint)
                    }
                }
                .frame(width: 32, height: 32)
                .overlay {
                    Circle().stroke(isUnlocked ? inkAccent.opacity(0.35) : Ink.hairline, lineWidth: 1.2)
                }

                if !isLast {
                    Capsule()
                        .fill(isUnlocked ? inkAccent.opacity(0.35) : theme.line)
                        .frame(width: 2.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 5)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    CapsLabel(text: "At \(milestone)%", color: isUnlocked ? inkAccent : Ink.faint, size: 10.5)
                    Spacer(minLength: 0)
                    HStack(spacing: 3) {
                        ClayIcon(glyph: .drop, size: 13)
                        Text("+\(DropRules.perBeat)")
                            .font(.dewy(12.5, .bold))
                            .monospacedDigit()
                            .foregroundStyle(isUnlocked ? Palette.coralDeep : Ink.faint)
                    }
                    .opacity(isUnlocked ? 1 : 0.65)
                }

                if isUnlocked {
                    Text(text)
                        .font(.editorialItalic(16))
                        .lineSpacing(3)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .topLeading)))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule().fill(theme.well).frame(height: 8)
                        Capsule().fill(theme.well).frame(width: 148, height: 8)
                    }
                    .padding(.top, 5)
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
        let size: CGFloat = isHere ? 94 : 74
        let isDark = chapter == .grove || chapter == .lake

        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                JourneySceneView(chapter: chapter, animated: false)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .saturation(state == .ahead ? 0.25 : 1)
                    .opacity(state == .ahead ? 0.72 : 1)
                    .overlay(Circle().stroke(Palette.paper, lineWidth: isHere ? 3.5 : 2.5))
                    .overlay(Circle().stroke(isHere ? Palette.aqua : Ink.hairlineStrong, lineWidth: isHere ? 1.5 : 1))
                    .shadow(color: Palette.shadow.opacity(isHere ? 0.18 : 0.10), radius: isHere ? 10 : 5, x: 0, y: isHere ? 5 : 3)

                if isHere {
                    MascotView(
                        progress: progress,
                        mood: mood,
                        size: 38,
                        outfits: outfits,
                        bands: bands,
                        animated: false,
                        showsShadow: false,
                        isNight: isDark
                    )
                    .offset(y: 10)
                }

                if state == .visited {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Palette.paper)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Palette.mint))
                        .overlay(Circle().stroke(Palette.paper, lineWidth: 2))
                        .offset(x: size * 0.34, y: -size * 0.68)
                }

                if state == .ahead {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.paper)
                        .shadow(color: Ink.primary.opacity(0.35), radius: 3)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: size, height: size)

            VStack(spacing: 1) {
                Text(chapter.title)
                    .font(.display(isHere ? 14 : 12.5, .semibold))
                    .foregroundStyle(state == .ahead ? Ink.soft : Ink.primary)
                    .lineLimit(1)
                Text(isHere ? "You are here" : "Stop \(number)")
                    .font(.dewy(10.5, .bold))
                    .foregroundStyle(isHere ? Palette.aquaDeep : Ink.faint)
            }
            .frame(width: 100)
        }
        .frame(height: 148, alignment: .bottom)
    }
}

/// Dotted botanical ink stepping path between trail medallions.
private struct TrailDots: View {
    var done: Bool

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(done ? Palette.aqua.opacity(0.7) : Color(hex: 0xDFD3C3))
                    .frame(width: 5.5, height: 5.5)
            }
        }
        .frame(width: 22)
        .padding(.bottom, 58)
        .frame(height: 148, alignment: .center)
    }
}

// MARK: - Archive

private struct ArchiveCard: View {
    var stop: JourneyStop
    var locked: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            JourneySceneView(chapter: stop.chapter, animated: false)
                .frame(width: 128, height: 164)
                .blur(radius: locked ? 5 : 0)
                .saturation(locked ? 0.55 : 1)

            LinearGradient(
                colors: [.clear, Color(hex: 0x1E1826).opacity(0.58)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(stop.chapter.title)
                    .font(.display(15, .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(stop.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.dewy(11.5, .bold))
                    .opacity(0.88)
            }
            .foregroundStyle(Ink.starlight)
            .padding(12)

            if locked {
                VStack(spacing: 6) {
                    ClayIcon(glyph: .crown, size: 32)
                    PlusBadge()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 128, height: 164)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Palette.paper, lineWidth: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Ink.hairlineStrong, lineWidth: 1)
        }
        .shadow(color: Palette.shadow.opacity(0.14), radius: 10, x: 0, y: 5)
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

    private var accentColor: Color {
        challenge.tint.blended(with: Ink.primary, by: 0.14)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(systemImage: challenge.symbol, color: accentColor, size: 46, filled: false)

                VStack(alignment: .leading, spacing: 3) {
                    Text(challenge.title)
                        .font(.display(19, .semibold))
                        .foregroundStyle(theme.ink)
                    Text(stateLine)
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                // Live vector wardrobe reward preview plus Dew Drops bonus.
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(challenge.reward.tint.opacity(0.18))
                            .overlay(Circle().stroke(Ink.hairline, lineWidth: 1))
                            .frame(width: 58, height: 58)
                        OutfitArtView(outfit: challenge.reward, size: 54)
                    }
                    HStack(spacing: 3) {
                        ClayIcon(glyph: .drop, size: 13)
                        Text("+\(DropRules.challenge)")
                            .font(.dewy(11.5, .bold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.coralDeep)
                    }
                }
            }

            HStack(spacing: 12) {
                ChallengeDays(progress: progress, tint: accentColor)
                Spacer(minLength: 0)
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.dewy(14, .bold))
                        .foregroundStyle(buttonIsQuiet ? theme.ink : Palette.paper)
                        .padding(.horizontal, 18)
                        .frame(height: 36)
                }
                .buttonStyle(
                    StampButtonStyle(
                        fill: buttonIsQuiet ? Palette.paper : accentColor,
                        lip: buttonIsQuiet ? Color(hex: 0xDDD0BF) : accentColor.blended(with: Ink.primary, by: 0.25),
                        depth: 3
                    )
                )
            }
        }
        .dewyCard(padding: 16, glow: progress.state == .notStarted ? nil : challenge.tint)
        .overlay(alignment: .topLeading) {
            if progress.state == .completed {
                StoryBadge(text: "Done", systemImage: "checkmark", tint: Palette.leafDeep, soft: Palette.mintSoft)
                    .offset(x: 14, y: -11)
            }
        }
    }

    private var buttonIsQuiet: Bool { progress.state == .active }
}

/// Matte hand-inked gouache progress beads, one per day of the challenge.
private struct ChallengeDays: View {
    var progress: ChallengeProgress
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<progress.total, id: \.self) { day in
                let done = day < progress.daysDone
                Capsule()
                    .fill(done ? tint : Palette.creamDeep)
                    .overlay {
                        Capsule().stroke(
                            done ? tint.blended(with: Ink.primary, by: 0.28).opacity(0.45) : Ink.hairline,
                            lineWidth: 1
                        )
                    }
                    .frame(width: 18, height: 10)
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
            ArtImage(name: "badge-\(badge.rawValue)", fallback: badge.symbol, tint: badge.tint, size: 70)
                .saturation(unlocked ? 1 : 0)
                .opacity(unlocked ? 1 : 0.36)
                .overlay(alignment: .bottomTrailing) {
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(Palette.paper)
                            .frame(width: 21, height: 21)
                            .background(Circle().fill(Ink.soft))
                            .overlay(Circle().stroke(Palette.paper, lineWidth: 1.5))
                    }
                }

            Text(badge.title)
                .font(.display(13, .semibold))
                .foregroundStyle(unlocked ? theme.ink : theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background {
            PaperSurface(
                shape: RoundedRectangle(cornerRadius: 22, style: .continuous),
                fill: unlocked ? Palette.paper : Palette.parchment,
                tint: unlocked ? badge.tint : Palette.shadow,
                elevation: unlocked ? 0.75 : 0.3
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
            Capsule().fill(Ink.faint.opacity(0.5)).frame(width: 38, height: 4.5).padding(.top, 10)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [badge.tint.opacity(unlocked ? 0.28 : 0.10), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 105
                        )
                    )
                    .frame(width: 210, height: 210)
                ArtImage(name: "badge-\(badge.rawValue)", fallback: badge.symbol, tint: badge.tint, size: 146)
                    .saturation(unlocked ? 1 : 0)
                    .opacity(unlocked ? 1 : 0.42)
                    .scaleEffect(pop ? 1 : 0.65)
                    .rotationEffect(.degrees(pop ? 0 : -10))
            }
            .frame(height: 168)

            VStack(spacing: 6) {
                Text(badge.title)
                    .font(.display(26, .bold))
                    .foregroundStyle(Ink.primary)
                Text(badge.detail)
                    .font(.editorialItalic(16))
                    .foregroundStyle(Ink.soft)
                    .multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    ClayIcon(glyph: .drop, size: 15)
                    Text(unlocked ? "Earned \(DropRules.badge) drops" : "Worth \(DropRules.badge) drops")
                        .font(.dewy(13.5, .bold))
                        .foregroundStyle(Palette.coralDeep)
                }
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Palette.coralSoft, in: Capsule())
                .overlay(Capsule().stroke(Palette.coral.opacity(0.25), lineWidth: 1))
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 0)

            PrimaryButton(title: unlocked ? "Wonderful!" : "Keep going", style: unlocked ? .accent : .light, height: 54) {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { pop = true }
            if unlocked { Haptics.success() }
        }
    }
}
