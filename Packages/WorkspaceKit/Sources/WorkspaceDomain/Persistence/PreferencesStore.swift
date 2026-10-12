/// Storage for `WorkspacePreferences` and first-launch bookkeeping.
@MainActor
public protocol PreferencesStore: AnyObject {
    /// Loads saved preferences, or defaults.
    func load() -> WorkspacePreferences
    /// Saves preferences.
    func save(_ preferences: WorkspacePreferences)
    /// Whether the sample tasks have already been seeded once.
    var hasSeededSampleTasks: Bool { get set }
}
