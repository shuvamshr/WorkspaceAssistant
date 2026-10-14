import Foundation
import Testing
@testable import WorkspaceAssistant

@MainActor
@Suite("WorkspaceStore commands and undo")
struct WorkspaceStoreTests {
    let fixture = StoreFixture()
    var store: WorkspaceStore { fixture.store }
    var network: TaskItem { fixture.task("Refactor Network Layer")! }

    @Test func seedsSampleTasksOnFirstLaunchOnly() throws {
        #expect(store.tasks.map(\.title) == SampleData.tasks().map(\.title))
        #expect(fixture.preferences.hasSeededSampleTasks)

        try fixture.perform(.deleteTasks(ids: store.tasks.map(\.id)))
        let relaunched = WorkspaceStore(repository: fixture.repository, preferencesStore: fixture.preferences)
        #expect(relaunched.tasks.isEmpty)
    }

    @Test func addTaskInsertsAtTopAndUndoRemovesIt() throws {
        let result = try fixture.perform(.addTask(title: "  Code review \n", category: .development, priority: .high, origin: .assistant))
        let created = try #require(result.createdTaskID.flatMap(store.task(id:)))
        #expect(created.title == "Code review")
        #expect(created.priority == .high)
        #expect(created.origin == .assistant)
        #expect(store.tasks.first?.id == created.id)
        #expect(try fixture.persisted().contains { $0.id == created.id })

        fixture.undo()
        #expect(store.task(id: created.id) == nil)
        #expect(try !fixture.persisted().contains { $0.id == created.id })

        fixture.redo()
        #expect(store.task(id: created.id)?.title == "Code review")
    }

