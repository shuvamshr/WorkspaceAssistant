/// The four ways the board can present tasks. `grid` is the default.
public enum BoardLayout: String, CaseIterable, Codable, Sendable, Identifiable {
    case grid, list, focus, board

    public var id: String { rawValue }
}
