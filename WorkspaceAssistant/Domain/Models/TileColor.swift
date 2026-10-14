/// The twelve tile colours a task can use, mirroring the Shortcuts palette.
public enum TileColor: String, CaseIterable, Codable, Sendable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, gray

    public var id: String { rawValue }
}
