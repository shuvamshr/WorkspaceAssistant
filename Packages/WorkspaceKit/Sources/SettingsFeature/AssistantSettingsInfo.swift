/// What the settings screen shows about the assistant, supplied by the composition root.
public struct AssistantSettingsInfo {
    /// Short status, e.g. "Apple Intelligence" or "Simulated assistant".
    public var status: String
    /// Longer explanation of the status.
    public var detail: String
    /// Whether there is a conversation to clear.
    public var hasConversation: Bool
    /// Clears the conversation only (never tasks or layout).
    public var clearConversation: () -> Void

    public init(status: String, detail: String, hasConversation: Bool, clearConversation: @escaping () -> Void) {
        self.status = status
        self.detail = detail
        self.hasConversation = hasConversation
        self.clearConversation = clearConversation
    }
}
