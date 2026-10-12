import Foundation

/// Reasons a command can be rejected.
public enum WorkspaceError: Error, Hashable, Sendable {
    case taskNotFound(UUID)
    case stepNotFound(UUID)
    case emptyTitle
}
