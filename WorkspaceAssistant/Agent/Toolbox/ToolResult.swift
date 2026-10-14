
/// The outcome of a toolbox operation: a factual message for the model and an activity for the UI.
public struct ToolResult: Hashable, Sendable {
    /// Plain-English, truthful result returned to the language model.
    public let message: String
    /// Structured record for the transcript's action block.
    public let activity: ToolActivity
}
