import Foundation
import Observation
import os
import WorkspaceDomain

/// State and actions for the board: selection, sorting, presentations, and user-issued commands.
///
/// Every mutation is forwarded to `WorkspaceStore` as a `WorkspaceCommand` with `actor: .user`.
@MainActor
@Observable
public final class BoardModel {
    /// The shared store.
    public let store: WorkspaceStore

    /// Whether multi-select mode is on. Turning it off clears the selection.
    public var isSelecting = false {
        didSet { if !isSelecting { selection.removeAll() } }
    }
    /// Selected task ids in multi-select mode.
    public var selection: Set<UUID> = []
    /// Current ordering. Persisted when the model was created with `sortStorage`.
    public var sort: BoardSort = .manual {
        didSet { sortStorage?.set(sort.rawValue, forKey: Self.sortKey) }
    }
    /// Task whose appearance picker is showing.
    public var appearanceTaskID: UUID?
    /// Deletion awaiting confirmation.
    public var pendingDeletion: PendingDeletion?
    /// Presents the new-task sheet when set.
    public var newTask: NewTaskRequest?
    /// Presents the settings sheet.
    public var isShowingSettings = false
    /// Asks the visible layout to scroll to a task.
    public private(set) var revealRequest: RevealRequest?
    /// Set when a detail view should close because its task was deleted.
    public private(set) var deletedTaskIDs: Set<UUID> = []

    @ObservationIgnored private let sortStorage: UserDefaults?
    private static let sortKey = "board.sort"

    /// - Parameter sortStorage: Where to remember the sort order across launches (`nil` = don't persist).
    public init(store: WorkspaceStore, sortStorage: UserDefaults? = nil) {
        self.store = store
        self.sortStorage = sortStorage
        if let raw = sortStorage?.string(forKey: Self.sortKey), let saved = BoardSort(rawValue: raw) {
            sort = saved
        }
    }

    // MARK: - Queries

    /// Tasks for a collection in the current layout and sort order.
    public func tasks(in collection: BoardCollection) -> [TaskItem] {
        sort.sorted(collection.visibleTasks(store.tasks, layout: store.preferences.layout))
    }

    /// Number of open tasks (or done tasks, for the Done collection) in a collection, for badges.
    public func count(in collection: BoardCollection) -> Int {
        collection.visibleTasks(store.tasks, layout: .grid).count
    }

    /// Whether drag-to-reorder is available.
    public var canReorder: Bool { sort == .manual && !isSelecting }

    /// The pulse trigger for a task, if the assistant just changed it.
    public func highlightTrigger(for id: UUID) -> UUID? {
        guard let change = store.lastAssistantChange, change.taskIDs.contains(id) else { return nil }
        return change.id
    }

    // MARK: - Single-task actions

    /// Toggles high priority.
    public func togglePriority(_ id: UUID) {
        guard let task = store.task(id: id) else { return }
        perform(.setPriority(ids: [id], task.isHighPriority ? .normal : .high))
    }

    /// Toggles done/open.
    public func toggleDone(_ id: UUID) {
        guard let task = store.task(id: id) else { return }
        perform(.setStatus(ids: [id], task.isDone ? .open : .done))
    }

    /// Duplicates a task next to the original.
    public func duplicate(_ id: UUID) {
        guard let task = store.task(id: id) else { return }
        perform(.duplicateTask(id: id, title: String(localized: "\(task.title) Copy", bundle: .module)))
    }

    /// Deletes immediately (undoable).
    public func delete(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        perform(.deleteTasks(ids: ids))
        deletedTaskIDs.formUnion(ids)
        selection.subtract(ids)
    }

    /// Asks for confirmation before deleting.
    public func requestDelete(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        pendingDeletion = PendingDeletion(taskIDs: ids)
    }

    /// Performs the pending deletion.
    public func confirmPendingDeletion() {
        guard let pending = pendingDeletion else { return }
        pendingDeletion = nil
        delete(pending.taskIDs)
        isSelecting = false
    }

