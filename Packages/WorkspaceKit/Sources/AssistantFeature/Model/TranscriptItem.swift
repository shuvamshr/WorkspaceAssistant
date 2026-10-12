import Foundation
import WorkspaceDomain

/// One entry in the assistant transcript.
public struct TranscriptItem: Identifiable, Hashable, Sendable {
    /// What the entry shows.
    public enum Content: Hashable, Sendable {
        case user(String)
        /// Assistant reply text; `isStreaming` while it's still arriving.
        case assistant(String, isStreaming: Bool)
        case action(ToolActivity)
        case notice(AssistantNotice)
    }

    public let id: UUID
    public let date: Date
    public var content: Content

    public init(id: UUID = UUID(), date: Date = .now, content: Content) {
        self.id = id
        self.date = date
        self.content = content
    }
}

/// A system note in the transcript (errors, stops).
public enum AssistantNotice: Hashable, Sendable {
    case error(AssistantError)
    case stopped
}
