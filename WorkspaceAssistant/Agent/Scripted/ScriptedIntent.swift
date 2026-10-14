
/// One action the scripted assistant understood from a prompt.
public enum ScriptedIntent: Hashable, Sendable {
    case setPriority(query: String, TaskPriority)
    /// Prioritise (or deprioritise) every open task in a category.
    case setCategoryPriority(TaskCategory, TaskPriority)
    case complete(query: String)
    case delete(query: String)
    case addTask(title: String, category: TaskCategory, priority: TaskPriority)
    case addStep(query: String, step: String)
    case switchLayout(BoardLayout)
    case setAccent(AccentTheme)
    case setTaskColor(query: String, TileColor)
    case find(query: String)
}
