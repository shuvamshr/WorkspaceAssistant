import Foundation
import Observation
import os

/// The single source of truth the UI observes. Every mutation goes through `perform(_:actor:)`.
///
/// Each command computes its inverse before it is applied, and that inverse is registered with the
/// scene's `UndoManager`. Undoing performs the inverse, which in turn registers the redo.
@MainActor
@Observable
public final class WorkspaceStore: WorkspaceCommandExecutor {
    /// All tasks, sorted by `sortIndex`.
    public private(set) var tasks: [TaskItem] = []
    /// Presentation preferences.
    public private(set) var preferences: WorkspacePreferences
    /// Most recent commands, newest last. Capped at `activityLimit`.
    public private(set) var activity: [ActivityEntry] = []
    /// The latest change made by the assistant, for highlighting tiles.
    public private(set) var lastAssistantChange: AssistantChange?

    /// The scene's undo manager. Set by the root view.
    @ObservationIgnored public weak var undoManager: UndoManager?
    /// Supplies localised undo action names ("Undo Prioritise"). Set by the composition root.
    @ObservationIgnored public var undoActionName: (@MainActor (WorkspaceCommand) -> String?)?

    @ObservationIgnored private let repository: any TaskRepository
    @ObservationIgnored private let preferencesStore: any PreferencesStore
    private let activityLimit = 100

    /// Loads tasks and preferences, seeding the sample tasks on first launch only.
    public init(
        repository: any TaskRepository,
        preferencesStore: any PreferencesStore,
        seed: @autoclosure () -> [TaskItem] = SampleData.tasks()
    ) {
        self.repository = repository
        self.preferencesStore = preferencesStore
        preferences = preferencesStore.load()

        var loaded: [TaskItem] = []
        do {
            loaded = try repository.fetchAll()
        } catch {
            Log.persistence.error("Failed to load tasks: \(error.localizedDescription, privacy: .public)")
        }
        if loaded.isEmpty && !preferencesStore.hasSeededSampleTasks {
            loaded = seed()
            do {
                try repository.upsert(loaded)
            } catch {
                Log.persistence.error("Failed to seed tasks: \(error.localizedDescription, privacy: .public)")
            }
        }
        preferencesStore.hasSeededSampleTasks = true
        tasks = loaded.sorted(by: Self.ordering)
    }

    /// Returns the task with the given id, if it exists.
    public func task(id: UUID) -> TaskItem? {
        tasks.first { $0.id == id }
    }

    public func resolveTasks(matching query: String) -> TaskMatch {
        TaskMatcher.match(query, in: tasks)
    }

    @discardableResult
    public func perform(_ command: WorkspaceCommand, actor: CommandActor = .user) throws -> CommandResult {
        let previousPreferences = preferences
        let outcome = try apply(command)
        tasks.sort(by: Self.ordering)
        persist(outcome, preferencesChanged: previousPreferences != preferences)
        registerUndo(for: command, inverse: outcome.inverse)

        let changed = outcome.result.changedTaskIDs
        activity.append(ActivityEntry(actor: actor, command: command, changedTaskIDs: changed))
        if activity.count > activityLimit { activity.removeFirst(activity.count - activityLimit) }
        if actor == .assistant {
            lastAssistantChange = AssistantChange(taskIDs: changed)
        }
        Log.store.debug("Performed \(String(describing: command), privacy: .private) by \(actor.rawValue, privacy: .public)")
        return outcome.result
    }

    // MARK: - Applying commands

    /// What applying a command did, and how to reverse it.
    private struct Outcome {
        var result = CommandResult()
        var inverse: WorkspaceCommand?
        var upserted: [UUID] = []
        var deleted: [UUID] = []
    }

