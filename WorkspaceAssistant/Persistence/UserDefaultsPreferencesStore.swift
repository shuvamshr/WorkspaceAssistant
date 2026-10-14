import Foundation

/// A `PreferencesStore` backed by `UserDefaults` (the same storage `@AppStorage` uses).
@MainActor
public final class UserDefaultsPreferencesStore: PreferencesStore {
    private enum Key {
        static let layout = "preferences.layout"
        static let accent = "preferences.accent"
        static let listDensity = "preferences.listDensity"
        static let seeded = "preferences.hasSeededSampleTasks"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> WorkspacePreferences {
        let fallback = WorkspacePreferences()
        return WorkspacePreferences(
            layout: defaults.string(forKey: Key.layout).flatMap(BoardLayout.init(rawValue:)) ?? fallback.layout,
            accent: defaults.string(forKey: Key.accent).flatMap(AccentTheme.init(rawValue:)) ?? fallback.accent,
            listDensity: defaults.string(forKey: Key.listDensity).flatMap(ListDensity.init(rawValue:)) ?? fallback.listDensity
        )
    }

    public func save(_ preferences: WorkspacePreferences) {
        defaults.set(preferences.layout.rawValue, forKey: Key.layout)
        defaults.set(preferences.accent.rawValue, forKey: Key.accent)
        defaults.set(preferences.listDensity.rawValue, forKey: Key.listDensity)
    }

    public var hasSeededSampleTasks: Bool {
        get { defaults.bool(forKey: Key.seeded) }
        set { defaults.set(newValue, forKey: Key.seeded) }
    }
}
