import Foundation

/// Behaviour switches read from launch arguments (used by UI tests and design review).
struct LaunchConfiguration {
    /// `-UITestScriptedAssistant`: in-memory storage and the scripted assistant.
    let isUITest: Bool
    /// `-DesignGallery`: show the design-system gallery instead of the app.
    let showsDesignGallery: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isUITest = arguments.contains("-UITestScriptedAssistant")
        showsDesignGallery = arguments.contains("-DesignGallery")
    }

    /// Whether to avoid touching persistent storage.
    var usesEphemeralStorage: Bool { isUITest }
}