    private func apply(_ command: WorkspaceCommand) throws -> Outcome {
        switch command {
        case let .addTask(title, category, priority, origin):
            let title = try validated(title)
            let task = TaskItem(
                title: title, category: category, priority: priority, origin: origin,
                sortIndex: (tasks.map(\.sortIndex).min() ?? 0) - 1
            )
            tasks.append(task)
            return Outcome(
                result: CommandResult(affectedTaskIDs: [task.id], changedTaskIDs: [task.id], createdTaskID: task.id),
                inverse: .deleteTasks(ids: [task.id]), upserted: [task.id]
            )

        case let .insertTasks(items):
            let ids = items.map(\.id)
            tasks.removeAll { ids.contains($0.id) }
            tasks.append(contentsOf: items)
            return Outcome(
                result: CommandResult(affectedTaskIDs: ids, changedTaskIDs: ids, createdTaskID: ids.count == 1 ? ids.first : nil),
                inverse: .deleteTasks(ids: ids), upserted: ids
            )

        case let .updateTask(id, changes):
            let title = try changes.title.map(validated)
            return try mutate([id]) { task in
                if let title { task.title = title }
                if let notes = changes.notes { task.notes = notes }
                if let category = changes.category { task.category = category }
                if let priority = changes.priority { task.priority = priority }
                if let status = changes.status { task.status = status }
            }

        case let .setPriority(ids, priority):
            return try mutate(ids) { $0.priority = priority }

        case let .setStatus(ids, status):
            return try mutate(ids) { $0.status = status }

        case let .deleteTasks(ids):
            let removed = try ids.map { id in
                guard let task = task(id: id) else { throw WorkspaceError.taskNotFound(id) }
                return task
            }
            tasks.removeAll { ids.contains($0.id) }
            return Outcome(
                result: CommandResult(affectedTaskIDs: ids, changedTaskIDs: ids),
                inverse: .insertTasks(removed), deleted: ids
            )

        case let .moveTask(id, toIndex):
            guard let current = tasks.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.taskNotFound(id) }
            let others = tasks.filter { $0.id != id }
            let index = min(max(toIndex, 0), others.count)
            let newSortIndex = Self.sortIndex(at: index, in: others)
            if index == current { return Outcome(result: CommandResult(affectedTaskIDs: [id])) }
            return try mutate([id]) { $0.sortIndex = newSortIndex }

        case let .setAppearance(id, appearance):
            return try mutate([id]) { $0.appearance = appearance }

        case let .duplicateTask(id, title):
            guard let index = tasks.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.taskNotFound(id) }
            let original = tasks[index]
            let copy = TaskItem(
                title: try validated(title), notes: original.notes, category: original.category,
                priority: original.priority, status: .open, origin: .user, appearance: original.appearance,
                steps: original.steps.map { TaskStep(title: $0.title, isDone: false) },
                sortIndex: Self.sortIndex(at: index + 1, in: tasks)
            )
            tasks.append(copy)
            return Outcome(
                result: CommandResult(affectedTaskIDs: [copy.id], changedTaskIDs: [copy.id], createdTaskID: copy.id),
                inverse: .deleteTasks(ids: [copy.id]), upserted: [copy.id]
            )

        case let .addStep(taskID, title):
            let title = try validated(title)
            let step = TaskStep(title: title)
            var outcome = try mutate([taskID]) { $0.steps.append(step) }
            outcome.result.createdStepID = step.id
            return outcome

        case let .toggleStep(taskID, stepID):
            try requireStep(stepID, in: taskID)
            return try mutate([taskID]) { task in
                if let index = task.steps.firstIndex(where: { $0.id == stepID }) { task.steps[index].isDone.toggle() }
            }

        case let .renameStep(taskID, stepID, title):
            let title = try validated(title)
            try requireStep(stepID, in: taskID)
            return try mutate([taskID]) { task in
                if let index = task.steps.firstIndex(where: { $0.id == stepID }) { task.steps[index].title = title }
            }

        case let .deleteStep(taskID, stepID):
            try requireStep(stepID, in: taskID)
            return try mutate([taskID]) { $0.steps.removeAll { $0.id == stepID } }

        case let .moveSteps(taskID, fromOffsets, toOffset):
            return try mutate([taskID]) { task in
                task.steps.moveElements(fromOffsets: fromOffsets, toOffset: toOffset)
            }

