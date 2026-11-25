import Foundation
import UserNotifications

/// Schedules Dewy's gentle, repeating sip reminders between wake-up and bedtime.
enum ReminderScheduler {
    private static let prefix = "dewy.reminder."

    private static let messages: [String] = [
        "Dewy is getting a little thirsty 🥺 Time for a sip!",
        "Psst… your water misses you 💧",
        "A tiny sip now = a happy Dewy later ✨",
        "Hydration break! Stretch, breathe, sip 🌿",
        "Your garden is waiting to bloom 🌸 Have a drink!",
        "Glug glug o'clock! 🫧",
        "Future you says thanks for this glass 💙"
    ]

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func reschedule(for profile: UserProfile) {
        guard !LaunchOptions.isDemo else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<64).map { "\(prefix)\($0)" })
        guard profile.remindersOn else { return }

        let interval = max(profile.reminderInterval, 30)
        var end = profile.sleepMinutes
        if end <= profile.wakeMinutes { end += 24 * 60 }
        var minute = profile.wakeMinutes + 30
        var index = 0
        while minute <= end - 30 && index < 60 {
            let content = UNMutableNotificationContent()
            content.title = "Sip time 💧"
            content.body = messages[index % messages.count]
            content.sound = .default

            var components = DateComponents()
            components.hour = (minute / 60) % 24
            components.minute = minute % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: "\(prefix)\(index)", content: content, trigger: trigger))

            minute += interval
            index += 1
        }
    }
}
