/// A `PreferencesStore` that keeps values in memory. For previews and tests.
@MainActor
public final class InMemoryPreferencesStore: PreferencesStore {
    private var preferences: WorkspacePreferences
    public var hasSeededSampleTasks: Bool

    public init(preferences: WorkspacePreferences = WorkspacePreferences(), hasSeededSampleTasks: Bool = false) {
        self.preferences = preferences
        self.hasSeededSampleTasks = hasSeededSampleTasks
    }

    public func load() -> WorkspacePreferences { preferences }

    public func save(_ preferences: WorkspacePreferences) { self.preferences = preferences }
}
