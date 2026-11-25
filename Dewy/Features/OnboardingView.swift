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
            DreamyBackground()

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
                CircleIconButton(systemImage: "chevron.left", size: 38) { goBack() }
                    .transition(.scale.combined(with: .opacity))
                HStack(spacing: 6) {
                    ForEach(1...lastStep, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.inkSoft.opacity(0.18)))
                            .frame(width: index == step ? 30 : 10, height: 10)
                    }
                }
                .frame(maxWidth: .infinity)
                Color.clear.frame(width: 38, height: 38)
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
            MascotView(progress: 0.55, mood: .happy, size: 210, bounceTrigger: bounce)
                .onTapGesture { bounce += 1; Haptics.tap() }
            VStack(spacing: 10) {
                Text("Meet Dewy")
                    .font(.dewy(44, .black))
                    .foregroundStyle(theme.ink)
                Text("Your tiny hydration buddy.\nDrink water, keep Dewy happy, grow a garden.")
                    .font(.dewy(17, .medium))
                    .foregroundStyle(theme.inkSoft)
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

    private func pill(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Text(emoji)
                .font(.system(size: 13))
            Text(text)
                .font(.dewy(13, .bold))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
        }
        .fixedSize()
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
    }

    private var nameStep: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 0)
            MascotView(progress: 0.35, mood: .okay, size: 130)
            stepTitle("What should Dewy call you?", subtitle: "A little name makes reminders feel friendlier.")
            TextField("Your name", text: $draft.name)
                .font(.dewy(24, .bold))
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($nameFocused)
                .onSubmit { advance() }
                .frame(height: 64)
                .glassCard(padding: 0, radius: 32)
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
                        .font(.dewy(72, .black))
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
            .glassCard(padding: 22)
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
                Text("Where you live")
                    .font(.dewy(15, .bold))
                    .foregroundStyle(theme.inkSoft)
                HStack(spacing: 8) {
                    ForEach(Climate.allCases) { climate in
                        ChipButton(title: "\(climate.emoji) \(climate.title)", isSelected: draft.climate == climate) {
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
                Divider().overlay(theme.inkSoft.opacity(0.15))
                scheduleRow(emoji: "🌙", title: "I go to bed at", minutes: $draft.sleepMinutes)
            }
            .glassCard(padding: 20)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private func scheduleRow(emoji: String, title: String, minutes: Binding<Int>) -> some View {
        HStack {
            Text(emoji)
                .font(.system(size: 26))
                .frame(width: 50, height: 50)
                .background(theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(title)
                .font(.dewy(17, .bold))
                .foregroundStyle(theme.ink)
            Spacer()
            DatePicker(title, selection: minutes.timeOfDay, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    private var goalStep: some View {
        let progress = draft.dailyGoal > 0 ? revealedGoal / draft.dailyGoal : 0
        return VStack(spacing: 18) {
            Spacer(minLength: 0)
            Text("YOUR DAILY GOAL")
                .font(.dewy(14, .heavy))
                .tracking(1.5)
                .foregroundStyle(theme.accent)
            MascotView(progress: progress, mood: DewyMood(progress: progress), size: 150, bounceTrigger: bounce)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(format(revealedGoal))
                    .font(.dewy(64, .black))
                    .foregroundStyle(theme.ink)
                    .contentTransition(.numericText(value: revealedGoal))
                Text(draft.unit.label)
                    .font(.dewy(24, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            HStack(spacing: 18) {
                adjustButton("minus") { draft.dailyGoal = max(800, draft.dailyGoal - draft.unit.step) }
                Text("Tap to adjust")
                    .font(.dewy(14, .semibold))
                    .foregroundStyle(theme.inkSoft)
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
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(theme.ink)
                .frame(width: 46, height: 46)
                .background(theme.card, in: Circle())
                .overlay(Circle().strokeBorder(theme.cardStroke, lineWidth: 1))
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.dewy(30, .heavy))
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.dewy(16, .medium))
                .foregroundStyle(theme.inkSoft)
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
                    .background(theme.accent.opacity(isSelected ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.dewy(17, .bold))
                        .foregroundStyle(theme.ink)
                    Text(subtitle)
                        .font(.dewy(13, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.accent : theme.inkSoft.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.card)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.cardStroke), lineWidth: isSelected ? 2 : 1)
            }
            .scaleEffect(isSelected ? 1.015 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}
