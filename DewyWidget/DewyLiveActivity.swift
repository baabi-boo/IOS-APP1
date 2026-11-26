import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Today's sips on the Lock Screen and Dynamic Island, harmonized with Dewy's Editorial Storybook look.
struct DewyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DewyActivityAttributes.self) { context in
            LockScreenActivityView(state: context.state)
                .activityBackgroundTint(Palette.cream)
                .activitySystemActionForegroundColor(Ink.primary)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MascotView(
                        progress: state.progress,
                        mood: DewyMood(progress: state.progress),
                        size: 54,
                        animated: false,
                        showsShadow: false,
                        isNight: true
                    )
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int((state.progress * 100).rounded()))%")
                            .font(.display(26, .bold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.aquaLight)
                        Text("of \(state.goalText)")
                            .font(.dewy(11.5, .bold))
                            .foregroundStyle(Ink.starlight.opacity(0.65))
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(state.totalText)
                        .font(.display(20, .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Ink.starlight)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        ActivityProgressBar(progress: state.progress, track: Ink.starlight.opacity(0.16), dark: true)
                            .frame(height: 10)
                        HStack(spacing: 8) {
                            QuickSipButton(amount: 150, dark: true)
                            QuickSipButton(amount: 250, dark: true)
                            QuickSipButton(amount: 500, dark: true)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                ProgressDrop(progress: state.progress)
                    .frame(width: 20, height: 24)
            } compactTrailing: {
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.display(14, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.aquaLight)
            } minimal: {
                ProgressDrop(progress: state.progress)
                    .frame(width: 18, height: 22)
            }
            .keylineTint(Palette.aqua)
        }
    }
}

private struct LockScreenActivityView: View {
    var state: DewyActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            MascotView(
                progress: state.progress,
                mood: DewyMood(progress: state.progress),
                size: 68,
                backdrop: .light,
                animated: false,
                showsShadow: false
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(state.totalText)
                        .font(.display(24, .bold))
                        .monospacedDigit()
                        .foregroundStyle(Ink.primary)
                    Text("of \(state.goalText)")
                        .font(.dewy(12.5, .semibold))
                        .foregroundStyle(Ink.soft)
                    Spacer(minLength: 0)
                    if state.streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("\(state.streak)")
                                .font(.dewy(12.5, .bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(Palette.butterDeep)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(Palette.butterSoft, in: Capsule())
                        .overlay(Capsule().stroke(Palette.butterDeep.opacity(0.24), lineWidth: 0.75))
                    }
                }

                ActivityProgressBar(progress: state.progress, track: Palette.creamDeep, dark: false)
                    .frame(height: 11)

                HStack(spacing: 8) {
                    QuickSipButton(amount: 150, dark: false)
                    QuickSipButton(amount: 250, dark: false)
                    QuickSipButton(amount: 500, dark: false)
                }
            }
        }
        .padding(16)
    }
}

private struct QuickSipButton: View {
    var amount: Double
    var dark: Bool

    var body: some View {
        Button(intent: QuickSipIntent(amount: amount)) {
            HStack(spacing: 3) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 9.5, weight: .bold))
                Text("+\(Int(amount))")
                    .font(.dewy(13, .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(dark ? Ink.starlight : Palette.aquaDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(dark ? Palette.aqua.opacity(0.32) : Palette.paper, in: Capsule())
            .overlay {
                Capsule().stroke(
                    dark ? Palette.aquaLight.opacity(0.35) : Palette.aqua.opacity(0.28),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }
}

/// Matte gouache hydration bar with subtle hairline border (zero plastic gloss glare).
private struct ActivityProgressBar: View {
    var progress: Double
    var track: Color
    var dark: Bool

    var body: some View {
        let clamped = min(max(progress, 0), 1)
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(track)
                    .overlay(Capsule().stroke(dark ? Ink.starlight.opacity(0.18) : Ink.hairline, lineWidth: 0.75))
                if clamped > 0 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Palette.aquaLight, Palette.aqua],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.height, proxy.size.width * clamped))
                        .padding(1)
                }
            }
        }
    }
}

/// Compact droplet gauge for Dynamic Island compact & minimal slots.
private struct ProgressDrop: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                DewyShape().fill(Ink.starlight.opacity(0.22))
                Rectangle()
                    .fill(Palette.aquaLight)
                    .frame(height: proxy.size.height * min(max(progress, 0.08), 1))
            }
            .clipShape(DewyShape())
        }
    }
}
