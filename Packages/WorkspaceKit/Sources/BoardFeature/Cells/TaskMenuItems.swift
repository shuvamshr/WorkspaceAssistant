import DesignSystem
import SwiftUI
import WorkspaceDomain

/// The shared action menu for a task, used by context menus and the tile "⋯" button.
struct TaskMenuItems: View {
    let task: TaskItem
    @Environment(BoardModel.self) private var model

    var body: some View {
        Button {
            model.togglePriority(task.id)
        } label: {
            if task.isHighPriority {
                Label { Text("Remove Priority", bundle: .module) } icon: { Image(systemName: "star.slash") }
            } else {
                Label { Text("Prioritise", bundle: .module) } icon: { Image(systemName: "star") }
            }
        }
        Button {
            model.toggleDone(task.id)
        } label: {
            if task.isDone {
                Label { Text("Reopen", bundle: .module) } icon: { Image(systemName: "arrow.uturn.backward.circle") }
            } else {
                Label { Text("Complete", bundle: .module) } icon: { Image(systemName: "checkmark.circle") }
            }
        }
        Button {
            model.appearanceTaskID = task.id
        } label: {
            Label { Text("Edit Appearance", bundle: .module) } icon: { Image(systemName: "paintpalette") }
        }
        Button {
            model.duplicate(task.id)
        } label: {
            Label { Text("Duplicate", bundle: .module) } icon: { Image(systemName: "plus.square.on.square") }
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
            Label { Text("Move to…", bundle: .module) } icon: { Image(systemName: "folder") }
        }
        Divider()
        Button(role: .destructive) {
            model.delete([task.id])
        } label: {
            Label { Text("Delete", bundle: .module) } icon: { Image(systemName: "trash") }
        }
    }
}
