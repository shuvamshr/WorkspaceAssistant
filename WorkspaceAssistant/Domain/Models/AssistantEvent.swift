/// Events streamed by an `AssistantEngine` while it answers a prompt.
public enum AssistantEvent: Hashable, Sendable {
    /// A tool ran (successfully or not).
    case toolCalled(ToolActivity)
    /// The reply so far (cumulative, not a delta).
    case partialText(String)
    /// The final reply.
    case completed(String)
}
