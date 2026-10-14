import SwiftUI

/// One checklist step drawn as a rounded block with a checkbox, content and a drag handle.
public struct StepBlock<Content: View>: View {
    private let isDone: Bool
    private let showsHandle: Bool
    private let onToggle: () -> Void
    private let content: Content

    public init(isDone: Bool, showsHandle: Bool = true, onToggle: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.isDone = isDone
        self.showsHandle = showsHandle
        self.onToggle = onToggle
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: Spacing.xxs) {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? Text("Mark as Not Done") : Text("Mark as Done"))
            .sensoryFeedback(.selection, trigger: isDone)

            content
                .strikethrough(isDone)
                .foregroundStyle(isDone ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsHandle {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .frame(width: 32)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .padding(.trailing, Spacing.xs)
        .background(Color(.secondarySystemGroupedBackground), in: Radius.blockShape)
    }
}

private struct StepBlockGallery: View {
    @State private var done = false
    var body: some View {
        VStack(spacing: Spacing.xs) {
            StepBlock(isDone: done, onToggle: { done.toggle() }) { Text(verbatim: "Audit URLSession call sites") }
            StepBlock(isDone: true, onToggle: {}) { Text(verbatim: "Introduce async API client") }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("Light") { StepBlockGallery() }
#Preview("Dark") { StepBlockGallery().preferredColorScheme(.dark) }
#Preview("AX5") { StepBlockGallery().dynamicTypeSize(.accessibility5) }
#Preview("RTL") { StepBlockGallery().environment(\.layoutDirection, .rightToLeft) }
