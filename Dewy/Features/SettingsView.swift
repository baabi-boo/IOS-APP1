import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    @State private var showPaywall = false
    @State private var confirmErase = false
    @State private var confirmClear = false
    @State private var permissionDenied = false
    @State private var appeared = false

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

    var body: some View {
        ZStack {
            HeroBackdrop()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 22)
                        .floatIn(appeared, index: 0)
                    premiumCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        .floatIn(appeared, index: 1)
                    VStack(spacing: 18) {
                        goalCard.floatIn(appeared, index: 2)
                        remindersCard.floatIn(appeared, index: 3)
                        themeCard.floatIn(appeared, index: 4)
                        profileCard.floatIn(appeared, index: 5)
                        dataCard.floatIn(appeared, index: 6)
                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 30)
                    .canvasSheet()
                }
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { appeared = true }
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
            Text("Your history, garden and settings will be removed. This can't be undone.")
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

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Make it yours", color: theme.onHeroSoft, size: 12)
                Text("Settings")
                    .font(.dewy(32, .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            MascotView(progress: store.todayProgress, mood: store.mood, size: 50, bands: store.todayBands, animated: false)
        }
    }

    // MARK: Premium

    @ViewBuilder
    private var premiumCard: some View {
        let tile = theme.isDark ? theme.heroLight : Color(hex: 0x1E2340)
        if purchases.isPremium {
            HStack(spacing: 14) {
                MascotView(progress: 1, mood: .ecstatic, size: 50, accessory: .crown, backdrop: .tile, animated: false)
                    .padding(.top, 10)
                VStack(alignment: .leading, spacing: 3) {
                    CapsLabel(text: "Dewy+", color: Palette.sunshine, size: 12)
                    Text("Everything is unlocked")
                        .font(.dewy(19, .black))
                        .foregroundStyle(.white)
                    Text("Thank you for supporting a tiny indie app 💙")
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(tile, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 10)
        } else {
            Button {
                Haptics.tap()
                showPaywall = true
            } label: {
                HStack(spacing: 14) {
                    MascotView(progress: 0.9, mood: .ecstatic, size: 54, accessory: .crown, backdrop: .tile, animated: false)
                        .padding(.top, 12)
                    VStack(alignment: .leading, spacing: 4) {
                        CapsLabel(text: "Dewy+", color: Palette.sunshine, size: 12)
                        Text("Unlock everything")
                            .font(.dewy(20, .black))
                            .foregroundStyle(.white)
                        Text("Themes, all drinks & 30-day insights")
                            .font(.dewy(13, .semibold))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Text("TRY")
                        .font(.dewy(14, .black))
                        .tracking(1)
                        .foregroundStyle(Color(hex: 0x1E2340))
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Palette.sunshine, in: Capsule())
                }
                .padding(18)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(tile)
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 160, height: 160)
                                .offset(x: 50, y: -70)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .shimmer()
                .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.97))
        }
    }

    // MARK: Goal

    private var goalCard: some View {
        let recommended = store.profile.recommendedGoal
        return VStack(alignment: .leading, spacing: 14) {
            SettingsLabel(icon: "target", tint: theme.accent, title: "Daily goal", subtitle: "Based on your body & day")
            HStack {
                roundButton("minus") {
                    store.profile.dailyGoal = max(500, store.profile.dailyGoal - store.profile.unit.step)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(store.format(store.profile.dailyGoal, withUnit: false))
                        .font(.dewy(44, .black))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: store.profile.dailyGoal))
                    CapsLabel(text: store.profile.unit.label + " per day", color: theme.inkSoft, size: 12)
                }
                Spacer()
                roundButton("plus") {
                    store.profile.dailyGoal = min(6_000, store.profile.dailyGoal + store.profile.unit.step)
                }
            }
            if abs(recommended - store.profile.dailyGoal) >= 1 {
                Button {
                    Haptics.select()
                    withAnimation(.spring) { store.profile.dailyGoal = recommended }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Use recommended \(store.format(recommended))")
                    }
                    .font(.dewy(14, .heavy))
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(theme.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .dewyCard()
    }

    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(theme.accent, in: Circle())
                .shadow(color: theme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }

    // MARK: Reminders

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(
                get: { store.profile.remindersOn },
                set: { newValue in toggleReminders(newValue) }
            )) {
                SettingsLabel(icon: "bell.badge.fill", tint: Palette.coral, title: "Sip reminders",
                              subtitle: store.profile.remindersOn ? "Dewy will nudge you gently" : "Off")
            }
            .tint(theme.accent)

            if store.profile.remindersOn {
                VStack(alignment: .leading, spacing: 10) {
                    CapsLabel(text: "Remind me every", color: theme.inkSoft, size: 11)
                    HStack(spacing: 8) {
                        ForEach(intervals, id: \.minutes) { option in
                            let locked = option.minutes != 120 && !purchases.isPremium
                            ChipButton(title: option.label, isSelected: store.profile.reminderInterval == option.minutes, isLocked: locked) {
                                if locked {
                                    showPaywall = true
                                } else {
                                    Haptics.select()
                                    withAnimation(.spring) { store.profile.reminderInterval = option.minutes }
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider().overlay(theme.line)

            timeRow(icon: "sun.max.fill", tint: Palette.tangerine, title: "Wake up", minutes: binding(\.wakeMinutes))
            timeRow(icon: "moon.stars.fill", tint: Palette.grape, title: "Bedtime", minutes: binding(\.sleepMinutes))
        }
        .dewyCard()
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: store.profile.remindersOn)
    }

    private func timeRow(icon: String, tint: Color, title: String, minutes: Binding<Int>) -> some View {
        HStack {
            SettingsLabel(icon: icon, tint: tint, title: title)
            Spacer()
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

    // MARK: Theme

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsLabel(icon: "paintpalette.fill", tint: Color(hex: 0xFF5C93), title: "Theme", subtitle: "Pick Dewy's color world")
            HStack(spacing: 0) {
                ForEach(AppTheme.allCases) { option in
                    let locked = option.isPremium && !purchases.isPremium
                    Button {
                        if locked {
                            Haptics.warning()
                            showPaywall = true
                        } else {
                            Haptics.select()
                            withAnimation(.smooth(duration: 0.5)) { store.profile.theme = option }
                        }
                    } label: {
                        ThemeSwatch(theme: option, isSelected: store.theme == option, isLocked: locked)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .dewyCard()
    }

    // MARK: Profile

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SettingsLabel(icon: "person.fill", tint: Palette.sky, title: "Name")
                Spacer()
                TextField("Your name", text: binding(\.name))
                    .multilineTextAlignment(.trailing)
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(theme.ink)
                    .submitLabel(.done)
                    .frame(maxWidth: 160)
            }
            Divider().overlay(theme.line)
            HStack {
                SettingsLabel(icon: "ruler.fill", tint: Palette.mint, title: "Units")
                Spacer()
                HStack(spacing: 6) {
                    ForEach(VolumeUnit.allCases) { unit in
                        ChipButton(title: unit.label, isSelected: store.profile.unit == unit) {
                            Haptics.select()
                            withAnimation(.spring) { store.profile.unit = unit }
                        }
                    }
                }
            }
            Divider().overlay(theme.line)
            HStack {
                SettingsLabel(icon: "figure.walk", tint: Palette.tangerine, title: "Activity")
                Spacer()
                Menu {
                    Picker("Activity", selection: binding(\.activity)) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text("\(level.emoji) \(level.title)").tag(level)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(store.profile.activity.emoji) \(store.profile.activity.title)")
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 11, weight: .bold))
                    }
                    .font(.dewy(15, .semibold))
                    .foregroundStyle(theme.ink)
                }
            }
        }
        .dewyCard()
    }

    // MARK: Data

    private var dataCard: some View {
        VStack(spacing: 0) {
            dataRow(icon: "arrow.counterclockwise", title: "Clear today's log", tint: Palette.sky) {
                confirmClear = true
            }
            Divider().overlay(theme.line).padding(.vertical, 6)
            dataRow(icon: "arrow.clockwise", title: "Restore purchases", tint: Palette.grape) {
                Task { await purchases.restore() }
            }
            Divider().overlay(theme.line).padding(.vertical, 6)
            dataRow(icon: "trash.fill", title: "Erase everything", tint: Palette.berry) {
                confirmErase = true
            }
        }
        .dewyCard()
    }

    private func dataRow(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconTile(systemImage: icon, color: tint, size: 34)
                Text(title)
                    .font(.dewy(16, .heavy))
                    .foregroundStyle(tint == Palette.berry ? Palette.berry : theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(theme.inkSoft.opacity(0.6))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            MascotView(progress: 0.6, mood: .happy, size: 40, backdrop: .light, animated: false)
            Text("Made with 💧 for tiny sips")
                .font(.dewy(14, .heavy))
                .foregroundStyle(theme.inkSoft)
            Text("Dewy 1.1")
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft.opacity(0.7))
        }
        .padding(.top, 8)
    }
}

