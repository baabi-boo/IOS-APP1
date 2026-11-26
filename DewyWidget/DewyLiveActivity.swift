import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Today's sips on the Lock Screen and in the Dynamic Island, with quick-sip buttons.
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
                    MascotView(progress: state.progress, mood: DewyMood(progress: state.progress), size: 54, animated: false, showsShadow: false)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int((state.progress * 100).rounded()))%")
                            .font(.display(26, .bold))
                            .foregroundStyle(Palette.aquaLight)
                        Text("of \(state.goalText)")
                            .font(.dewy(12, .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(state.totalText)
                        .font(.display(20))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        ActivityProgressBar(progress: state.progress, track: .white.opacity(0.15))
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
                    .font(.display(14))
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
            MascotView(progress: state.progress, mood: DewyMood(progress: state.progress), size: 70, backdrop: .light, animated: false, showsShadow: false)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(state.totalText)
                        .font(.display(24, .bold))
                        .foregroundStyle(Ink.primary)
                    Text("of \(state.goalText)")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(Ink.soft)
                    Spacer(minLength: 0)
                    if state.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill").font(.system(size: 11, weight: .heavy))
                            Text("\(state.streak)").font(.display(14))
                        }
                        .foregroundStyle(Palette.butterDeep)
                    }
                }
                ActivityProgressBar(progress: state.progress, track: Color(hex: 0xF3E7DC))
                    .frame(height: 12)
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
                Image(systemName: "drop.fill").font(.system(size: 10, weight: .black))
                Text("+\(Int(amount))").font(.display(14))
            }
            .foregroundStyle(dark ? Color.white : Palette.aquaDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(dark ? Palette.aqua.opacity(0.35) : Palette.aquaSoft, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityProgressBar: View {
    var progress: Double
    var track: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(proxy.size.height, proxy.size.width * min(progress, 1)))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.4)).frame(height: proxy.size.height * 0.3).padding(.horizontal, 4).padding(.top, 2)
                    }
            }
        }
    }
}

/// A droplet that fills from the bottom, for the compact Dynamic Island.
private struct ProgressDrop: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                DewyShape().fill(Color.white.opacity(0.2))
                Rectangle()
                    .fill(Palette.aquaLight)
                    .frame(height: proxy.size.height * min(max(progress, 0.08), 1))
            }
            .clipShape(DewyShape())
        }
    }
}
