import Foundation

/// The surface tools and features use to read and mutate the workspace.
/// `WorkspaceStore` is the production implementation.
@MainActor
public protocol WorkspaceCommandExecutor: AnyObject, Sendable {
    /// All tasks in display order.
    var tasks: [TaskItem] { get }
    /// Current presentation preferences.
    var preferences: WorkspacePreferences { get }
    /// Performs a command, registering undo and persisting the result.
    @discardableResult
    func perform(_ command: WorkspaceCommand, actor: CommandActor) throws -> CommandResult
    /// Resolves a free-text query to tasks.
    func resolveTasks(matching query: String) -> TaskMatch
}
