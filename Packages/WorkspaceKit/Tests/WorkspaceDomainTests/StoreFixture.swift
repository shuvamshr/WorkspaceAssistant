import Foundation
@testable import WorkspaceDomain

/// Builds a store over in-memory storage with a manual-grouping undo manager.
@MainActor
struct StoreFixture {
    let store: WorkspaceStore
    let repository: InMemoryTaskRepository
    let preferences: InMemoryPreferencesStore
    let undoManager: UndoManager

    init(tasks: [TaskItem] = SampleData.tasks(now: Date(timeIntervalSince1970: 1_000_000))) {
        repository = InMemoryTaskRepository()
        preferences = InMemoryPreferencesStore()
        store = WorkspaceStore(repository: repository, preferencesStore: preferences, seed: tasks)
        undoManager = UndoManager()
        undoManager.groupsByEvent = false
        store.undoManager = undoManager
    }

    /// Performs a command inside its own undo group, as a single user event would.
    @discardableResult
    func perform(_ command: WorkspaceCommand, actor: CommandActor = .user) throws -> CommandResult {
        undoManager.beginUndoGrouping()
        defer { undoManager.endUndoGrouping() }
        return try store.perform(command, actor: actor)
    }

    func undo() { undoManager.undo() }
    func redo() { undoManager.redo() }

    func task(_ title: String) -> TaskItem? { store.tasks.first { $0.title == title } }

    /// Persisted tasks, sorted by sort index.
    func persisted() throws -> [TaskItem] { try repository.fetchAll().sorted { $0.sortIndex < $1.sortIndex } }
}
