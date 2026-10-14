import SwiftUI

/// Adds VoiceOver custom actions (Toggle Priority, Complete, Edit, Delete) to a task element.
struct TaskAccessibilityActions: ViewModifier {
    let task: TaskItem
    let onEdit: () -> Void
    @Environment(BoardModel.self) private var model

    func body(content: Content) -> some View {
        content
            .accessibilityAction(named: Text("Toggle Priority")) { model.togglePriority(task.id) }
            .accessibilityAction(named: task.isDone ? Text("Reopen") : Text("Complete")) {
                model.toggleDone(task.id)
            }
            .accessibilityAction(named: Text("Edit"), onEdit)
            .accessibilityAction(named: Text("Delete")) { model.delete([task.id]) }
    }
}

extension View {
    /// Adds the standard task custom actions for VoiceOver and Switch Control.
    func taskAccessibilityActions(_ task: TaskItem, onEdit: @escaping () -> Void) -> some View {
        modifier(TaskAccessibilityActions(task: task, onEdit: onEdit))
    }
}
