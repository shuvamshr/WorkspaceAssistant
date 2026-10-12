/// Whether a task is still to do or finished.
public enum TaskStatus: String, CaseIterable, Codable, Sendable {
    case open, done
}
