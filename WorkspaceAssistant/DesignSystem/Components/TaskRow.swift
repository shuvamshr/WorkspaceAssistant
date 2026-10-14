import SwiftUI

/// A list row: small glyph square, title, and category in secondary text.
public struct TaskRow: View {
    private let task: TaskItem
    private let density: ListDensity
    private let highlightTrigger: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(task: TaskItem, density: ListDensity = .comfortable, highlightTrigger: UUID? = nil) {
        self.task = task
        self.density = density
        self.highlightTrigger = highlightTrigger
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            GlyphSquare(task.resolvedAppearance, size: density == .compact ? .small : .medium)
                .grayscale(task.isDone ? 0.9 : 0)
                .symbolEffect(.bounce, value: reduceMotion ? nil : highlightTrigger)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(density == .compact ? .subheadline : .body)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .lineLimit(dynamicTypeSize > .large ? nil : (density == .compact ? 1 : 2))
                if density == .comfortable {
                    Text(task.tileCaption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize > .large ? nil : 1)
                }
            }
            Spacer(minLength: Spacing.xs)
            HStack(spacing: Spacing.xs) {
                if task.origin == .assistant {
                    Image(systemName: "sparkles").foregroundStyle(.secondary)
                }
                if task.isHighPriority {
                    Image(systemName: "star.fill").foregroundStyle(.tint)
                }
                if task.isDone {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .accessibilityHidden(true)
        }
        .padding(.vertical, density == .compact ? 0 : Spacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.accessibilitySummary)
    }
}

#Preview("Light") {
    List {
        ForEach(PreviewTasks.all) { TaskRow(task: $0) }
        Section("Compact") {
            ForEach(PreviewTasks.all) { TaskRow(task: $0, density: .compact) }
        }
    }
}

#Preview("Dark") {
    List(PreviewTasks.all) { TaskRow(task: $0) }.preferredColorScheme(.dark)
}

#Preview("AX5") {
    List(PreviewTasks.all) { TaskRow(task: $0) }.dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    List(PreviewTasks.all) { TaskRow(task: $0) }.environment(\.layoutDirection, .rightToLeft)
}