    /// Moves tasks to a category.
    public func move(_ ids: [UUID], to category: TaskCategory) {
        let undo = store.undoManager
        undo?.beginUndoGrouping()
        for id in ids { perform(.updateTask(id: id, changes: TaskChanges(category: category))) }
        undo?.endUndoGrouping()
    }

    /// Sets the board layout.
    public func setLayout(_ layout: BoardLayout) {
        perform(.setLayout(layout))
    }

    /// Scrolls the visible layout to a task.
    public func reveal(_ id: UUID) {
        revealRequest = RevealRequest(taskID: id)
    }

    /// Presents the new-task sheet.
    public func createTask(in collection: BoardCollection = .all) {
        newTask = NewTaskRequest(category: collection.defaultCategory)
    }

    // MARK: - Multi-select

    /// Toggles a task's selection.
    public func toggleSelection(_ id: UUID) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    /// Selected ids in display order.
    public var orderedSelection: [UUID] {
        store.tasks.map(\.id).filter(selection.contains)
    }

    /// Prioritises the selection, or removes priority if every selected task is already high.
    public func prioritiseSelection() {
        let ids = orderedSelection
        let allHigh = ids.allSatisfy { store.task(id: $0)?.isHighPriority == true }
        perform(.setPriority(ids: ids, allHigh ? .normal : .high))
        isSelecting = false
    }

    /// Completes the selection, or reopens it if every selected task is already done.
    public func completeSelection() {
        let ids = orderedSelection
        let allDone = ids.allSatisfy { store.task(id: $0)?.isDone == true }
        perform(.setStatus(ids: ids, allDone ? .open : .done))
        isSelecting = false
    }

    /// Moves the selection to a category.
    public func moveSelection(to category: TaskCategory) {
        move(orderedSelection, to: category)
        isSelecting = false
    }

    // MARK: - Reordering

    /// Applies a `List.onMove` within the visible tasks to the full task order.
    public func reorder(visible: [TaskItem], fromOffsets: IndexSet, toOffset: Int) {
        guard let from = fromOffsets.first, visible.indices.contains(from) else { return }
        let moving = visible[from]
        if toOffset > from, visible.indices.contains(toOffset - 1) {
            place(moving.id, after: visible[toOffset - 1].id)
        } else if visible.indices.contains(toOffset), visible[toOffset].id != moving.id {
            place(moving.id, before: visible[toOffset].id)
        }
    }

    /// Handles a tile dropped onto another tile: it takes the target's position.
    public func drop(_ draggedID: UUID, onto targetID: UUID, visible: [TaskItem]) {
        guard draggedID != targetID,
              let from = visible.firstIndex(where: { $0.id == draggedID }),
              let to = visible.firstIndex(where: { $0.id == targetID }) else { return }
        if to > from { place(draggedID, after: targetID) } else { place(draggedID, before: targetID) }
    }

    /// Handles a task dropped onto a Board column.
    public func drop(_ id: UUID, into column: BoardColumn) {
        guard let task = store.task(id: id), BoardColumn.of(task) != column else { return }
        perform(.updateTask(id: id, changes: column.changes))
    }

    private func place(_ id: UUID, before targetID: UUID) {
        let others = store.tasks.filter { $0.id != id }
        guard let index = others.firstIndex(where: { $0.id == targetID }) else { return }
        perform(.moveTask(id: id, toIndex: index))
    }

    private func place(_ id: UUID, after targetID: UUID) {
        let others = store.tasks.filter { $0.id != id }
        guard let index = others.firstIndex(where: { $0.id == targetID }) else { return }
        perform(.moveTask(id: id, toIndex: index + 1))
    }

    // MARK: - Commands

    /// Performs a user command, logging failures.
    @discardableResult
    public func perform(_ command: WorkspaceCommand) -> CommandResult? {
        do {
            return try store.perform(command, actor: .user)
        } catch {
            Log.ui.error("Command failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}
