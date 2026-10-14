import SwiftUI

/// A Shortcuts-style task tile: solid colour with a subtle gradient, glyph top-leading, title bottom-leading.
///
/// The top-trailing corner is reserved for a `TileMenuButton` overlay (or the selection indicator).
public struct TaskTile: View {
    /// Tile sizes for the different layouts.
    public enum Size: Sendable {
        /// Grid tile.
        case regular
        /// Full-width Focus tile with two lines of detail and a progress ring.
        case large
        /// Compact Board-column tile.
        case mini
    }

    private let task: TaskItem
    private let size: Size
    private let isSelected: Bool?
    private let highlightTrigger: UUID?

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var regularMinHeight: CGFloat = 116
    @ScaledMetric(relativeTo: .headline) private var largeMinHeight: CGFloat = 140
    @ScaledMetric(relativeTo: .subheadline) private var miniMinHeight: CGFloat = 60
    @ScaledMetric(relativeTo: .body) private var glyphCircle: CGFloat = 40

    /// - Parameters:
    ///   - isSelected: `nil` when not in selection mode; otherwise whether the tile is selected.
    ///   - highlightTrigger: Changing this value plays the "assistant changed me" pulse.
    public init(task: TaskItem, size: Size = .regular, isSelected: Bool? = nil, highlightTrigger: UUID? = nil) {
        self.task = task
        self.size = size
        self.isSelected = isSelected
        self.highlightTrigger = highlightTrigger
    }

    private var appearance: TileAppearance { task.resolvedAppearance }

    public var body: some View {
        content
            .foregroundStyle(appearance.color.foreground)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background {
                Radius.tileShape
                    .fill(appearance.color.background(contrast: contrast, solid: size == .mini))
                    .grayscale(task.isDone ? 0.9 : 0)
            }
            .overlay(alignment: .topTrailing) { selectionIndicator }
            .overlay {
                if isSelected == true {
                    Radius.tileShape.strokeBorder(.tint, lineWidth: 3).padding(-5)
                }
            }
            .contentShape(Radius.tileShape)
            .phaseAnimator([false, true], trigger: highlightTrigger) { view, pulsing in
                view
                    .scaleEffect(pulsing && !reduceMotion ? 1.04 : 1)
                    .shadow(color: appearance.color.color.opacity(pulsing ? 0.55 : 0), radius: pulsing ? 14 : 0)
            } animation: { _ in
                reduceMotion ? .easeInOut(duration: 0.3) : .spring(duration: 0.35, bounce: 0.4)
            }
            .accessibilityIgnoresInvertColors()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(task.accessibilitySummary)
            .accessibilityAddTraits(isSelected == true ? .isSelected : [])
    }

    /// Line limits apply at standard text sizes; larger sizes let text wrap fully instead of truncating.
    private func lineLimit(_ standard: Int) -> Int? {
        dynamicTypeSize > .large ? nil : standard
    }

    private var minHeight: CGFloat {
        switch size {
        case .regular: regularMinHeight
        case .large: largeMinHeight
        case .mini: miniMinHeight
        }
    }

    @ViewBuilder private var content: some View {
        switch size {
        case .regular: regularContent
        case .large: largeContent
        case .mini: miniContent
        }
    }

    private var glyph: some View {
        Image(systemName: appearance.glyph)
            .font(.title2.weight(.semibold))
            .frame(width: glyphCircle, height: glyphCircle)
            .background(.black.opacity(0.14), in: Circle())
            .symbolEffect(.bounce, value: reduceMotion ? nil : highlightTrigger)
            .accessibilityHidden(true)
    }

    private var regularContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .center, spacing: Spacing.xs) {
                glyph
                TaskBadges(task: task).font(.caption.weight(.bold))
                Spacer(minLength: 0)
            }
            .padding(.trailing, 32)
            Spacer(minLength: Spacing.s)
            Text(task.title)
                .font(.headline)
                .lineLimit(lineLimit(3))
                .multilineTextAlignment(.leading)
            Text(task.tileCaption)
                .font(.caption.weight(.medium))
                .lineLimit(lineLimit(1))
        }
        .padding(Spacing.s)
    }

    private var largeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .center, spacing: Spacing.xs) {
                glyph
                TaskBadges(task: task).font(.subheadline.weight(.bold))
                Spacer(minLength: 44)
            }
            Spacer(minLength: Spacing.xs)
            HStack(alignment: .bottom, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(task.title)
                        .font(.title3.bold())
                        .lineLimit(lineLimit(2))
                        .multilineTextAlignment(.leading)
                    Text(largeDetail)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if let progress = task.stepProgress {
                    ProgressRing(progress: progress)
                }
            }
        }
        .padding(Spacing.m)
    }

    private var largeDetail: String {
        let notes = task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes.isEmpty ? task.tileCaption : "\(task.tileCaption) · \(notes)"
    }

    private var miniContent: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: appearance.glyph)
                .font(.subheadline.weight(.semibold))
                .symbolEffect(.bounce, value: reduceMotion ? nil : highlightTrigger)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(lineLimit(2))
                    .multilineTextAlignment(.leading)
                TaskBadges(task: task).font(.caption2.weight(.bold))
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.s)
    }

    @ViewBuilder private var selectionIndicator: some View {
        if let isSelected {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.black.opacity(0.18)))
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
    }
}

#Preview("Grid · Light") {
    TileGalleryPreview()
}

#Preview("Grid · Dark") {
    TileGalleryPreview().preferredColorScheme(.dark)
}

#Preview("AX5") {
    ScrollView {
        TaskTile(task: PreviewTasks.highPriority, size: .regular).padding()
        TaskTile(task: PreviewTasks.highPriority, size: .large).padding()
    }
    .dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    TileGalleryPreview().environment(\.layoutDirection, .rightToLeft)
}
