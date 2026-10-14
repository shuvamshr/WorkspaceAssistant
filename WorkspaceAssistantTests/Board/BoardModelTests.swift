import Foundation
import Testing
@testable import WorkspaceAssistant

@MainActor
@Suite("BoardModel")
struct BoardModelTests {
    let store: WorkspaceStore
    let model: BoardModel
    let undo = UndoManager()

    init() {
        store = WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore())
        model = BoardModel(store: store)
        store.undoManager = undo
    }

    func task(_ title: String) -> TaskItem { store.tasks.first { $0.title == title }! }
    var titles: [String] { store.tasks.map(\.title) }

    @Test func collectionsFilterTasks() throws {
        let network = task("Refactor Network Layer")
        try store.perform(.setPriority(ids: [network.id], .high))
        try store.perform(.setStatus(ids: [task("Accessibility Audit").id], .done))

        #expect(model.tasks(in: .priority).map(\.title) == ["Refactor Network Layer"])
        #expect(model.tasks(in: .done).map(\.title) == ["Accessibility Audit"])
        #expect(model.tasks(in: .category(.testing)).map(\.title) == ["Write Unit Test Suite"])
        #expect(!model.tasks(in: .all).contains { $0.isDone })
    }

    @Test func boardLayoutIncludesDoneTasks() throws {
        try store.perform(.setStatus(ids: [task("Accessibility Audit").id], .done))
        try store.perform(.setLayout(.board))
        #expect(model.tasks(in: .all).contains { $0.title == "Accessibility Audit" })
        #expect(model.tasks(in: .category(.testing)).count == 2)
    }

    @Test func sortOrders() {
        model.sort = .title
        #expect(model.tasks(in: .all).map(\.title) == titles.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        model.sort = .newest
        #expect(model.tasks(in: .all).first?.title == "Refactor Network Layer")
        #expect(!model.canReorder)
    }

    @Test func togglesAreUndoable() {
        let id = task("Redesign Onboarding Flow").id
        undo.groupsByEvent = false
        undo.beginUndoGrouping()
        model.togglePriority(id)
        undo.endUndoGrouping()
        #expect(store.task(id: id)?.isHighPriority == true)
        undo.undo()
        #expect(store.task(id: id)?.isHighPriority == false)
    }

    @Test func listMoveDownTranslatesToGlobalOrder() {
        // Visible list is the Testing collection; moving within it reorders the full list.
        let visible = model.tasks(in: .category(.testing))  // [Write Unit Test Suite, Accessibility Audit]
        model.reorder(visible: visible, fromOffsets: [0], toOffset: 2)
        #expect(titles.firstIndex(of: "Write Unit Test Suite")! > titles.firstIndex(of: "Accessibility Audit")!)
    }

    @Test func listMoveUpTranslatesToGlobalOrder() {
        let visible = model.tasks(in: .all)
        model.reorder(visible: visible, fromOffsets: [5], toOffset: 0)
        #expect(titles.first == "Accessibility Audit")
    }

    @Test func gridDropTakesTargetPosition() {
        let visible = model.tasks(in: .all)
        model.drop(visible[0].id, onto: visible[2].id, visible: visible)
        #expect(titles[2] == visible[0].title)
        let updated = model.tasks(in: .all)
        model.drop(updated[4].id, onto: updated[1].id, visible: updated)
        #expect(titles[1] == updated[4].title)
    }

    @Test func kanbanDropChangesPriorityAndStatus() {
        let id = task("Fix Memory Leak in Feed").id
        model.drop(id, into: .priority)
        #expect(store.task(id: id)?.priority == .high)
        model.drop(id, into: .done)
        #expect(store.task(id: id)?.status == .done)
        model.drop(id, into: .backlog)
        #expect(store.task(id: id)?.priority == .normal)
        #expect(store.task(id: id)?.status == .open)
    }

    @Test func bulkPrioritiseTogglesWhenAllAlreadyHigh() {
        model.isSelecting = true
        model.selection = [task("Refactor Network Layer").id, task("Accessibility Audit").id]
        model.prioritiseSelection()
        #expect(store.tasks.count(where: \.isHighPriority) == 2)
        #expect(!model.isSelecting)
        #expect(model.selection.isEmpty)

        model.isSelecting = true
        model.selection = [task("Refactor Network Layer").id, task("Accessibility Audit").id]
        model.prioritiseSelection()
        #expect(store.tasks.count(where: \.isHighPriority) == 0)
    }

    @Test func bulkCompleteAndMove() {
        let ids: Set = [task("Write Unit Test Suite").id, task("Set Up CI/CD Pipeline").id]
        model.selection = ids
        model.completeSelection()
        #expect(ids.allSatisfy { store.task(id: $0)?.isDone == true })

        model.selection = ids
        model.moveSelection(to: .design)
        #expect(ids.allSatisfy { store.task(id: $0)?.category == .design })
    }

    @Test func deletionNeedsConfirmation() {
        let id = task("Write Unit Test Suite").id
        model.requestDelete([id])
        #expect(store.task(id: id) != nil)
        model.confirmPendingDeletion()
        #expect(store.task(id: id) == nil)
        #expect(model.pendingDeletion == nil)
    }

    @Test func duplicateUsesCopyTitle() {
        model.duplicate(task("Accessibility Audit").id)
        #expect(titles.contains("Accessibility Audit Copy"))
    }

    @Test func createTaskUsesCollectionCategory() {
        model.createTask(in: .category(.operations))
        #expect(model.newTask?.category == .operations)
        model.createTask(in: .priority)
        #expect(model.newTask?.category == .development)
    }

    @Test func highlightTriggerOnlyForAssistantChanges() throws {
        let id = task("Accessibility Audit").id
        try store.perform(.setPriority(ids: [id], .high), actor: .user)
        #expect(model.highlightTrigger(for: id) == nil)
        try store.perform(.setStatus(ids: [id], .done), actor: .assistant)
        #expect(model.highlightTrigger(for: id) == store.lastAssistantChange?.id)
    }
}

@MainActor
@Suite("BoardModel sort persistence")
struct BoardSortPersistenceTests {
    @Test func sortIsRestoredFromStorage() throws {
        let suite = "BoardSortPersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore())

        BoardModel(store: store, sortStorage: defaults).sort = .title
        #expect(BoardModel(store: store, sortStorage: defaults).sort == .title)
        #expect(BoardModel(store: store).sort == .manual)
    }
}
