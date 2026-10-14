import Foundation

/// Behaviour switches read from launch arguments (used by UI tests and design review).
/// They only take effect in DEBUG builds; release builds always use real storage and the app UI.
struct LaunchConfiguration {
    /// `-UITestScriptedAssistant`: in-memory storage and the scripted assistant.
    let isUITest: Bool
    /// `-DesignGallery`: show the design-system gallery instead of the app.
    let showsDesignGallery: Bool

    /// Set when the app is hosting the unit test bundle; it then avoids the on-disk store.
    let isUnitTestHost: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments, environment: [String: String] = ProcessInfo.processInfo.environment) {
        #if DEBUG
        isUnitTestHost = environment["XCTestConfigurationFilePath"] != nil
        isUITest = arguments.contains("-UITestScriptedAssistant")
        showsDesignGallery = arguments.contains("-DesignGallery")
        #else
        isUnitTestHost = false
        isUITest = false
        showsDesignGallery = false
        #endif
    }

    /// Whether to avoid touching persistent storage.
    var usesEphemeralStorage: Bool { isUITest || isUnitTestHost }
}
