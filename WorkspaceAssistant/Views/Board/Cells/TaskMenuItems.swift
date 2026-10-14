import SwiftUI

/// The shared action menu for a task, used by context menus and the tile "⋯" button.
struct TaskMenuItems: View {
    let task: TaskItem
    @Environment(BoardViewModel.self) private var model

    var body: some View {
        Button {
            model.togglePriority(task.id)
        } label: {
            if task.isHighPriority {
                Label { Text("Remove Priority") } icon: { Image(systemName: "star.slash") }
            } else {
                Label { Text("Prioritise") } icon: { Image(systemName: "star") }
            }
        }
        Button {
            model.toggleDone(task.id)
        } label: {
            if task.isDone {
                Label { Text("Reopen") } icon: { Image(systemName: "arrow.uturn.backward.circle") }
            } else {
                Label { Text("Complete") } icon: { Image(systemName: "checkmark.circle") }
            }
        }
        Button {
            model.appearanceTaskID = task.id
        } label: {
            Label { Text("Edit Appearance") } icon: { Image(systemName: "paintpalette") }
        }
        Button {
            model.duplicate(task.id)
        } label: {
            Label { Text("Duplicate") } icon: { Image(systemName: "plus.square.on.square") }
        }
        Menu {
            ForEach(TaskCategory.allCases) { category in
                Button {
                    model.move([task.id], to: category)
                } label: {
                    Label(category.displayName, systemImage: category.symbolName)
                }
                .disabled(category == task.category)
            }
        } label: {
            Label { Text("Move to…") } icon: { Image(systemName: "folder") }
        }
        Divider()
        Button(role: .destructive) {
            model.delete([task.id])
        } label: {
            Label { Text("Delete") } icon: { Image(systemName: "trash") }
        }
    }
}
