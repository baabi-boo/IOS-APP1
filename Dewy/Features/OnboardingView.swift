import SwiftUI

/// First launch: meet Dewy, answer four quick questions and receive a personalized daily goal.
///
/// Steps (indices are stable because the screenshot script launches `-step N`):
/// 0 welcome · 1 name · 2 weight · 3 lifestyle · 4 schedule & reminders · 5 goal
struct OnboardingView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme

    @State private var step: Int = LaunchOptions.onboardingStep ?? 0
    @State private var forward = true
    @State private var draft: UserProfile = {
        var profile = UserProfile()
        if LaunchOptions.isDemo { profile.name = "Mira" }
        return profile
    }()
    @State private var revealedGoal: Double = 0
    @State private var bounce = 0
    @State private var isFinishing = false
    @State private var appeared = LaunchOptions.freezesMotion
    @FocusState private var nameFocused: Bool

    private let lastStep = 5
    /// The goal at which the gauge ring is full.
    private let gaugeMax: Double = 4_000

    var body: some View {
        ZStack {
            theme.canvas.ignoresSafeArea()

            if step == 0 {
                welcomeLayer
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .offset(x: -56))
                    ))
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .frame(height: 54)

                ZStack {
                    stepContent
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                PrimaryButton(
                    title: buttonTitle,
                    systemImage: step == lastStep ? "drop.fill" : "arrow.right",
                    style: .accent,
                    isLoading: isFinishing
                ) {
                    advance()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            if step == lastStep {
                draft.dailyGoal = draft.recommendedGoal
                revealGoal()
            }
            if !appeared {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.1))
                    appeared = true
                }
            }
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0: "Let's begin"
        case lastStep: "Start sipping"
        default: "Continue"
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            if step > 0 {
                CircleIconButton(systemImage: "chevron.left", size: 38) { goBack() }
                    .transition(.scale.combined(with: .opacity))
                OnbProgressDots(current: step, total: lastStep)
                    .frame(maxWidth: .infinity)
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: step)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: welcomeText
        case 1: nameStep
        case 2: weightStep
        case 3: lifestyleStep
        case 4: scheduleStep
        default: goalStep
        }
    }

    // MARK: Welcome

    /// Live dawn lagoon panorama with Dewy and two live animated companions.
    private var welcomeLayer: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .top) {
                heroScene(size: size)
                welcomeStage
                    .frame(width: min(size.width, 360), height: 290)
                    .position(x: size.width / 2, y: size.height * 0.59 - 140)
            }
            .frame(width: size.width, height: size.height, alignment: .top)
        }
        .ignoresSafeArea()
    }

    private func heroScene(size: CGSize) -> some View {
        OnboardingPanoramaView()
            .frame(width: size.width, height: size.height * 0.65)
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.72),
                        .init(color: .black.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var welcomeStage: some View {
        ZStack(alignment: .bottom) {
            LilyPad(width: 172, rippleTrigger: bounce)

            FriendView(friend: .cat, size: 70, animated: true, celebrateTrigger: bounce)
                .offset(x: -118, y: -26)
            FriendView(friend: .bunny, size: 70, animated: true, celebrateTrigger: bounce)
                .scaleEffect(x: -1, y: 1)
                .offset(x: 118, y: -30)

            MascotView(
                progress: 0.62,
                mood: .happy,
                size: 196,
                bounceTrigger: bounce,
                bands: welcomeBands,
                showsShadow: false
            )
            .liveMeniscusGlow(strength: 0.13)
            .padding(.bottom, 22)
            .contentShape(Rectangle())
            .onTapGesture {
                bounce += 1
                Haptics.tap()
            }
        }
        .scaleEffect(appeared ? 1 : 0.92, anchor: .bottom)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.58, dampingFraction: 0.76), value: appeared)
    }

    private var welcomeBands: [LiquidBand] {
        [
            LiquidBand(color: DrinkKind.water.color, upTo: 0.22),
            LiquidBand(color: DrinkKind.coffee.color, upTo: 0.32),
            LiquidBand(color: DrinkKind.juice.color, upTo: 0.44),
            LiquidBand(color: DrinkKind.water.color, upTo: 0.62)
        ]
    }

    private var welcomeText: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            CapsLabel(text: "Your hydration companion", color: Palette.aquaDeep, size: 11)
                .floatIn(appeared, index: 1)
            Text("Meet Dewy")
                .font(.display(50, .bold))
                .tracking(-0.8)
                .foregroundStyle(theme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .floatIn(appeared, index: 2)
            Text("Every sip you log fills him up — and carries you through a living storybook.")
                .font(.editorialItalic(17))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .floatIn(appeared, index: 3)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Question pages

    private func questionPage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                content()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }

    private func titleBlock(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.display(30, .bold))
                .tracking(-0.4)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.editorialItalic(16))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Miniature Dewy reacting to each step's answer.
    private func reactingDewy(progress: Double, mood: DewyMood, outfits: [Outfit] = [], sparkles: Bool = false) -> some View {
        MascotView(progress: progress, mood: mood, size: 102, bounceTrigger: bounce, outfits: outfits, sparkles: sparkles)
            .contentShape(Rectangle())
            .onTapGesture {
                bounce += 1
                Haptics.tap()
            }
    }

    // MARK: Name

    private var nameStep: some View {
        let hasName = !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        return questionPage {
            reactingDewy(progress: hasName ? 0.55 : 0.35, mood: hasName ? .happy : .okay, sparkles: hasName)
            titleBlock("What should Dewy call you?", subtitle: "A familiar name makes reminders feel warmer.")
            TextField("Your name", text: $draft.name)
                .font(.display(26, .semibold))
                .foregroundStyle(theme.ink)
                .tint(theme.accent)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($nameFocused)
                .onSubmit { advance() }
                .frame(height: 64)
                .padding(.horizontal, 20)
                .background {
                    PaperSurface(shape: Capsule(), fill: Palette.paper, tint: nameFocused ? theme.accent : Palette.shadow)
                }
                .overlay {
                    Capsule().strokeBorder(nameFocused ? theme.accent.opacity(0.65) : Color.clear, lineWidth: 2)
                }
            if hasName {
                Text("Nice to meet you, \(draft.name.trimmingCharacters(in: .whitespaces))!")
                    .font(.editorialItalic(17))
                    .foregroundStyle(theme.accentDeep)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: hasName)
        .onChange(of: hasName) { _, newValue in
            if newValue { bounce += 1 }
        }
        .onAppear {
            if !LaunchOptions.isDemo { nameFocused = true }
        }
    }

    // MARK: Weight

    private var displayWeight: Double {
        draft.usesPounds ? draft.weightKg * 2.20462 : draft.weightKg
    }

    private var unitBinding: Binding<VolumeUnit> {
        Binding(
            get: { draft.unit },
            set: { newValue in
                draft.unit = newValue
                draft.usesPounds = newValue == .oz
            }
        )
    }

    private var weightStep: some View {
        let fill = 0.25 + 0.6 * min(max((draft.weightKg - 30) / 130, 0), 1)
        return questionPage {
            reactingDewy(progress: fill, mood: .okay)
            titleBlock("How much do you weigh?", subtitle: "Dewy uses this to tailor your daily hydration target.")
            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(displayWeight.rounded()))")
                        .font(.display(72, .bold))
                        .foregroundStyle(theme.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: displayWeight.rounded()))
                        .animation(.snappy, value: displayWeight.rounded())
                    Text(draft.usesPounds ? "lb" : "kg")
                        .font(.display(24, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                AmountSlider(value: $draft.weightKg, range: 30...160, step: 0.5, tint: theme.accent, lip: theme.accentDeep, unitName: "kilograms")
                StorySegmented(items: VolumeUnit.allCases, selection: unitBinding) { unit in
                    unit == .ml ? "kg · ml" : "lb · oz"
                }
            }
            .dewyCard(padding: 22)
        }
    }

    // MARK: Lifestyle

    private var lifestyleOutfits: [Outfit] {
        switch draft.climate {
        case .cool: [.beanie, .scarf]
        case .mild: [.leafhat]
        case .hot: [.strawhat]
        }
    }

    private var activityFill: Double {
        switch draft.activity {
        case .chill: 0.35
        case .active: 0.55
        case .athlete: 0.8
        }
    }

    private var lifestyleStep: some View {
        questionPage {
            reactingDewy(progress: activityFill, mood: draft.activity == .athlete ? .happy : .okay, outfits: lifestyleOutfits)
            titleBlock("How's your rhythm?", subtitle: "Active days and warm weather call for extra sips.")
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases) { level in
                    OnbChoiceCard(
                        symbol: level.symbol,
                        tint: level.tint,
                        title: level.title,
                        subtitle: level.subtitle,
                        isSelected: draft.activity == level
                    ) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { draft.activity = level }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Where you live")
                HStack(spacing: 12) {
                    ForEach(Climate.allCases) { climate in
                        OnbClimateTile(
                            symbol: climate.symbol,
                            tint: climate.tint,
                            title: climate.title,
                            isSelected: draft.climate == climate
                        ) {
                            Haptics.select()
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { draft.climate = climate }
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .onChange(of: draft.climate) { bounce += 1 }
        .onChange(of: draft.activity) { bounce += 1 }
    }

    // MARK: Schedule & reminders

    private var scheduleStep: some View {
        questionPage {
            reactingDewy(progress: 0.5, mood: .okay, outfits: [.beanie])
            titleBlock("When does your day happen?", subtitle: "Reminders only arrive while you're awake.")
            VStack(spacing: 14) {
                scheduleRow(symbol: "sun.max.fill", tint: Palette.tangerine, title: "I wake up at", minutes: $draft.wakeMinutes)
                Rectangle().fill(theme.line).frame(height: 1)
                scheduleRow(symbol: "moon.stars.fill", tint: Palette.lilac, title: "I go to bed at", minutes: $draft.sleepMinutes)
            }
            .dewyCard(padding: 20)
            HStack(spacing: 14) {
                ClayIcon(glyph: .bell, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Gentle reminders")
                        .font(.display(17, .semibold))
                        .foregroundStyle(theme.ink)
                    Text("Dewy will nudge you every couple of hours. You can adjust this anytime.")
                        .font(.dewy(13.5, .medium))
                        .foregroundStyle(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .dewyCard(padding: 18)
        }
    }

    private func scheduleRow(symbol: String, tint: Color, title: String, minutes: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            IconTile(systemImage: symbol, color: tint, size: 44, filled: false)
            Text(title)
                .font(.display(17.5, .semibold))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            DatePicker(title, selection: timeBinding(minutes), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(theme.accent)
        }
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding<Date>(
            get: {
                let value = minutes.wrappedValue
                return Calendar.current.date(bySettingHour: value / 60 % 24, minute: value % 60, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }

    // MARK: Goal

    private var goalStep: some View {
        questionPage {
            titleBlock("Your daily goal", subtitle: goalSubtitle)
            goalGauge
                .padding(.top, 4)
            goalAdjuster
            summaryRow
            healthCard
        }
    }

    private var goalSubtitle: String {
        let name = draft.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Tuned to your body, rhythm and climate." : "Tuned just for you, \(name)."
    }

    private var goalGauge: some View {
        let ring = min(max(revealedGoal / gaugeMax, 0), 1)
        let fill = draft.dailyGoal > 0 ? min(max(revealedGoal / draft.dailyGoal, 0), 1) : 0
        return ZStack {
            PaperSurface(shape: Circle(), fill: Palette.paper, tint: theme.accent, elevation: 0.85)
            Circle()
                .stroke(theme.well, lineWidth: 16)
                .padding(22)
            Circle()
                .trim(from: 0, to: ring)
                .stroke(
                    LinearGradient(colors: [Palette.aquaLight, theme.accent], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(22)
            MascotView(progress: fill, mood: DewyMood(progress: fill), size: 126, bounceTrigger: bounce, showsShadow: false)
                .liveMeniscusGlow(strength: 0.12)
                .offset(y: 4)
        }
        .frame(width: 262, height: 262)
    }

    private var goalAdjuster: some View {
        HStack(spacing: 16) {
            adjustButton("minus") { draft.dailyGoal = max(800, draft.dailyGoal - draft.unit.step) }
            VStack(spacing: -2) {
                Text(format(revealedGoal))
                    .font(.display(52, .bold))
                    .foregroundStyle(theme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: revealedGoal))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(draft.unit.label) a day")
                    .font(.editorialItalic(16))
                    .foregroundStyle(theme.inkSoft)
            }
            .frame(minWidth: 150)
            adjustButton("plus") { draft.dailyGoal = min(6_000, draft.dailyGoal + draft.unit.step) }
        }
    }

    private func adjustButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                action()
                revealedGoal = draft.dailyGoal
            }
            bounce += 1
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.accentDeep)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(StampButtonStyle(fill: Palette.paper, lip: Color(hex: 0xDDD0BF), shape: AnyShape(Circle()), depth: 3))
        .shadow(color: Palette.shadow.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityLabel(icon == "plus" ? "Increase goal" : "Decrease goal")
    }

    private var summaryRow: some View {
        HStack(spacing: 8) {
            summaryPill(symbol: "scalemass.fill", tint: Palette.peach, text: "\(Int(displayWeight.rounded())) \(draft.usesPounds ? "lb" : "kg")")
            summaryPill(symbol: draft.activity.symbol, tint: draft.activity.tint, text: draft.activity.title)
            summaryPill(symbol: draft.climate.symbol, tint: draft.climate.tint, text: draft.climate.title)
        }
    }

    private func summaryPill(symbol: String, tint: Color, text: String) -> some View {
        HStack(spacing: 5) {
            IconTile(systemImage: symbol, color: tint, size: 24, filled: false)
            Text(text)
                .font(.dewy(13, .bold))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
        }
        .fixedSize()
        .padding(.leading, 5)
        .padding(.trailing, 11)
        .frame(height: 34)
        .background {
            PaperSurface(shape: Capsule(), fill: Palette.paper, elevation: 0.4)
        }
    }

    @ViewBuilder
    private var healthCard: some View {
        if HealthSync.isAvailable {
            HStack(spacing: 12) {
                ClayIcon(glyph: .heart, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(.display(17, .semibold))
                        .foregroundStyle(theme.ink)
                    Text("Save every sip to the Health app.")
                        .font(.dewy(12.5, .medium))
                        .foregroundStyle(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                ChipButton(
                    title: draft.healthSyncOn ? "On" : "Connect",
                    isSelected: draft.healthSyncOn,
                    tint: Palette.pink,
                    tintDeep: Palette.berry
                ) {
                    toggleHealth()
                }
                .fixedSize()
            }
            .dewyCard(padding: 16)
        }
    }

    private func toggleHealth() {
        Haptics.select()
        if draft.healthSyncOn {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { draft.healthSyncOn = false }
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { draft.healthSyncOn = true }
        Task { @MainActor in
            let granted = await HealthSync.requestAccess()
            if !granted {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { draft.healthSyncOn = false }
            }
        }
    }

    private func format(_ ml: Double) -> String {
        switch draft.unit {
        case .ml: Int(ml.rounded()).formatted(.number)
        case .oz: Int((ml / VolumeUnit.mlPerOunce).rounded()).formatted(.number)
        }
    }

    // MARK: Navigation

    private func advance() {
        Haptics.tap()
        nameFocused = false
        if step == lastStep {
            finish()
            return
        }
        forward = true
        withAnimation(.spring(response: 0.52, dampingFraction: 0.85)) {
            step += 1
        }
        if step == lastStep {
            draft.dailyGoal = draft.recommendedGoal
            revealGoal()
        }
    }

    private func goBack() {
        Haptics.tap()
        nameFocused = false
        forward = false
        withAnimation(.spring(response: 0.52, dampingFraction: 0.85)) {
            step = max(0, step - 1)
        }
    }

    private func revealGoal() {
        if draft.dailyGoal <= 0 { draft.dailyGoal = draft.recommendedGoal }
        revealedGoal = 0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 1.15, dampingFraction: 0.82)) {
                revealedGoal = draft.dailyGoal
            }
            bounce += 1
            Haptics.success()
        }
    }

    private func finish() {
        guard !isFinishing else { return }
        isFinishing = true
        Task { @MainActor in
            var profile = draft
            profile.remindersOn = await ReminderScheduler.requestPermission()
            Haptics.success()
            SoundFX.play(.goal, volume: 0.5)
            store.completeOnboarding(with: profile)
            isFinishing = false
        }
    }
}

// MARK: - Pieces

/// Matte editorial progress indicator beads, expanding for the active step.
private struct OnbProgressDots: View {
    @Environment(\.dewyTheme) private var theme
    var current: Int
    var total: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(1...max(total, 1), id: \.self) { index in
                dot(isDone: index <= current, isCurrent: index == current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current) of \(total)")
    }

    private func dot(isDone: Bool, isCurrent: Bool) -> some View {
        Capsule()
            .fill(isDone ? theme.accent : theme.well)
            .overlay {
                Capsule().stroke(isDone ? theme.accentDeep.opacity(0.3) : Ink.hairlineStrong, lineWidth: 1)
            }
            .frame(width: isCurrent ? 30 : 10, height: 10)
    }
}

private struct OnbChoiceCard: View {
    @Environment(\.dewyTheme) private var theme
    var symbol: String
    var tint: Color
    var title: String
    var subtitle: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconTile(systemImage: symbol, color: tint, size: 46, filled: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.display(18.5, .semibold))
                        .foregroundStyle(theme.ink)
                    Text(subtitle)
                        .font(.dewy(13.5, .medium))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                OnbCheck(isSelected: isSelected)
            }
            .padding(14)
            .onbChoice(isSelected, radius: 22)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OnbClimateTile: View {
    @Environment(\.dewyTheme) private var theme
    var symbol: String
    var tint: Color
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                IconTile(systemImage: symbol, color: tint, size: 44, filled: false)
                Text(title)
                    .font(.display(16, .semibold))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 102)
            .onbChoice(isSelected, radius: 20)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.96))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OnbCheck: View {
    @Environment(\.dewyTheme) private var theme
    var isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? theme.accent : theme.well)
                .overlay(Circle().stroke(isSelected ? theme.accentDeep.opacity(0.35) : Ink.hairlineStrong, lineWidth: 1.2))
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.paper)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 26, height: 26)
    }
}

private extension View {
    func onbChoice(_ isSelected: Bool, radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background {
                PaperSurface(
                    shape: shape,
                    fill: isSelected ? Palette.aquaSoft.blended(with: Palette.paper, by: 0.65) : Palette.paper,
                    tint: isSelected ? Palette.aqua : Palette.shadow,
                    elevation: isSelected ? 0.85 : 0.55
                )
            }
            .overlay {
                shape.strokeBorder(isSelected ? Palette.aqua : Color.clear, lineWidth: 2)
            }
            .offset(y: isSelected ? -2 : 0)
            .animation(.spring(response: 0.34, dampingFraction: 0.76), value: isSelected)
    }
}