    @Test func addTaskRejectsBlankTitle() {
        #expect(throws: WorkspaceError.emptyTitle) {
            try fixture.perform(.addTask(title: " \n ", category: .design, priority: .normal, origin: .user))
        }
    }

    @Test func insertTasksAndUndo() throws {
        let item = TaskItem(title: "Draft", category: .design, sortIndex: 99)
        try fixture.perform(.insertTasks([item]))
        #expect(store.tasks.last == item)
        fixture.undo()
        #expect(store.task(id: item.id) == nil)
    }

    @Test func updateTaskChangesOnlyGivenFieldsAndUndoRestores() throws {
        let original = network
        try fixture.perform(.updateTask(id: original.id, changes: TaskChanges(title: "Network v2", notes: "Use async/await")))
        let updated = try #require(store.task(id: original.id))
        #expect(updated.title == "Network v2")
        #expect(updated.notes == "Use async/await")
        #expect(updated.category == original.category)

        fixture.undo()
        #expect(store.task(id: original.id) == original)
        fixture.redo()
        #expect(store.task(id: original.id)?.title == "Network v2")
    }

    @Test func setPriorityReportsOnlyActualChanges() throws {
        let ids = store.tasks.prefix(2).map(\.id)
        try fixture.perform(.setPriority(ids: [ids[0]], .high))
        let result = try fixture.perform(.setPriority(ids: ids, .high))
        #expect(result.affectedTaskIDs == ids)
        #expect(result.changedTaskIDs == [ids[1]])

        fixture.undo()
        #expect(store.task(id: ids[0])?.priority == .high)
        #expect(store.task(id: ids[1])?.priority == .normal)
    }

    @Test func setPriorityWithUnknownIDThrowsAndChangesNothing() {
        let unknown = UUID()
        #expect(throws: WorkspaceError.taskNotFound(unknown)) {
            try fixture.perform(.setPriority(ids: [network.id, unknown], .high))
        }
        #expect(network.priority == .normal)
    }

    @Test func setStatusAndUndo() throws {
        try fixture.perform(.setStatus(ids: [network.id], .done))
        #expect(network.status == .done)
        fixture.undo()
        #expect(network.status == .open)
    }

    @Test func deleteTasksAndUndoRestoresOrder() throws {
        let before = store.tasks
        let victims = [before[1].id, before[3].id]
        try fixture.perform(.deleteTasks(ids: victims))
        #expect(store.tasks.count == before.count - 2)
        #expect(try fixture.persisted().count == before.count - 2)

        fixture.undo()
        #expect(store.tasks == before)
        #expect(try fixture.persisted().count == before.count)
    }

    @Test func moveTaskReordersAndUndoRestores() throws {
        let before = store.tasks
        try fixture.perform(.moveTask(id: before[0].id, toIndex: 3))
        #expect(store.tasks.map(\.id) == [before[1], before[2], before[3], before[0], before[4], before[5]].map(\.id))

        try fixture.perform(.moveTask(id: before[5].id, toIndex: 0))
        #expect(store.tasks.first?.id == before[5].id)

        fixture.undo()
        fixture.undo()
        #expect(store.tasks.map(\.id) == before.map(\.id))
    }

    @Test func moveTaskClampsOutOfRangeIndex() throws {
        let first = store.tasks[0]
        try fixture.perform(.moveTask(id: first.id, toIndex: 999))
        #expect(store.tasks.last?.id == first.id)
    }

    @Test func setAppearanceAndClear() throws {
        let custom = TileAppearance(color: .purple, glyph: "star.fill")
        try fixture.perform(.setAppearance(id: network.id, custom))
        #expect(network.resolvedAppearance == custom)
        try fixture.perform(.setAppearance(id: network.id, nil))
        #expect(network.resolvedAppearance == TaskCategory.development.defaultAppearance)
        fixture.undo()
        #expect(network.appearance == custom)
    }

    @Test func duplicateTaskPlacesCopyAfterOriginal() throws {
        let original = network
        let result = try fixture.perform(.duplicateTask(id: original.id, title: "Refactor Network Layer Copy"))
        let copyID = try #require(result.createdTaskID)
        let index = try #require(store.tasks.firstIndex { $0.id == original.id })
        #expect(store.tasks[index + 1].id == copyID)
        #expect(store.tasks[index + 1].steps.count == original.steps.count)
        #expect(store.tasks[index + 1].steps.map(\.id) != original.steps.map(\.id))
        fixture.undo()
        #expect(store.task(id: copyID) == nil)
    }

    @Test func stepCommandsAndUndo() throws {
        let id = network.id
        let added = try fixture.perform(.addStep(taskID: id, title: "Write docs"))
        let stepID = try #require(added.createdStepID)
        #expect(network.steps.last?.title == "Write docs")

        try fixture.perform(.toggleStep(taskID: id, stepID: stepID))
        #expect(network.steps.last?.isDone == true)

        try fixture.perform(.renameStep(taskID: id, stepID: stepID, title: "Write API docs"))
        #expect(network.steps.last?.title == "Write API docs")

        try fixture.perform(.moveSteps(taskID: id, fromOffsets: [3], toOffset: 0))
        #expect(network.steps.first?.id == stepID)

        try fixture.perform(.deleteStep(taskID: id, stepID: stepID))
        #expect(!network.steps.contains { $0.id == stepID })

        fixture.undo()
        #expect(network.steps.first?.id == stepID)
        fixture.undo()
        fixture.undo()
        #expect(network.steps.last?.title == "Write docs")
        fixture.undo()
        #expect(network.steps.last?.isDone == false)
        fixture.undo()
        #expect(!network.steps.contains { $0.id == stepID })
    }

    @Test func stepCommandsRejectUnknownStep() {
        let missing = UUID()
        #expect(throws: WorkspaceError.stepNotFound(missing)) {
            try fixture.perform(.toggleStep(taskID: network.id, stepID: missing))
        }
    }

    @Test func preferencesCommandsPersistAndUndo() throws {
        try fixture.perform(.setLayout(.focus))
        try fixture.perform(.setAccent(.green))
        try fixture.perform(.setListDensity(.compact))
        #expect(fixture.preferences.load() == WorkspacePreferences(layout: .focus, accent: .green, listDensity: .compact))

        fixture.undo()
        fixture.undo()
        fixture.undo()
        #expect(store.preferences == WorkspacePreferences())
    }

    @Test func assistantCommandsAreLoggedAndHighlighted() throws {
        try fixture.perform(.setPriority(ids: [network.id], .high), actor: .assistant)
        #expect(store.lastAssistantChange?.taskIDs == [network.id])
        #expect(store.activity.last?.actor == .assistant)

        try fixture.perform(.setStatus(ids: [network.id], .done), actor: .user)
        #expect(store.lastAssistantChange?.taskIDs == [network.id])
        #expect(store.activity.last?.actor == .user)
    }

    @Test func undoActionNameIsApplied() throws {
        store.undoActionName = { _ in "Prioritise" }
        try fixture.perform(.setPriority(ids: [network.id], .high))
        #expect(fixture.undoManager.undoActionName == "Prioritise")
    }
}
