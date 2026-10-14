import SwiftUI

/// The task editor for a stored task, pushed from the board with a zoom transition.
public struct TaskDetailView: View {
    private let taskID: UUID
    private let onDeleted: () -> Void
    @Environment(BoardViewModel.self) private var model

    /// - Parameter onDeleted: Called when the task disappears (deleted here or elsewhere).
    public init(taskID: UUID, onDeleted: @escaping () -> Void) {
        self.taskID = taskID
        self.onDeleted = onDeleted
    }

    public var body: some View {
        Group {
            if let task = model.store.task(id: taskID) {
                TaskEditorForm(task: task, commitsLive: false, apply: { apply($0, to: task) }) {
                    model.appearanceTaskID = taskID
                }
                .toolbar { toolbar(task) }
            } else {
                ContentUnavailableView {
                    Label { Text("Task Deleted") } icon: { Image(systemName: "trash") }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // The editor gets the full screen; nothing is layered under the tab bar while editing.
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.systemGroupedBackground))
        .onChange(of: model.store.task(id: taskID) == nil) { _, isGone in
            if isGone { onDeleted() }
        }
    }

    @ToolbarContentBuilder private func toolbar(_ task: TaskItem) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    model.duplicate(task.id)
                } label: {
                    Label { Text("Duplicate") } icon: { Image(systemName: "plus.square.on.square") }
                }
                ShareLink(item: task.plainTextExport, subject: Text(task.title)) {
                    Label { Text("Share") } icon: { Image(systemName: "square.and.arrow.up") }
                }
                Divider()
                Button(role: .destructive) {
                    model.requestDelete([task.id])
                } label: {
                    Label { Text("Delete") } icon: { Image(systemName: "trash") }
                }
            } label: {
                Label { Text("More") } icon: { Image(systemName: "ellipsis") }
            }
        }
    }

    private func apply(_ edit: TaskEdit, to task: TaskItem) {
        let commands = edit.commands(for: task)
        let undoManager = model.store.undoManager
        if commands.count > 1 { undoManager?.beginUndoGrouping() }
        for command in commands { model.perform(command) }
        if commands.count > 1 { undoManager?.endUndoGrouping() }
    }
}
