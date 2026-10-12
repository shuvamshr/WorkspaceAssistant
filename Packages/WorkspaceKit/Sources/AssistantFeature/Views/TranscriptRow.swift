import DesignSystem
import SwiftUI
import WorkspaceDomain

/// Renders one transcript entry.
struct TranscriptRow: View {
    let item: TranscriptItem
    let isLatestAction: Bool
    let onSelectTask: (UUID) -> Void
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        switch item.content {
        case let .user(text): userBubble(text)
        case let .assistant(text, isStreaming): assistantText(text, isStreaming: isStreaming)
        case let .action(activity): actionBlock(activity)
        case let .notice(notice): noticeRow(notice)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: Spacing.xxl)
            Text(text)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, Spacing.xs)
                .foregroundStyle(.white)
                .background(.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("You: \(text)", bundle: .module))
    }

    private func assistantText(_ text: String, isStreaming: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: isStreaming)
                .accessibilityHidden(true)
            Text(text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Assistant: \(text)", bundle: .module))
    }

    private func actionBlock(_ activity: ToolActivity) -> some View {
        let block = ActionBlock(
            glyph: activity.kind.glyph,
            color: activity.kind.color,
            parts: activity.blockParts,
            failureReason: activity.succeeded ? nil : activity.failureReason,
            accessibilitySentence: activity.spokenSentence
        ) {
            if activity.kind == .deleteTask, activity.succeeded, isLatestAction, undoManager?.canUndo == true {
                Button {
                    undoManager?.undo()
                } label: {
                    Text("Undo", bundle: .module)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        return Group {
            if let taskID = activity.referencedTaskID, activity.kind != .deleteTask {
                Button { onSelectTask(taskID) } label: { block }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Shows this task on the board", bundle: .module))
            } else {
                block
            }
        }
    }

    private func noticeRow(_ notice: AssistantNotice) -> some View {
        Group {
            switch notice {
            case .stopped:
                Label { Text("Stopped", bundle: .module) } icon: { Image(systemName: "stop.circle") }
                    .foregroundStyle(.secondary)
            case let .error(error):
                Label { Text(AssistantCopy.message(for: error)) } icon: { Image(systemName: "exclamationmark.bubble") }
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
