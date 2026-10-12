/// Who created a task.
public enum TaskOrigin: String, CaseIterable, Codable, Sendable {
    case user, assistant
}
