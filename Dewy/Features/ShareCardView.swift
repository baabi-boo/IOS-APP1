import SwiftUI

/// Previews today's collectible cotton-rag storybook postcard and hands it to the system share sheet.
///
/// The postcard is rendered completely static (`animated: false`) so `ImageRenderer` exports
/// the exact frame shown in the preview.
struct ShareDaySheet: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: Image?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            header
                .padding(.horizontal, 22)
                .padding(.top, 24)

            GeometryReader { proxy in
                let scale = min(
                    1,
                    (proxy.size.width - 40) / ShareDayCard.size.width,
                    (proxy.size.height - 24) / ShareDayCard.size.height
                )
                ShareDayCard(store: store, theme: theme)
                    .scaleEffect(appeared ? scale : scale * 0.92)
                    .rotationEffect(.degrees(appeared ? -1.5 : 0))
                    .opacity(appeared ? 1 : 0)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }

            shareButton
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
        }
        .background(theme.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .onAppear {
            render()
            withAnimation(.spring(response: 0.56, dampingFraction: 0.76).delay(0.05)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Daily postcard", color: theme.inkSoft, size: 10.5)
                Text("Share your day")
                    .font(.display(28, .bold))
                    .tracking(-0.4)
                    .foregroundStyle(theme.ink)
            }
            Spacer()
            CircleIconButton(systemImage: "xmark") { dismiss() }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let rendered {
            ShareLink(item: rendered, preview: SharePreview("My Dewy day", image: rendered)) {
                HStack(spacing: 9) {
                    Text("Share postcard")
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                }
                .font(.display(19.5, .semibold))
                .foregroundStyle(theme.onAccent)
                .shadow(color: theme.accentDeep.opacity(0.28), radius: 0, x: 0, y: 0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .contentShape(Capsule())
            }
            .buttonStyle(StampButtonStyle(fill: theme.accent, lip: theme.accentDeep, depth: 3.5))
            .shadow(color: theme.accentDeep.opacity(0.18), radius: 10, x: 0, y: 6)
        } else {
            ProgressView()
                .tint(theme.accent)
                .frame(height: 62)
        }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: ShareDayExport(store: store, theme: theme))
        renderer.scale = 3
        renderer.isOpaque = true
        if let image = renderer.uiImage {
            rendered = Image(uiImage: image)
        }
    }
}

// MARK: - Export

/// The postcard framed on a warm cotton-paper mat so its subtle elevation shadow exports cleanly.
private struct ShareDayExport: View {
    var store: HydrationStore
    var theme: AppTheme

    var body: some View {
        ShareDayCard(store: store, theme: theme)
            .padding(28)
            .background(Palette.cream)
    }
}

// MARK: - Collectible Storybook Postcard

private struct ShareDayCard: View {
    var store: HydrationStore
    var theme: AppTheme

    static let size = CGSize(width: 320, height: 488)
    private static let sceneHeight: CGFloat = 216
    private static let contentWidth: CGFloat = 280

    private var percent: Int { Int((store.todayProgress * 100).rounded()) }
    private var isNight: Bool { theme.phase().isNight }

