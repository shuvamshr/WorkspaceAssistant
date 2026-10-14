import os

/// Shared `Logger` categories for the workspace modules.
public enum Log {
    static let subsystem = "au.edu.uts.WorkspaceAssistant"
    /// Store and command processing.
    public static let store = Logger(subsystem: subsystem, category: "store")
    /// Persistence and storage.
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    /// Assistant engines and tools.
    public static let agent = Logger(subsystem: subsystem, category: "agent")
    /// UI-level events.
    public static let ui = Logger(subsystem: subsystem, category: "ui")
}
