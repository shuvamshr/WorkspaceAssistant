/// App-wide tint choices. `indigo` is the default.
public enum AccentTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    case indigo, blue, teal, green, orange, red, purple

    public var id: String { rawValue }
}
