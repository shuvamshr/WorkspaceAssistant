/// Result of resolving a free-text query to tasks.
public enum TaskMatch: Hashable, Sendable {
    case none
    case unique(TaskItem)
    case ambiguous([TaskItem])
}
