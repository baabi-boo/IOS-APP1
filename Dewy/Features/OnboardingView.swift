import SwiftUI

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
    @FocusState private var nameFocused: Bool

    private let lastStep = 5

    var body: some View {
        ZStack {
            HeroBackdrop(rays: step == 0 || step == lastStep, rayCenter: UnitPoint(x: 0.5, y: 0.36))

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .frame(height: 52)

                ZStack {
                    stepContent
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                PrimaryButton(title: buttonTitle, systemImage: step == lastStep ? "drop.fill" : "arrow.right", isLoading: isFinishing) {
                    advance()
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            if step == lastStep {
                draft.dailyGoal = draft.recommendedGoal
                revealGoal()
            }
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0: "Let's go"
        case lastStep: "Start sipping"
        default: "Continue"
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            if step > 0 {
                CircleIconButton(systemImage: "chevron.left", size: 40, onHero: true) { goBack() }
                    .transition(.scale.combined(with: .opacity))
                HStack(spacing: 6) {
                    ForEach(1...lastStep, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(index <= step ? 1 : 0.3))
                            .frame(width: index == step ? 30 : 10, height: 10)
                    }
                }
                .frame(maxWidth: .infinity)
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: step)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: welcome
        case 1: nameStep
        case 2: weightStep
        case 3: lifestyleStep
        case 4: scheduleStep
        default: goalStep
        }
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            ZStack {
                HaloRings(diameter: 340)
                MascotView(progress: 0.62, mood: .happy, size: 210, bounceTrigger: bounce, bands: welcomeBands)
                    .onTapGesture { bounce += 1; Haptics.tap() }
                // A couple of Dewy's collectible friends come to say hi.
                friend(.sunny)
                    .offset(x: -128, y: 92)
                friend(.berry)
                    .offset(x: 128, y: 84)
            }
            .frame(height: 300)
            VStack(spacing: 10) {
                Text("Meet Dewy")
                    .font(.dewy(52, .black))
                    .foregroundStyle(.white)
                    .shadow(color: theme.heroDeep.opacity(0.5), radius: 0, x: 0, y: 4)
                Text("Your tiny hydration buddy.\nEvery drink you log fills Dewy up.")
                    .font(.dewy(18, .bold))
                    .foregroundStyle(theme.onHeroSoft)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 6) {
                pill("💧", "Track sips")
                pill("🌸", "Grow flowers")
                pill("🔔", "Reminders")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private func friend(_ friend: DewyFriend) -> some View {
        MascotView(progress: 0.74, mood: friend.mood, size: 64, accessory: friend.accessory, liquid: friend.liquid)
    }

    private var welcomeBands: [LiquidBand] {
        [
            LiquidBand(color: DrinkKind.water.color, upTo: 0.22),
            LiquidBand(color: DrinkKind.coffee.color, upTo: 0.32),
            LiquidBand(color: DrinkKind.juice.color, upTo: 0.44),
            LiquidBand(color: DrinkKind.water.color, upTo: 0.62)
        ]
    }

    private func pill(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Text(emoji)
                .font(.system(size: 13))
            Text(text)
                .font(.dewy(13, .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .fixedSize()
        .padding(.horizontal, 11)
        .frame(height: 34)
        .background(Color.white.opacity(0.2), in: Capsule())
    }

    /// A chip that sits on the hero color.
    private func heroChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.dewy(15, .heavy))
                .foregroundStyle(isSelected ? theme.heroDeep : Color.white)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(isSelected ? Color.white : Color.white.opacity(0.2), in: Capsule())
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private var nameStep: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 0)
            MascotView(progress: 0.35, mood: .okay, size: 130)
            stepTitle("What should Dewy call you?", subtitle: "A little name makes reminders feel friendlier.")
            TextField("Your name", text: $draft.name)
                .font(.dewy(24, .heavy))
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($nameFocused)
                .onSubmit { advance() }
                .frame(height: 66)
                .dewyCard(padding: 0, radius: 33)
            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .onAppear {
            if !LaunchOptions.isDemo { nameFocused = true }
        }
    }

    private var weightStep: some View {
        let displayWeight = draft.usesPounds ? draft.weightKg * 2.20462 : draft.weightKg
        return VStack(spacing: 26) {
            Spacer(minLength: 0)
            stepTitle("How much do you weigh?", subtitle: "Dewy uses this to find your perfect daily goal.")
            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(displayWeight.rounded()))")
                        .font(.dewy(76, .black))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: displayWeight.rounded()))
                        .animation(.snappy, value: displayWeight.rounded())
                    Text(draft.usesPounds ? "lb" : "kg")
                        .font(.dewy(24, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
                Slider(value: $draft.weightKg, in: 30...160, step: 0.5)
                    .tint(theme.accent)
                HStack(spacing: 8) {
                    ChipButton(title: "kg · ml", isSelected: !draft.usesPounds, tint: theme.hero) {
                        Haptics.select()
                        withAnimation(.spring) { draft.usesPounds = false; draft.unit = .ml }
                    }
                    ChipButton(title: "lb · oz", isSelected: draft.usesPounds, tint: theme.hero) {
                        Haptics.select()
                        withAnimation(.spring) { draft.usesPounds = true; draft.unit = .oz }
                    }
                }
            }
            .dewyCard(padding: 22)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private var lifestyleStep: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            stepTitle("How's your lifestyle?", subtitle: "Active days and warm weather need extra sips.")
            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases) { level in
                    OptionCard(emoji: level.emoji, title: level.title, subtitle: level.subtitle, isSelected: draft.activity == level) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { draft.activity = level }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                CapsLabel(text: "Where you live", color: theme.onHeroSoft, size: 12)
                HStack(spacing: 8) {
                    ForEach(Climate.allCases) { climate in
                        heroChip("\(climate.emoji) \(climate.title)", isSelected: draft.climate == climate) {
                            Haptics.select()
                            withAnimation(.spring) { draft.climate = climate }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private var scheduleStep: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            stepTitle("When does your day happen?", subtitle: "Reminders only arrive while you're awake.")
            VStack(spacing: 14) {
                scheduleRow(emoji: "☀️", title: "I wake up at", minutes: $draft.wakeMinutes)
                Divider().overlay(theme.line)
                scheduleRow(emoji: "🌙", title: "I go to bed at", minutes: $draft.sleepMinutes)
            }
            .dewyCard(padding: 20)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private func scheduleRow(emoji: String, title: String, minutes: Binding<Int>) -> some View {
        HStack {
            Text(emoji)
                .font(.system(size: 26))
                .frame(width: 50, height: 50)
                .background(theme.well, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(title)
                .font(.dewy(17, .heavy))
                .foregroundStyle(theme.ink)
            Spacer()
            DatePicker(title, selection: minutes.timeOfDay, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    private var goalStep: some View {
        let progress = draft.dailyGoal > 0 ? revealedGoal / draft.dailyGoal : 0
        return VStack(spacing: 16) {
            Spacer(minLength: 0)
            CapsLabel(text: "Your daily goal", color: .white, size: 14)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.2), in: Capsule())
            ZStack {
                HaloRings(diameter: 250)
                MascotView(progress: progress, mood: DewyMood(progress: progress), size: 150, bounceTrigger: bounce)
            }
            .frame(height: 220)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(format(revealedGoal))
                    .font(.dewy(72, .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: revealedGoal))
                Text(draft.unit.label)
                    .font(.dewy(26, .heavy))
                    .foregroundStyle(theme.onHeroSoft)
            }
            .shadow(color: theme.heroDeep.opacity(0.5), radius: 0, x: 0, y: 4)
            HStack(spacing: 18) {
                adjustButton("minus") { draft.dailyGoal = max(800, draft.dailyGoal - draft.unit.step) }
                Text("Tap to adjust")
                    .font(.dewy(15, .heavy))
                    .foregroundStyle(theme.onHeroSoft)
                adjustButton("plus") { draft.dailyGoal = min(6_000, draft.dailyGoal + draft.unit.step) }
            }
            HStack(spacing: 8) {
                pill("⚖️", "\(Int((draft.usesPounds ? draft.weightKg * 2.20462 : draft.weightKg).rounded())) \(draft.usesPounds ? "lb" : "kg")")
                pill(draft.activity.emoji, draft.activity.title)
                pill(draft.climate.emoji, draft.climate.title)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private func adjustButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                action()
                revealedGoal = draft.dailyGoal
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(theme.heroDeep)
                .frame(width: 50, height: 50)
                .background(Color.white, in: Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.dewy(31, .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.dewy(16, .bold))
                .foregroundStyle(theme.onHeroSoft)
                .multilineTextAlignment(.center)
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
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
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
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            step = max(0, step - 1)
        }
    }

    private func revealGoal() {
        if draft.dailyGoal <= 0 { draft.dailyGoal = draft.recommendedGoal }
        revealedGoal = 0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
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
            store.completeOnboarding(with: profile)
            isFinishing = false
        }
    }
}

private struct OptionCard: View {
    @Environment(\.dewyTheme) private var theme
    var emoji: String
    var title: String
    var subtitle: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 26))
                    .frame(width: 50, height: 50)
                    .background(theme.well, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.dewy(17, .heavy))
                        .foregroundStyle(theme.ink)
                    Text(subtitle)
                        .font(.dewy(13, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? theme.accent : theme.inkSoft.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.card)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? (theme.isDark ? theme.accent : Color(hex: 0x1E2340)) : Color.clear, lineWidth: 3)
            }
            .scaleEffect(isSelected ? 1.015 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}
