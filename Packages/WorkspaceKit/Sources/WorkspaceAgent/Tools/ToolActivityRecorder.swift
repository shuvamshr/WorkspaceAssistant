import WorkspaceDomain

/// Forwards tool activity from tool calls to the engine's current response stream.
@MainActor
public final class ToolActivityRecorder: Sendable {
    /// Receives each activity while a response is streaming.
    var onActivity: ((ToolActivity) -> Void)?

    public init() {}

    func record(_ activity: ToolActivity) {
        onActivity?(activity)
    }
}
