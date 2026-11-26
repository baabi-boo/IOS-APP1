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
            GeometryReader { proxy in
                WorldScene(horizon: proxy.size.height * 0.78, sunPosition: CGPoint(x: 0.82, y: 130))
            }
            .ignoresSafeArea()

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

                PrimaryButton(title: buttonTitle, systemImage: step == lastStep ? "drop.fill" : "arrow.right", style: .light, isLoading: isFinishing) {
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
                            .fill(Color.white.opacity(index <= step ? 1 : 0.35))
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
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                // Dewy and two friends float in on fluffy clouds.
                cloudy(.sunny, size: 70)
                    .offset(x: -122, y: -6)
                cloudy(.berry, size: 70)
                    .offset(x: 122, y: -14)
                VStack(spacing: -30) {
                    MascotView(progress: 0.62, mood: .happy, size: 210, bounceTrigger: bounce, bands: welcomeBands, showsShadow: false)
                        .onTapGesture { bounce += 1; Haptics.tap() }
                        .zIndex(1)
                    CloudPuff()
                        .fill(LinearGradient(colors: [.white, theme.cloudShade], startPoint: .top, endPoint: .bottom))
                        .frame(width: 250, height: 74)
                }
            }
            .frame(height: 330)
            VStack(spacing: 10) {
                Text("Meet Dewy")
                    .font(.display(56))
                    .foregroundStyle(.white)
                    .shadow(color: theme.sky[0].opacity(0.45), radius: 0, x: 0, y: 4)
                Text("Your tiny hydration buddy.\nEvery drink you log fills Dewy up.")
                    .font(.display(19, .medium))
                    .foregroundStyle(theme.onHeroSoft)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 6) {
                pill("drop.fill", "Track sips")
                pill("camera.macro", "Grow a garden")
                pill("bell.fill", "Reminders")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private func cloudy(_ friend: DewyFriend, size: CGFloat) -> some View {
        VStack(spacing: -12) {
            MascotView(progress: 0.74, mood: friend.mood, size: size, accessory: friend.accessory, liquid: friend.liquid, showsShadow: false)
                .zIndex(1)
            CloudPuff()
                .fill(LinearGradient(colors: [.white, theme.cloudShade], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 1.25, height: size * 0.36)
        }
    }

    private var welcomeBands: [LiquidBand] {
        [
            LiquidBand(color: DrinkKind.water.color, upTo: 0.22),
            LiquidBand(color: DrinkKind.coffee.color, upTo: 0.32),
            LiquidBand(color: DrinkKind.juice.color, upTo: 0.44),
            LiquidBand(color: DrinkKind.water.color, upTo: 0.62)
        ]
    }

    private func pill(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .heavy))
            Text(text)
                .font(.display(14))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .fixedSize()
        .padding(.horizontal, 11)
        .frame(height: 34)
        .background(Color.white.opacity(0.22), in: Capsule())
    }

    /// A chip that sits on the sky.
    private func skyChip(_ symbol: String, _ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 13, weight: .heavy))
                Text(title).font(.display(16))
            }
            .foregroundStyle(isSelected ? (theme.isDark ? Palette.ink : theme.accent) : Color.white)
            .padding(.horizontal, 15)
            .frame(height: 42)
        }
        .buttonStyle(CandyButtonStyle(
            fill: isSelected ? .white : Color.white.opacity(0.22),
            lip: isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.1),
            depth: 3
        ))
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            MascotView(progress: 0.35, mood: .okay, size: 140, accessory: .hearts, showsShadow: false)
            stepTitle("What should Dewy call you?", subtitle: "A little name makes reminders feel friendlier.")
            TextField("Your name", text: $draft.name)
                .font(.display(26))
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
        return VStack(spacing: 24) {
            Spacer(minLength: 0)
            stepTitle("How much do you weigh?", subtitle: "Dewy uses this to find your perfect daily goal.")
            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(displayWeight.rounded()))")
                        .font(.display(78))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: displayWeight.rounded()))
                        .animation(.snappy, value: displayWeight.rounded())
                    Text(draft.usesPounds ? "lb" : "kg")
                        .font(.display(26))
                        .foregroundStyle(theme.inkSoft)
                }
                AmountSlider(value: $draft.weightKg, range: 30...160, step: 0.5, tint: theme.accent, lip: theme.accentDeep, unitName: "kilograms")
                HStack(spacing: 8) {
                    ChipButton(title: "kg · ml", isSelected: !draft.usesPounds) {
                        Haptics.select()
                        withAnimation(.spring) { draft.usesPounds = false; draft.unit = .ml }
                    }
                    ChipButton(title: "lb · oz", isSelected: draft.usesPounds) {
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
                    OptionCard(symbol: level.symbol, tint: level.tint, title: level.title, subtitle: level.subtitle, isSelected: draft.activity == level) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { draft.activity = level }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                CapsLabel(text: "Where you live", color: theme.onHeroSoft, size: 12)
                HStack(spacing: 8) {
                    ForEach(Climate.allCases) { climate in
                        skyChip(climate.symbol, climate.title, isSelected: draft.climate == climate) {
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
            MascotView(progress: 0.5, mood: .okay, size: 120, accessory: .nightcap, showsShadow: false)
            stepTitle("When does your day happen?", subtitle: "Reminders only arrive while you're awake.")
            VStack(spacing: 14) {
                scheduleRow(symbol: "sun.max.fill", tint: Palette.tangerine, title: "I wake up at", minutes: $draft.wakeMinutes)
                Rectangle().fill(theme.line).frame(height: 1.5)
                scheduleRow(symbol: "moon.stars.fill", tint: Palette.grape, title: "I go to bed at", minutes: $draft.sleepMinutes)
            }
            .dewyCard(padding: 20)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private func scheduleRow(symbol: String, tint: Color, title: String, minutes: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            IconTile(systemImage: symbol, color: tint, size: 46)
            Text(title)
                .font(.display(18))
                .foregroundStyle(theme.ink)
            Spacer()
            DatePicker(title, selection: minutes.timeOfDay, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    private var goalStep: some View {
        let progress = draft.dailyGoal > 0 ? revealedGoal / draft.dailyGoal : 0
        return VStack(spacing: 14) {
            Spacer(minLength: 0)
            Text("Your daily goal")
                .font(.display(16))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(Color.white.opacity(0.22), in: Capsule())
            VStack(spacing: -24) {
                MascotView(progress: progress, mood: DewyMood(progress: progress), size: 170, bounceTrigger: bounce, showsShadow: false)
                    .zIndex(1)
                CloudPuff()
                    .fill(LinearGradient(colors: [.white, theme.cloudShade], startPoint: .top, endPoint: .bottom))
                    .frame(width: 210, height: 62)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(format(revealedGoal))
                    .font(.display(76))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: revealedGoal))
                Text(draft.unit.label)
                    .font(.display(28))
                    .foregroundStyle(theme.onHeroSoft)
            }
            .shadow(color: theme.sky[0].opacity(0.45), radius: 0, x: 0, y: 4)
            HStack(spacing: 18) {
                adjustButton("minus") { draft.dailyGoal = max(800, draft.dailyGoal - draft.unit.step) }
                Text("Tap to adjust")
                    .font(.display(16, .medium))
                    .foregroundStyle(theme.onHeroSoft)
                adjustButton("plus") { draft.dailyGoal = min(6_000, draft.dailyGoal + draft.unit.step) }
            }
            HStack(spacing: 8) {
                pill("scalemass.fill", "\(Int((draft.usesPounds ? draft.weightKg * 2.20462 : draft.weightKg).rounded())) \(draft.usesPounds ? "lb" : "kg")")
                pill(draft.activity.symbol, draft.activity.title)
                pill(draft.climate.symbol, draft.climate.title)
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
                .foregroundStyle(theme.isDark ? Palette.ink : theme.accent)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(CandyButtonStyle(fill: .white, lip: Color.white.opacity(0.6), shape: AnyShape(Circle()), depth: 4))
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.display(32))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: theme.sky[0].opacity(0.35), radius: 0, x: 0, y: 3)
            Text(subtitle)
                .font(.display(17, .medium))
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
            SoundFX.play(.goal, volume: 0.5)
            store.completeOnboarding(with: profile)
            isFinishing = false
        }
    }
}

private struct OptionCard: View {
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
                IconTile(systemImage: symbol, color: tint, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.display(18))
                        .foregroundStyle(theme.ink)
                    Text(subtitle)
                        .font(.dewy(13, .semibold))
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
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 3)
            }
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? theme.accentDeep : Color.black.opacity(0.08))
                    .offset(y: 4)
            }
            .padding(.bottom, 4)
            .scaleEffect(isSelected ? 1.015 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}
