import SwiftUI

/// An interactive tile: tap to open (or select), "⋯" menu, context menu with preview,
/// drag to reorder, VoiceOver custom actions, pointer hover and keyboard focus.
struct TaskTileCell: View {
    let task: TaskItem
    var size: TaskTile.Size = .regular
    let namespace: Namespace.ID
    let onOpen: (UUID) -> Void
    @Environment(BoardViewModel.self) private var model

    var body: some View {
        let selecting = model.isSelecting
        ZStack(alignment: .topTrailing) {
            Button {
                if selecting { model.toggleSelection(task.id) } else { onOpen(task.id) }
            } label: {
                TaskTile(
                    task: task,
                    size: size,
                    isSelected: selecting ? model.selection.contains(task.id) : nil,
                    highlightTrigger: model.highlightTrigger(for: task.id)
                )
            }
            .buttonStyle(TileButtonStyle())
            .hoverEffect(.lift)
            .matchedTransitionSource(id: task.id, in: namespace)

            if !selecting && size != .mini {
                TileMenuButton { TaskMenuItems(task: task) }
                    .padding(Spacing.xxs)
            }
        }
        .contextMenu {
            TaskMenuItems(task: task)
        } preview: {
            TaskTile(task: task, size: .large)
                .frame(width: 320)
        }
        .draggable(TaskDragItem(id: task.id)) {
            TaskTile(task: task, size: .mini).frame(width: 200)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.accessibilitySummary)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selecting && model.selection.contains(task.id) ? .isSelected : [])
        .accessibilityAction {
            if selecting { model.toggleSelection(task.id) } else { onOpen(task.id) }
        }
        .taskAccessibilityActions(task) { onOpen(task.id) }
        .id(task.id)
    }
}
