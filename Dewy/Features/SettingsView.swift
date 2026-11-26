import SwiftUI
import UIKit

/// The "Me" screen, presented as a sheet from the avatar button on Today.
/// Profile, goal, reminders, worlds, Apple Health, Live Activity, widgets and data.
struct SettingsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    /// This screen is itself a sheet, so it presents the paywall from its own `.sheet`.
    @State private var showPaywall = false
    @State private var confirmErase = false
    @State private var confirmClear = false
    @State private var permissionDenied = false
    @State private var appeared = false
    /// Latest body weight read from Apple Health, in kilograms.
    @State private var healthWeight: Double?

    private struct ReminderInterval {
        let minutes: Int
        let label: String
    }

    private let intervals = [
        ReminderInterval(minutes: 60, label: "1h"),
        ReminderInterval(minutes: 90, label: "1.5h"),
        ReminderInterval(minutes: 120, label: "2h"),
        ReminderInterval(minutes: 180, label: "3h")
    ]

    private static let kgPerPound = 0.45359237

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 26) {
                    Group {
                        profileHero.floatIn(appeared, index: 0)
                        if !purchases.isPremium {
                            plusCard.floatIn(appeared, index: 1)
                        }
                        goalGroup.floatIn(appeared, index: 2)
                        youGroup.floatIn(appeared, index: 3)
                        remindersGroup.floatIn(appeared, index: 4)
                    }
                    Group {
                        worldsSection.floatIn(appeared, index: 5)
                        lockScreenGroup.floatIn(appeared, index: 6).id("widgets")
                        if HealthSync.isAvailable {
                            healthGroup.floatIn(appeared, index: 7)
                        }
                        feelGroup.floatIn(appeared, index: 8)
                        dataGroup.floatIn(appeared, index: 9)
                        footer
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .background(theme.canvas.ignoresSafeArea())
            .onAppear {
                appeared = true
                if LaunchOptions.screenshot == "widgets" {
                    // Demo screenshot: show the worlds and the widget previews.
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.6))
                        withAnimation(.easeInOut(duration: 0.5)) {
                            reader.scrollTo("widgets", anchor: .center)
                        }
                    }
                }
            }
        }
        .task { await refreshHealthWeight() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: reminderSignature) {
            ReminderScheduler.reschedule(for: store.profile)
        }
        .confirmationDialog("Clear today's log?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear today", role: .destructive) {
                withAnimation { store.clearToday() }
            }
        } message: {
            Text("Dewy will forget every drink you logged today.")
        }
        .confirmationDialog("Erase everything?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Erase all data", role: .destructive) {
                store.eraseEverything()
            }
        } message: {
            Text("Your history, friends, outfits and settings will be removed. This can't be undone.")
        }
        .alert("Notifications are off", isPresented: $permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Allow notifications for Dewy in Settings so it can send gentle sip reminders.")
        }
    }

    // MARK: Helpers

    private var reminderSignature: String {
        let p = store.profile
        return "\(p.remindersOn)-\(p.reminderInterval)-\(p.wakeMinutes)-\(p.sleepMinutes)"
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<UserProfile, Value>) -> Binding<Value> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { store.profile[keyPath: keyPath] = $0 }
        )
    }

    /// Changes something the recommended goal depends on (weight, activity, climate).
    /// If the goal was following the recommendation, it keeps following it.
    private func updateBody(_ change: (inout UserProfile) -> Void) {
        var profile = store.profile
        let wasFollowing = abs(profile.dailyGoal - profile.recommendedGoal) < 1
        change(&profile)
        if wasFollowing {
            profile.dailyGoal = profile.recommendedGoal
        }
        store.profile = profile
    }

    private func bodyBinding<Value>(_ keyPath: WritableKeyPath<UserProfile, Value>) -> Binding<Value> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    updateBody { $0[keyPath: keyPath] = newValue }
                }
            }
        )
    }

    private func weightText(_ kg: Double) -> String {
        if store.profile.usesPounds {
            return "\(Int((kg / Self.kgPerPound).rounded())) lb"
        }
        return "\(Int(kg.rounded())) kg"
    }

    private var displayName: String {
        store.profile.name.isEmpty ? "Friend of Dewy" : store.profile.name
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Text("Me")
                .font(.display(34))
                .foregroundStyle(theme.ink)
            Spacer()
            CircleIconButton(systemImage: "xmark", size: 38) {
                Haptics.tap()
                dismiss()
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(theme.canvas.opacity(0.96))
    }

    // MARK: Profile hero

    private var profileHero: some View {
        let phase = theme.phase()
        return VStack(spacing: 10) {
            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: 110,
                outfits: store.outfits,
                bands: store.todayBands,
                animated: false
            )
            Text(displayName)
                .font(.display(28))
                .foregroundStyle(phase.onSky)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)
            HStack(spacing: 10) {
                CountPill(glyph: .drop, value: store.dropBalance, tint: Palette.coral)
                CountPill(glyph: .flame, value: store.currentStreak, tint: Palette.butter)
                if purchases.isPremium {
                    MemberPill()
                }
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background { HeroCardBackground(phase: phase) }
    }

    // MARK: Dewy+

    static let rainbow: [LiquidBand] = [
        LiquidBand(color: DrinkKind.water.color, upTo: 0.22),
        LiquidBand(color: DrinkKind.juice.color, upTo: 0.42),
        LiquidBand(color: DrinkKind.matcha.color, upTo: 0.6),
        LiquidBand(color: DrinkKind.smoothie.color, upTo: 0.8),
        LiquidBand(color: DrinkKind.sparkling.color, upTo: 1)
    ]

    private var plusCard: some View {
        Button {
            Haptics.tap()
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                MascotView(progress: 1, mood: .ecstatic, size: 66, outfits: [.crown], bands: Self.rainbow, backdrop: .light, animated: false, showsShadow: false)
                    .frame(width: 74, height: 84)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Dewy+")
                            .font(.display(24))
                            .foregroundStyle(theme.ink)
                        ClayIcon(glyph: .crown, size: 24)
                    }
                    Text("Every world, friend and drink, 2× Dew Drops and custom reminders.")
                        .font(.dewy(13.5, .medium))
                        .foregroundStyle(theme.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(theme.accent, in: Circle())
            }
            .padding(16)
            .background {
                ClaySurface(shape: RoundedRectangle(cornerRadius: 28, style: .continuous), fill: Palette.butterSoft, glow: Palette.butterDeep)
            }
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }

    // MARK: Goal

    private var goalGroup: some View {
        let recommended = store.profile.recommendedGoal
        let matches = abs(recommended - store.profile.dailyGoal) < 1
        return MeGroup("Daily goal") {
            VStack(spacing: 14) {
                HStack {
                    roundButton("minus") {
                        store.profile.dailyGoal = max(500, store.profile.dailyGoal - store.profile.unit.step)
                    }
                    Spacer()
                    VStack(spacing: -2) {
                        Text(store.format(store.profile.dailyGoal, withUnit: false))
                            .font(.display(46))
                            .foregroundStyle(theme.ink)
                            .contentTransition(.numericText(value: store.profile.dailyGoal))
                        Text(store.profile.unit.label + " per day")
                            .font(.dewy(14, .semibold))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer()
                    roundButton("plus") {
                        store.profile.dailyGoal = min(6_000, store.profile.dailyGoal + store.profile.unit.step)
                    }
                }
                if matches {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(theme.accent)
                        Text("Matches your recommended goal")
                            .foregroundStyle(theme.inkSoft)
                    }
                    .font(.dewy(13.5, .semibold))
                    .frame(height: 30)
                } else {
                    Button {
                        Haptics.select()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.profile.dailyGoal = recommended }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Use recommended \(store.format(recommended))")
                        }
                        .font(.display(15))
                        .foregroundStyle(theme.link)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(theme.accentSoft, in: Capsule())
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(theme.onAccent)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(CandyButtonStyle(fill: theme.accent, lip: theme.accentDeep, shape: AnyShape(Circle()), depth: 4))
    }

    // MARK: You

    private var youGroup: some View {
        MeGroup("You") {
            profileRows
            MeDivider()
            lifestyleRows
        }
    }

    @ViewBuilder
    private var profileRows: some View {
        MeRow(icon: "person.fill", tint: Palette.aqua, title: "Name") {
            TextField("Your name", text: binding(\.name))
                .multilineTextAlignment(.trailing)
                .font(.dewy(16, .medium))
                .foregroundStyle(theme.ink)
                .submitLabel(.done)
                .frame(maxWidth: 160)
        }
        MeDivider()
        MeRow(icon: "scalemass.fill", tint: Palette.peach, title: "Weight") {
            weightStepper
        }
        MeDivider()
        MeRow(icon: "ruler.fill", tint: Palette.mint, title: "Weigh in") {
            ClaySegmented(items: [false, true], selection: binding(\.usesPounds), title: { $0 ? "lb" : "kg" })
                .frame(width: 124)
        }
        MeDivider()
        MeRow(icon: "drop.fill", tint: Palette.aquaLight, title: "Drinks in") {
            ClaySegmented(items: VolumeUnit.allCases, selection: binding(\.unit), title: { $0.label })
                .frame(width: 124)
        }
    }

    @ViewBuilder
    private var lifestyleRows: some View {
        VStack(alignment: .leading, spacing: 4) {
            MeRow(icon: store.profile.activity.symbol, tint: Palette.lilac, title: "Activity", subtitle: store.profile.activity.subtitle)
            ClaySegmented(items: ActivityLevel.allCases, selection: bodyBinding(\.activity), title: { $0.title })
                .padding(.bottom, 12)
        }
        MeDivider()
        VStack(alignment: .leading, spacing: 4) {
            MeRow(icon: store.profile.climate.symbol, tint: Palette.butter, title: "Climate", subtitle: "Hotter days need a little more water")
            ClaySegmented(items: Climate.allCases, selection: bodyBinding(\.climate), title: { $0.title })
                .padding(.bottom, 12)
        }
    }

    private var weightStepper: some View {
        let step = store.profile.usesPounds ? Self.kgPerPound : 1
        return HStack(spacing: 8) {
            CircleIconButton(systemImage: "minus", size: 32) {
                Haptics.select()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    updateBody { $0.weightKg = max(30, $0.weightKg - step) }
                }
            }
            Text(weightText(store.profile.weightKg))
                .font(.display(17))
                .foregroundStyle(theme.ink)
                .monospacedDigit()
                .contentTransition(.numericText(value: store.profile.weightKg))
                .frame(minWidth: 62)
            CircleIconButton(systemImage: "plus", size: 32) {
                Haptics.select()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    updateBody { $0.weightKg = min(250, $0.weightKg + step) }
                }
            }
        }
    }

    // MARK: Reminders

    private var remindersGroup: some View {
        MeGroup("Reminders") {
            MeToggleRow(
                icon: "bell.badge.fill",
                tint: Palette.coral,
                title: "Sip reminders",
                subtitle: store.profile.remindersOn ? "Dewy will nudge you gently" : "Off",
                isOn: Binding(
                    get: { store.profile.remindersOn },
                    set: { newValue in toggleReminders(newValue) }
                )
            )
            if store.profile.remindersOn {
                intervalPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            MeDivider()
            timeRow(icon: "sun.max.fill", tint: Palette.tangerine, title: "Wake up", minutes: binding(\.wakeMinutes))
            MeDivider()
            timeRow(icon: "moon.stars.fill", tint: Palette.lilac, title: "Bedtime", minutes: binding(\.sleepMinutes))
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: store.profile.remindersOn)
    }

    private var intervalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                CapsLabel(text: "Remind me every", color: theme.inkSoft, size: 11)
                if !purchases.isPremium {
                    PlusBadge()
                }
            }
            HStack(spacing: 8) {
                ForEach(intervals, id: \.minutes) { option in
                    let locked = option.minutes != 120 && !purchases.isPremium
                    ChipButton(title: option.label, isSelected: store.profile.reminderInterval == option.minutes, isLocked: locked) {
                        if locked {
                            Haptics.warning()
                            showPaywall = true
                        } else {
                            Haptics.select()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { store.profile.reminderInterval = option.minutes }
                        }
                    }
                }
            }
        }
        .padding(.leading, 48)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeRow(icon: String, tint: Color, title: String, minutes: Binding<Int>) -> some View {
        MeRow(icon: icon, tint: tint, title: title) {
            DatePicker(title, selection: minutes.timeOfDay, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(theme.accent)
        }
    }

    private func toggleReminders(_ isOn: Bool) {
        Haptics.select()
        guard isOn else {
            store.profile.remindersOn = false
            return
        }
        Task { @MainActor in
            let granted = await ReminderScheduler.requestPermission()
            if granted {
                store.profile.remindersOn = true
            } else {
                permissionDenied = true
            }
        }
    }

    // MARK: Worlds

    private var worldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Dewy's world", trailing: store.theme.displayName)
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(AppTheme.allCases) { option in
                        worldButton(option)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .padding(.horizontal, -20)
        }
    }

    private func worldButton(_ option: AppTheme) -> some View {
        let locked = option.isPremium && !purchases.isPremium
        return Button {
            if locked {
                Haptics.warning()
                showPaywall = true
            } else {
                Haptics.select()
                withAnimation(.smooth(duration: 0.5)) { store.profile.theme = option }
            }
        } label: {
            MeWorldTile(world: option, isSelected: store.theme == option, isLocked: locked)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.95))
        .accessibilityLabel(option.displayName + (locked ? ", Dewy+" : ""))
    }

    // MARK: Lock Screen & widgets

    private var lockScreenGroup: some View {
        MeGroup("Lock Screen & widgets") {
            MeToggleRow(
                icon: "iphone.radiowaves.left.and.right",
                tint: Palette.aqua,
                title: "Live Activity",
                subtitle: "Today's progress on your Lock Screen and Dynamic Island, with quick-sip buttons",
                isOn: Binding(
                    get: { store.profile.liveActivityOn },
                    set: { newValue in setLiveActivity(newValue) }
                )
            )
            MeDivider()
            VStack(alignment: .leading, spacing: 4) {
                MeRow(icon: "square.grid.2x2.fill", tint: Palette.lilac, title: "Widgets", subtitle: "Touch and hold your Home Screen, tap +, find Dewy")
                widgetPreviews
                    .padding(.bottom, 14)
            }
        }
    }

    private func setLiveActivity(_ isOn: Bool) {
        Haptics.select()
        store.profile.liveActivityOn = isOn
        if isOn {
            LiveActivityManager.sync(store)
        } else {
            LiveActivityManager.end()
        }
    }

    private var widgetPreviews: some View {
        let snapshot = DewySnapshot.make(from: AppData(profile: store.profile, entries: store.entries, hasOnboarded: true), at: .now)
        return ScrollView(.horizontal) {
            HStack(spacing: 12) {
                widgetPreview(width: 150) { DewyWidgetSmall(snapshot: snapshot) }
                widgetPreview(width: 322) { DewyWidgetMedium(snapshot: snapshot) }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .padding(.horizontal, -16)
    }

    private func widgetPreview<Content: View>(width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: width, height: 150)
            .background(WidgetSky(theme: theme))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1.5)
            }
            .shadow(color: Palette.shadow.opacity(0.22), radius: 12, x: 0, y: 7)
            .allowsHitTesting(false)
    }

    // MARK: Apple Health

    private var healthGroup: some View {
        MeGroup("Apple Health") {
            MeToggleRow(
                icon: "heart.fill",
                tint: Palette.pink,
                title: "Sync with Health",
                subtitle: "Save drinks as water and read your weight",
                isOn: Binding(
                    get: { store.profile.healthSyncOn },
                    set: { newValue in setHealthSync(newValue) }
                )
            )
            if store.profile.healthSyncOn, let weight = healthWeight, abs(weight - store.profile.weightKg) >= 0.1 {
                MeDivider()
                Button {
                    Haptics.select()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        updateBody { $0.weightKg = weight }
                    }
                } label: {
                    MeRow(icon: "scalemass.fill", tint: Palette.peach, title: "Use weight from Health (\(weightText(weight)))", subtitle: "Updates your recommended goal") {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(theme.accent)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            MeDivider()
            Button {
                guard !purchases.isPremium else { return }
                Haptics.tap()
                showPaywall = true
            } label: {
                MeRow(icon: "calendar", tint: Palette.mint, title: "Health history", subtitle: "Past days from Apple Health in Insights") {
                    if purchases.isPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(theme.accent)
                    } else {
                        PlusBadge()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: healthWeight)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: store.profile.healthSyncOn)
    }

    private func setHealthSync(_ isOn: Bool) {
        Haptics.select()
        guard isOn else {
            store.profile.healthSyncOn = false
            return
        }
        store.profile.healthSyncOn = true
        Task { @MainActor in
            let granted = await HealthSync.requestAccess()
            if granted {
                await refreshHealthWeight()
            } else {
                withAnimation { store.profile.healthSyncOn = false }
            }
        }
    }

    private func refreshHealthWeight() async {
        guard HealthSync.isAvailable, store.profile.healthSyncOn, !LaunchOptions.isDemo else { return }
        healthWeight = await HealthSync.latestWeight()
    }

    // MARK: Sounds & feel

    private var feelGroup: some View {
        MeGroup("Sounds & feel") {
            MeToggleRow(icon: "speaker.wave.2.fill", tint: Palette.aqua, title: "Sounds", subtitle: "Bloops, splashes and a goal chime", isOn: binding(\.soundsOn))
            MeDivider()
            MeToggleRow(icon: "hand.tap.fill", tint: Palette.peach, title: "Haptics", subtitle: "Feel every sip", isOn: binding(\.hapticsOn))
            MeDivider()
            VStack(alignment: .leading, spacing: 4) {
                MeRow(icon: "bolt.fill", tint: Palette.lilac, title: "Caffeine budget", subtitle: "Dewy keeps an eye on it for you")
                HStack(spacing: 8) {
                    ForEach([200.0, 300, 400], id: \.self) { limit in
                        ChipButton(title: "\(Int(limit)) mg", isSelected: store.profile.caffeineLimit == limit) {
                            Haptics.select()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { store.profile.caffeineLimit = limit }
                        }
                    }
                }
                .padding(.leading, 48)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: Data

    private var dataGroup: some View {
        MeGroup("Your data") {
            MeActionRow(icon: "arrow.counterclockwise", tint: Palette.aqua, title: "Clear today's log") {
                confirmClear = true
            }
            MeDivider()
            MeActionRow(icon: "arrow.clockwise", tint: Palette.lilac, title: "Restore purchases") {
                Haptics.tap()
                Task { await purchases.restore() }
            }
            MeDivider()
            MeActionRow(icon: "trash.fill", tint: Palette.berry, title: "Erase everything", isDestructive: true) {
                confirmErase = true
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            MascotView(progress: 0.6, mood: .happy, size: 56, backdrop: .light, animated: false, showsShadow: false)
            Text("Made with love for tiny sips")
                .font(.display(15, .medium))
                .foregroundStyle(theme.inkSoft)
            Text("Dewy 2.0")
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkFaint)
        }
        .padding(.top, 4)
    }
}

// MARK: - Pieces

/// A titled clay card that holds grouped rows.
private struct MeGroup<Content: View>: View {
    var title: String?
    var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                SectionHeader(title: title)
            }
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dewyCard(padding: 0)
        }
    }
}

/// A hairline between rows, aligned with the row titles.
private struct MeDivider: View {
    @Environment(\.dewyTheme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.line)
            .frame(height: 1.5)
            .padding(.leading, 48)
    }
}

/// Icon tile, title (and optional subtitle), then the value or control on the right.
private struct MeRow<Trailing: View>: View {
    @Environment(\.dewyTheme) private var theme
    var icon: String
    var tint: Color
    var title: String
    var subtitle: String?
    var titleColor: Color?
    var trailing: Trailing

    init(icon: String, tint: Color, title: String, subtitle: String? = nil, titleColor: Color? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: icon, color: tint, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(titleColor ?? theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.dewy(12.5, .medium))
                        .foregroundStyle(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.vertical, 10)
        .frame(minHeight: 58)
    }
}

extension MeRow where Trailing == EmptyView {
    init(icon: String, tint: Color, title: String, subtitle: String? = nil) {
        self.init(icon: icon, tint: tint, title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// A row with an aqua switch.
private struct MeToggleRow: View {
    @Environment(\.dewyTheme) private var theme
    var icon: String
    var tint: Color
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool

    init(icon: String, tint: Color, title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        MeRow(icon: icon, tint: tint, title: title, subtitle: subtitle) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(theme.accent)
        }
    }
}

/// A tappable row with a chevron.
private struct MeActionRow: View {
    @Environment(\.dewyTheme) private var theme
    var icon: String
    var tint: Color
    var title: String
    var isDestructive = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            MeRow(icon: icon, tint: tint, title: title, titleColor: isDestructive ? Palette.berry : nil) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(theme.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The gold "Dewy+" membership pill shown on the hero for subscribers.
private struct MemberPill: View {
    @Environment(\.dewyTheme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            ClayIcon(glyph: .crown, size: 22)
            Text("Dewy+")
                .font(.display(16))
                .foregroundStyle(theme.ink)
        }
        .padding(.leading, 7)
        .padding(.trailing, 12)
        .frame(height: 38)
        .background {
            ClaySurface(shape: Capsule(), fill: Palette.butterSoft, glow: Palette.butter, elevation: 0.55)
        }
    }
}

/// The soft sky behind the profile hero, with two clay clouds drifting at the edges.
private struct HeroCardBackground: View {
    var phase: SkyPhase

    private let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)

    var body: some View {
        shape
            .fill(phase.gradient)
            .overlay {
                RadialGradient(colors: [phase.sunGlow.opacity(0.85), phase.sunGlow.opacity(0)], center: UnitPoint(x: 0.85, y: 0.1), startRadius: 0, endRadius: 160)
            }
            .overlay(alignment: .topLeading) {
                cloud("prop-cloud-1", width: 96)
                    .offset(x: -22, y: 26)
            }
            .overlay(alignment: .topTrailing) {
                cloud("prop-cloud-2", width: 84)
                    .offset(x: 18, y: 78)
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1.5)
            }
            .shadow(color: phase.sky[0].opacity(0.35), radius: 18, x: 0, y: 10)
            .shadow(color: Palette.shadow.opacity(0.1), radius: 1.5, x: 0, y: 1.5)
    }

    @ViewBuilder
    private func cloud(_ name: String, width: CGFloat) -> some View {
        if Art.exists(name) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .colorMultiply(phase.cloudTint.map { $0.blended(with: .white, by: 0.45) } ?? .white)
                .opacity(0.95)
                .accessibilityHidden(true)
        }
    }
}

/// A clay postcard of a world: its landmark art on the world's tint, its name and tagline.
private struct MeWorldTile: View {
    @Environment(\.dewyTheme) private var theme
    var world: AppTheme
    var isSelected: Bool
    var isLocked: Bool

    private let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            art
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(world.displayName)
                        .font(.display(17))
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    if isLocked {
                        PlusBadge()
                    }
                }
                Text(world.tagline)
                    .font(.dewy(12, .medium))
                    .foregroundStyle(theme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .padding(10)
        .frame(width: 170)
        .background {
            ClaySurface(shape: shape, fill: .white, glow: world.tint, elevation: 0.75)
        }
        .overlay {
            shape.strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 2.5)
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(theme.accent, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                    .offset(x: 6, y: -6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(shape)
    }

    private var art: some View {
        let wash = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return ZStack(alignment: .bottom) {
            wash.fill(LinearGradient(
                colors: [world.tint.blended(with: .white, by: 0.6), world.tint.blended(with: .white, by: 0.15)],
                startPoint: .top, endPoint: .bottom
            ))
            celestial
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(10)
            landmarks
                .padding(.bottom, 4)
        }
        .frame(height: 108)
        .clipShape(wash)
        .overlay {
            wash.strokeBorder(LinearGradient(colors: [.white.opacity(0.85), .white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1.2)
        }
    }

    @ViewBuilder
    private var celestial: some View {
        let name = world == .midnight ? "prop-moon" : "prop-sun"
        if Art.exists(name) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var landmarks: some View {
        let names = world.landmarks
        if names.count > 1 {
            HStack(alignment: .bottom, spacing: -8) {
                ArtImage(name: names[0], size: 84)
                ArtImage(name: names[1], size: 54)
            }
        } else if let first = names.first {
            ArtImage(name: first, size: 92)
        }
    }
}

// MARK: - Time binding

extension Binding where Value == Int {
    /// Bridges "minutes after midnight" to a `Date` for `DatePicker`.
    var timeOfDay: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: wrappedValue / 60 % 24, minute: wrappedValue % 60, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}
