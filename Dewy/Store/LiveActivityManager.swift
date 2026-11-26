import ActivityKit
import Foundation

/// Starts, updates and ends today's Live Activity from the app.
@MainActor
enum LiveActivityManager {
    private static var current: Activity<DewyActivityAttributes>? {
        Activity<DewyActivityAttributes>.activities.first
    }

    /// Keeps the activity in sync with the app's data: starts it on the first sip of the day,
    /// updates it on every change and ends it once the goal is reached for a while.
    static func sync(_ store: HydrationStore) {
        guard !LaunchOptions.isDemo else { return }
        let data = AppData(profile: store.profile, entries: store.entries, hasOnboarded: store.hasOnboarded, challenges: store.challenges, collection: store.collection)
        sync(data: data, enabled: store.profile.liveActivityOn)
    }

    static func sync(data: AppData, enabled: Bool) {
        guard enabled, ActivityAuthorizationInfo().areActivitiesEnabled else {
            end()
            return
        }
        let state = DewyActivityAttributes.ContentState.make(from: data)
        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 4, to: .now))
        if let activity = current {
            Task { await activity.update(content) }
        } else if state.total > 0 {
            _ = try? Activity.request(attributes: DewyActivityAttributes(name: data.profile.name), content: content, pushType: nil)
        }
    }

    static func end() {
        for activity in Activity<DewyActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
