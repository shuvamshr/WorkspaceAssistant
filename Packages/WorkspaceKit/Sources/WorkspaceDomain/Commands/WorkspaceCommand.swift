import Foundation

/// Every mutation of workspace state, whether issued by the user or by the assistant.
///
/// Adding a capability means adding a case here, a handler in `WorkspaceStore`, and optionally a tool.
public enum WorkspaceCommand: Hashable, Sendable {
    case addTask(title: String, category: TaskCategory, priority: TaskPriority, origin: TaskOrigin)
    /// Inserts fully-formed tasks (new-task sheet, undo of delete). Existing ids are replaced.
    case insertTasks([TaskItem])
    case updateTask(id: UUID, changes: TaskChanges)
    case setPriority(ids: [UUID], TaskPriority)
    case setStatus(ids: [UUID], TaskStatus)
    case deleteTasks(ids: [UUID])
    /// Moves a task so it ends up at `toIndex` in the full ordered task list.
    case moveTask(id: UUID, toIndex: Int)
    case setAppearance(id: UUID, TileAppearance?)
    /// Duplicates a task directly after the original, using `title` for the copy.
    case duplicateTask(id: UUID, title: String)
    case addStep(taskID: UUID, title: String)
    case toggleStep(taskID: UUID, stepID: UUID)
    case renameStep(taskID: UUID, stepID: UUID, title: String)
    case deleteStep(taskID: UUID, stepID: UUID)
    case moveSteps(taskID: UUID, fromOffsets: IndexSet, toOffset: Int)
    /// Restores task snapshots wholesale. Used as the inverse of field-level edits.
    case replaceTasks([TaskItem])
    case setLayout(BoardLayout)
    case setAccent(AccentTheme)
    case setListDensity(ListDensity)
}
