import WidgetKit
import SwiftUI

@main
struct DewyWidgetBundle: WidgetBundle {
    init() {
        FontRegistry.registerFonts()
    }

    var body: some Widget {
        DewyHomeWidget()
        DewyLiveActivity()
    }
}

struct DewyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DewySnapshot {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (DewySnapshot) -> Void) {
        completion(context.isPreview ? .sample : .load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DewySnapshot>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86_400)
        // Dewy starts every new day empty, and the app refreshes the widget whenever you log.
        let entries = [DewySnapshot.load(at: now), DewySnapshot.load(at: tomorrow.addingTimeInterval(1))]
        completion(Timeline(entries: entries, policy: .after(min(now.addingTimeInterval(30 * 60), tomorrow))))
    }
}

struct DewyHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DewyHomeWidget", provider: DewyProvider()) { snapshot in
            DewyWidgetView(snapshot: snapshot)
        }
        .configurationDisplayName("Dewy")
        .description("Watch Dewy fill up and log a sip without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}
