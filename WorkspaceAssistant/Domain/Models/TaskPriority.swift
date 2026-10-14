/// How important a task is. An enum rather than a `Bool` so more levels can be added later.
public enum TaskPriority: String, CaseIterable, Codable, Sendable {
    case normal, high
}
