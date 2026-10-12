import SwiftUI
import WorkspaceDomain

/// Adds VoiceOver custom actions (Toggle Priority, Complete, Edit, Delete) to a task element.
struct TaskAccessibilityActions: ViewModifier {
    let task: TaskItem
    let onEdit: () -> Void
    @Environment(BoardModel.self) private var model

    func body(content: Content) -> some View {
        content
            .accessibilityAction(named: Text("Toggle Priority", bundle: .module)) { model.togglePriority(task.id) }
            .accessibilityAction(named: task.isDone ? Text("Reopen", bundle: .module) : Text("Complete", bundle: .module)) {
                model.toggleDone(task.id)
            }
            .accessibilityAction(named: Text("Edit", bundle: .module), onEdit)
            .accessibilityAction(named: Text("Delete", bundle: .module)) { model.delete([task.id]) }
    }
}

extension View {
    /// Adds the standard task custom actions for VoiceOver and Switch Control.
    func taskAccessibilityActions(_ task: TaskItem, onEdit: @escaping () -> Void) -> some View {
        modifier(TaskAccessibilityActions(task: task, onEdit: onEdit))
    }
}
