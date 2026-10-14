import SwiftUI

/// An inset-grouped list with swipe actions, reordering and a density setting.
struct ListLayoutView: View {
    let tasks: [TaskItem]
    let onOpen: (UUID) -> Void
    @Environment(BoardModel.self) private var model

    var body: some View {
        @Bindable var model = model
        ScrollViewReader { proxy in
            List(selection: $model.selection) {
                ForEach(tasks) { task in
                    row(task)
                }
                .onMove(perform: model.canReorder ? { from, to in
                    model.reorder(visible: tasks, fromOffsets: from, toOffset: to)
                } : nil)
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(model.isSelecting ? .active : .inactive))
            .revealsTasks(with: proxy)
        }
    }

    private func row(_ task: TaskItem) -> some View {
        Button {
            onOpen(task.id)
        } label: {
            TaskRow(task: task, density: model.store.preferences.listDensity, highlightTrigger: model.highlightTrigger(for: task.id))
        }
        .foregroundStyle(.primary)
        .tag(task.id)
        .id(task.id)
        .swipeActions(edge: .leading) {
            Button {
                model.togglePriority(task.id)
            } label: {
                if task.isHighPriority {
                    Label { Text("Remove Priority") } icon: { Image(systemName: "star.slash") }
                } else {
                    Label { Text("Prioritise") } icon: { Image(systemName: "star.fill") }
                }
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                model.delete([task.id])
            } label: {
                Label { Text("Delete") } icon: { Image(systemName: "trash") }
            }
            Button {
                model.toggleDone(task.id)
            } label: {
                if task.isDone {
                    Label { Text("Reopen") } icon: { Image(systemName: "arrow.uturn.backward") }
                } else {
                    Label { Text("Complete") } icon: { Image(systemName: "checkmark") }
                }
            }
            .tint(.green)
        }
        .contextMenu { TaskMenuItems(task: task) } preview: { TaskTile(task: task, size: .large).frame(width: 320) }
        .accessibilityElement(children: .combine)
        .taskAccessibilityActions(task) { onOpen(task.id) }
    }
}