// MARK: - Pieces

struct SettingsLabel: View {
    @Environment(\.dewyTheme) private var theme
    var icon: String
    var tint: Color
    var title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: icon, color: tint, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.dewy(16, .heavy))
                    .foregroundStyle(theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.dewy(12, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
        }
    }
}

struct ThemeSwatch: View {
    @Environment(\.dewyTheme) private var current
    var theme: AppTheme
    var isSelected: Bool
    var isLocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [theme.hero, theme.heroDeep], startPoint: .top, endPoint: .bottom))
                DropletShape()
                    .fill(Color.white)
                    .frame(width: 20, height: 25)
                    .offset(y: 1)
                DropletShape()
                    .fill(theme.water)
                    .frame(width: 20, height: 25)
                    .mask {
                        Rectangle()
                            .frame(width: 20, height: 13)
                            .offset(y: 6)
                    }
                    .offset(y: 1)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color(hex: 0x1E2340), in: Circle())
                        .overlay(Circle().strokeBorder(current.card, lineWidth: 2))
                        .offset(x: 19, y: 19)
                }
            }
            .frame(width: 54, height: 54)
            .padding(4)
            .overlay(Circle().strokeBorder(isSelected ? current.ink : Color.clear, lineWidth: 3))
            .scaleEffect(isSelected ? 1.05 : 1)
            .shadow(color: theme.hero.opacity(0.35), radius: 6, x: 0, y: 4)
            Text(theme.displayName)
                .font(.dewy(12, isSelected ? .black : .bold))
                .foregroundStyle(isSelected ? current.ink : current.inkSoft)
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
