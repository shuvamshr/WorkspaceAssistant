/// Presentation preferences. Stored outside SwiftData via a `PreferencesStore`.
public struct WorkspacePreferences: Hashable, Codable, Sendable {
    public var layout: BoardLayout
    public var accent: AccentTheme
    public var listDensity: ListDensity

    public init(layout: BoardLayout = .grid, accent: AccentTheme = .indigo, listDensity: ListDensity = .comfortable) {
        self.layout = layout
        self.accent = accent
        self.listDensity = listDensity
    }
}
