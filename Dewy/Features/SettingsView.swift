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
        ScrollView {
            VStack(spacing: 18) {
                header.floatIn(appeared, index: 0)
                premiumCard.floatIn(appeared, index: 1)
                goalCard.floatIn(appeared, index: 2)
                remindersCard.floatIn(appeared, index: 3)
                themeCard.floatIn(appeared, index: 4)
                profileCard.floatIn(appeared, index: 5)
                dataCard.floatIn(appeared, index: 6)
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
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
        VStack(alignment: .leading, spacing: 2) {
            Text("MAKE IT YOURS")
                .font(.dewy(13, .bold))
                .tracking(1.2)
                .foregroundStyle(theme.inkSoft)
            Text("Settings")
                .font(.dewy(30, .heavy))
                .foregroundStyle(theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Premium

    @ViewBuilder
    private var premiumCard: some View {
        if purchases.isPremium {
            HStack(spacing: 14) {
                MascotView(progress: 1, mood: .ecstatic, size: 44, accessory: .crown)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dewy+ is active")
                        .font(.dewy(18, .heavy))
                        .foregroundStyle(theme.ink)
                    Text("Thank you for supporting a tiny indie app 💙")
                        .font(.dewy(13, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer(minLength: 0)
            }
            .glassCard()
        } else {
            Button {
                Haptics.tap()
                showPaywall = true
            } label: {
                HStack(spacing: 14) {
                    MascotView(progress: 0.9, mood: .ecstatic, size: 50, accessory: .crown)
                        .padding(.top, 8)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unlock Dewy+")
                            .font(.dewy(20, .heavy))
                        Text("Dreamy themes, all drinks & 30-day insights")
                            .font(.dewy(13, .semibold))
                            .opacity(0.9)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(18)
                .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.4), lineWidth: 1))
                .shimmer()
                .shadow(color: theme.accent.opacity(0.35), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.97))
        }
    }

    // MARK: Goal

    private var goalCard: some View {
        let recommended = store.profile.recommendedGoal
        return VStack(alignment: .leading, spacing: 14) {
            SettingsLabel(icon: "target", tint: theme.accent, title: "Daily goal")
            HStack {
                roundButton("minus") {
                    store.profile.dailyGoal = max(500, store.profile.dailyGoal - store.profile.unit.step)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(store.format(store.profile.dailyGoal, withUnit: false))
                        .font(.dewy(40, .heavy))
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
            if abs(recommended - store.profile.dailyGoal) >= 1 {
                Button {
                    Haptics.select()
                    withAnimation(.spring) { store.profile.dailyGoal = recommended }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Use recommended \(store.format(recommended))")
                    }
                    .font(.dewy(14, .bold))
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(theme.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .glassCard()
    }

    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(theme.accentGradient, in: Circle())
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
                SettingsLabel(icon: "bell.badge.fill", tint: Color(hex: 0xFF8A7A), title: "Sip reminders",
                              subtitle: store.profile.remindersOn ? "Dewy will nudge you gently" : "Off")
            }
            .tint(theme.accent)

            if store.profile.remindersOn {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Remind me every")
                        .font(.dewy(14, .semibold))
                        .foregroundStyle(theme.inkSoft)
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

            Divider().overlay(theme.inkSoft.opacity(0.15))

            timeRow(icon: "sun.max.fill", tint: Palette.sunshine, title: "Wake up", minutes: binding(\.wakeMinutes))
            timeRow(icon: "moon.stars.fill", tint: Palette.lilac, title: "Bedtime", minutes: binding(\.sleepMinutes))
        }
        .glassCard()
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
            SettingsLabel(icon: "paintpalette.fill", tint: Color(hex: 0xB78CFF), title: "Theme")
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
        .glassCard()
    }

    // MARK: Profile

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SettingsLabel(icon: "person.crop.circle.fill", tint: Color(hex: 0x5AB4FF), title: "Name")
                Spacer()
                TextField("Your name", text: binding(\.name))
                    .multilineTextAlignment(.trailing)
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(theme.ink)
                    .submitLabel(.done)
                    .frame(maxWidth: 160)
            }
            Divider().overlay(theme.inkSoft.opacity(0.15))
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
            Divider().overlay(theme.inkSoft.opacity(0.15))
            HStack {
                SettingsLabel(icon: "figure.walk", tint: Color(hex: 0xFFB347), title: "Activity")
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
        .glassCard()
    }

    // MARK: Data

    private var dataCard: some View {
        VStack(spacing: 0) {
            dataRow(icon: "arrow.counterclockwise", title: "Clear today's log", tint: theme.inkSoft) {
                confirmClear = true
            }
            Divider().overlay(theme.inkSoft.opacity(0.15)).padding(.vertical, 6)
            dataRow(icon: "arrow.clockwise.circle.fill", title: "Restore purchases", tint: theme.accent) {
                Task { await purchases.restore() }
            }
            Divider().overlay(theme.inkSoft.opacity(0.15)).padding(.vertical, 6)
            dataRow(icon: "trash.fill", title: "Erase everything", tint: Color(hex: 0xFF6B6B)) {
                confirmErase = true
            }
        }
        .glassCard()
    }

    private func dataRow(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 30)
                Text(title)
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(tint == theme.inkSoft ? theme.ink : tint)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.inkSoft.opacity(0.6))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            MascotView(progress: 0.6, mood: .happy, size: 36)
            Text("Made with 💧 for tiny sips")
                .font(.dewy(13, .semibold))
                .foregroundStyle(theme.inkSoft)
            Text("Dewy 1.0")
                .font(.dewy(12, .medium))
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
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.dewy(16, .bold))
                    .foregroundStyle(theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.dewy(12, .medium))
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
                    .fill(LinearGradient(colors: [theme.backgroundTop, theme.backgroundBottom], startPoint: .top, endPoint: .bottom))
                DropletShape()
                    .fill(theme.waterGradient)
                    .frame(width: 22, height: 27)
                    .offset(y: 1)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(current.inkSoft, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .offset(x: 18, y: 18)
                }
            }
            .frame(width: 52, height: 52)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 2))
            .padding(3)
            .overlay(Circle().strokeBorder(isSelected ? current.accent : .clear, lineWidth: 2.5))
            .scaleEffect(isSelected ? 1.06 : 1)
            .shadow(color: theme.waterBottom.opacity(0.25), radius: 6, x: 0, y: 3)
            Text(theme.displayName)
                .font(.dewy(12, isSelected ? .heavy : .semibold))
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