        case let .replaceTasks(items):
            let existing = items.filter { item in tasks.contains { $0.id == item.id } }
            let previous = existing.compactMap { task(id: $0.id) }
            for item in existing {
                if let index = tasks.firstIndex(where: { $0.id == item.id }) { tasks[index] = item }
            }
            let changed = zip(previous, existing).filter { $0 != $1 }.map(\.1.id)
            return Outcome(
                result: CommandResult(affectedTaskIDs: existing.map(\.id), changedTaskIDs: changed),
                inverse: .replaceTasks(previous), upserted: changed
            )

        case let .setLayout(layout):
            let previous = preferences.layout
            preferences.layout = layout
            return Outcome(inverse: previous == layout ? nil : .setLayout(previous))

        case let .setAccent(accent):
            let previous = preferences.accent
            preferences.accent = accent
            return Outcome(inverse: previous == accent ? nil : .setAccent(previous))

        case let .setListDensity(density):
            let previous = preferences.listDensity
            preferences.listDensity = density
            return Outcome(inverse: previous == density ? nil : .setListDensity(previous))
        }
    }

    /// Applies `change` to each task, recording snapshots so the edit can be reversed.
    private func mutate(_ ids: [UUID], _ change: (inout TaskItem) -> Void) throws -> Outcome {
        var indices: [Int] = []
        for id in ids {
            guard let index = tasks.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.taskNotFound(id) }
            indices.append(index)
        }
        var previous: [TaskItem] = []
        var changed: [UUID] = []
        for index in indices {
            let before = tasks[index]
            change(&tasks[index])
            if tasks[index] != before {
                previous.append(before)
                changed.append(before.id)
            }
        }
        return Outcome(
            result: CommandResult(affectedTaskIDs: ids, changedTaskIDs: changed),
            inverse: previous.isEmpty ? nil : .replaceTasks(previous),
            upserted: changed
        )
    }

    private func validated(_ title: String) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WorkspaceError.emptyTitle }
        return trimmed
    }

    private func requireStep(_ stepID: UUID, in taskID: UUID) throws {
        guard let task = task(id: taskID) else { throw WorkspaceError.taskNotFound(taskID) }
        guard task.steps.contains(where: { $0.id == stepID }) else { throw WorkspaceError.stepNotFound(stepID) }
    }

    // MARK: - Side effects

    private func persist(_ outcome: Outcome, preferencesChanged: Bool) {
        do {
            let upserted = outcome.upserted.compactMap { task(id: $0) }
            if !upserted.isEmpty { try repository.upsert(upserted) }
            if !outcome.deleted.isEmpty { try repository.delete(ids: outcome.deleted) }
        } catch {
            Log.persistence.error("Failed to persist change: \(error.localizedDescription, privacy: .public)")
        }
        if preferencesChanged { preferencesStore.save(preferences) }
    }

    private func registerUndo(for command: WorkspaceCommand, inverse: WorkspaceCommand?) {
        guard let inverse, let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                do {
                    try store.perform(inverse, actor: .user)
                } catch {
                    Log.store.error("Undo failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
        if let name = undoActionName?(command) { undoManager.setActionName(name) }
    }

    // MARK: - Ordering

    private static func ordering(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        lhs.sortIndex == rhs.sortIndex ? lhs.createdAt > rhs.createdAt : lhs.sortIndex < rhs.sortIndex
    }

    /// A sort index that places an item at `index` within `ordered` (which must be sorted).
    static func sortIndex(at index: Int, in ordered: [TaskItem]) -> Double {
        switch (ordered.indices.contains(index - 1) ? ordered[index - 1] : nil, ordered.indices.contains(index) ? ordered[index] : nil) {
        case (nil, nil): 0
        case let (nil, next?): next.sortIndex - 1
        case let (previous?, nil): previous.sortIndex + 1
        case let (previous?, next?): (previous.sortIndex + next.sortIndex) / 2
        }
    }
}