    var body: some View {
        let outerShape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        VStack(spacing: 0) {
            scene
                .padding(.horizontal, 12)
                .padding(.top, 12)
            stats
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 16)
            Spacer(minLength: 0)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            PaperSurface(shape: outerShape, fill: Palette.paper, tint: Palette.shadow, elevation: 1.0)
        }
        .overlay(outerShape.strokeBorder(Ink.hairlineStrong, lineWidth: 1))
        .environment(\.dewyTheme, theme)
    }

    // MARK: Scene

    private var scene: some View {
        let frameShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return ZStack(alignment: .bottom) {
            ClayWorld(horizon: 128, animated: false, decor: store.placedDecor)

            ZStack(alignment: .bottom) {
                LilyPad(width: 112, animated: false)
                MascotView(
                    progress: store.todayProgress,
                    mood: store.mood,
                    size: 104,
                    outfits: store.outfits,
                    sparkles: store.todayProgress >= 1,
                    bands: store.todayBands,
                    backdrop: .color,
                    animated: false,
                    showsShadow: false,
                    isNight: isNight
                )
                .padding(.bottom, 15)
            }
            .padding(.bottom, 4)
        }
        .frame(height: Self.sceneHeight)
        .frame(maxWidth: .infinity)
        .clipShape(frameShape)
        .overlay(frameShape.strokeBorder(Ink.hairlineStrong, lineWidth: 1))
        // Tucked neatly top-trailing so Lagoon's left palm island and Seaside's lighthouse stay clear.
        .overlay(alignment: .topTrailing) {
            drinksChip
                .padding(11)
        }
    }

    /// Today's sipped drink vessels in a compact cotton-paper pill.
    @ViewBuilder
    private var drinksChip: some View {
        let kinds = Array(Set(store.todayEntries.map(\.kind))).sorted { $0.rawValue < $1.rawValue }.prefix(4)
        if !kinds.isEmpty {
            HStack(spacing: -3) {
                ForEach(Array(kinds)) { kind in
                    DrinkIcon(kind: kind, size: 22)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(Palette.paper.opacity(0.92), in: Capsule())
            .overlay(Capsule().stroke(Ink.hairline, lineWidth: 1))
        }
    }

    // MARK: Numbers

    private var stats: some View {
        VStack(spacing: 12) {
            VStack(spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(store.format(store.todayTotal, withUnit: false))
                        .font(.display(48, .bold))
                        .tracking(-0.8)
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(store.profile.unit.label)
                        .font(.display(19, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                Text("of \(store.format(store.goal)) today")
                    .font(.editorialItalic(14.5))
                    .foregroundStyle(theme.inkSoft)
            }

            progressBar

            HStack(spacing: 8) {
                ShareStatTile(value: "\(percent)%", label: "of goal", tint: Palette.aquaSoft, labelColor: Palette.aquaDeep) {
                    DewyShape()
                        .fill(Palette.aqua)
                        .overlay(DewyShape().stroke(Ink.primary.opacity(0.35), lineWidth: 0.8))
                        .frame(width: 16, height: 21)
                }
                ShareStatTile(value: "\(store.currentStreak)", label: "day streak", tint: Palette.butterSoft, labelColor: Palette.butterDeep) {
                    ClayIcon(glyph: .flame, size: 22)
                }
                ShareStatTile(value: "+\(store.todayDrops)", label: "drops", tint: Palette.coralSoft, labelColor: Palette.coralDeep) {
                    ClayIcon(glyph: .drop, size: 22)
                }
            }

            footer
        }
    }

    private var progressBar: some View {
        let fraction = CGFloat(min(max(store.todayProgress, 0), 1))
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(theme.well)
                .overlay(Capsule().stroke(Ink.hairline, lineWidth: 1))
            if fraction > 0 {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Palette.aquaLight, Palette.aqua],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(Capsule().stroke(Palette.aquaDeep.opacity(0.3), lineWidth: 0.75))
                    .frame(width: max(12, Self.contentWidth * fraction))
                    .padding(1)
            }
        }
        .frame(width: Self.contentWidth, height: 11)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            DewyShape()
                .fill(Palette.aqua)
                .overlay(DewyShape().stroke(Ink.primary.opacity(0.35), lineWidth: 0.7))
                .frame(width: 11, height: 15)
            Text("dewy")
                .font(.display(17, .bold))
                .foregroundStyle(Palette.aquaDeep)
            Spacer(minLength: 0)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.dewy(11.5, .bold))
                .foregroundStyle(theme.inkSoft)
        }
    }
}

/// Matte watercolor-tinted postcard stat medallion.
private struct ShareStatTile<Icon: View>: View {
    let value: String
    let label: String
    let tint: Color
    let labelColor: Color
    let icon: Icon

    init(value: String, label: String, tint: Color, labelColor: Color, @ViewBuilder icon: () -> Icon) {
        self.value = value
        self.label = label
        self.tint = tint
        self.labelColor = labelColor
        self.icon = icon()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        VStack(spacing: 3) {
            icon
                .frame(width: 24, height: 24)
            Text(value)
                .font(.display(18, .semibold))
                .monospacedDigit()
                .foregroundStyle(Ink.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.dewy(10.5, .bold))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            shape
                .fill(tint)
                .overlay(shape.stroke(Ink.hairline, lineWidth: 1))
        }
    }
}
