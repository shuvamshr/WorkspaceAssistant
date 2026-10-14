/// Who issued a command. Lets the UI show what the assistant changed.
public enum CommandActor: String, Sendable, Codable {
    case user, assistant
}
