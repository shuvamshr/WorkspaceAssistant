import Foundation
import Testing
@testable import WorkspaceAssistant

@MainActor
@Suite("WorkspaceToolbox")
struct WorkspaceToolboxTests {
    let store = makeStore()
    var toolbox: WorkspaceToolbox { WorkspaceToolbox(executor: store) }

    @Test func prioritiseUniqueMatch() {
        let result = toolbox.setTaskPriority(query: "network refactor", priority: .high)
        #expect(result.message == "Marked 'Refactor Network Layer' as high priority.")
        #expect(result.activity.outcome == .success)
        #expect(store.task(titled: "Refactor Network Layer")?.priority == .high)
        #expect(store.activity.last?.actor == .assistant)
        #expect(store.lastAssistantChange?.taskIDs == result.activity.taskIDs)
    }

    @Test func prioritiseAlreadyHighReportsNoChange() {
        _ = toolbox.setTaskPriority(query: "network", priority: .high)
        let result = toolbox.setTaskPriority(query: "network", priority: .high)
        #expect(result.message == "'Refactor Network Layer' is already high priority. No change made.")
        #expect(result.activity.outcome == .unchanged)
    }

    @Test func noMatchIsTruthful() {
        let result = toolbox.setTaskPriority(query: "pipeline-x", priority: .high)
        #expect(result.message.hasPrefix("No task matches 'pipeline-x'. Nothing was changed. Open tasks: 'Refactor Network Layer'"))
        #expect(result.activity.outcome == .failure(.noMatch(query: "pipeline-x")))
        #expect(store.tasks.allSatisfy { $0.priority == .normal })
    }

    @Test func ambiguousListsCandidates() {
        let store = makeStore(extra: [TaskItem(title: "Refactor Settings Screen", category: .development, sortIndex: 10)])
        let result = WorkspaceToolbox(executor: store).completeTask(query: "refactor")
        #expect(result.message == "Ambiguous: 'refactor' matches 'Refactor Network Layer', 'Refactor Settings Screen'. Nothing was changed. Ask the user which one they mean.")
        #expect(result.activity.outcome == .failure(.ambiguous(query: "refactor", candidates: ["Refactor Network Layer", "Refactor Settings Screen"])))
        #expect(!store.tasks.contains { $0.isDone })
    }

    @Test func addTask() throws {
        let result = toolbox.addTask(title: " Code Review ", category: .development, priority: .high)
        #expect(result.message == "Added 'Code Review' to development with high priority.")
        let task = try #require(store.task(titled: "Code Review"))
        #expect(task.origin == .assistant)
        #expect(task.priority == .high)
        #expect(result.activity.taskIDs == [task.id])
    }

    @Test func addTaskWithEmptyTitleFails() {
        let result = toolbox.addTask(title: "  ", category: .design, priority: .normal)
        #expect(result.activity.outcome == .failure(.emptyTitle))
        #expect(store.tasks.count == 6)
    }

    @Test func completeAndDelete() {
        #expect(toolbox.completeTask(query: "accessibility audit").message == "Marked 'Accessibility Audit' as done.")
        #expect(toolbox.completeTask(query: "accessibility audit").activity.outcome == .unchanged)
        let deleted = toolbox.deleteTask(query: "memory leak")
        #expect(deleted.message == "Deleted 'Fix Memory Leak in Feed'. The user can undo this from the board.")
        #expect(store.task(titled: "Fix Memory Leak in Feed") == nil)
    }

    @Test func layoutAndAccent() {
        #expect(toolbox.switchLayout(.focus).message == "Switched the board to focus layout.")
        #expect(toolbox.switchLayout(.focus).activity.outcome == .unchanged)
        #expect(store.preferences.layout == .focus)
        #expect(toolbox.setAccentColor(.green).message == "Changed the accent colour to green.")
        #expect(store.preferences.accent == .green)
    }

    @Test func taskColorKeepsGlyph() {
        let result = toolbox.setTaskColor(query: "onboarding", color: .purple)
        #expect(result.message == "Changed 'Redesign Onboarding Flow' to purple.")
        #expect(store.task(titled: "Redesign Onboarding Flow")?.resolvedAppearance == TileAppearance(color: .purple, glyph: "paintbrush.pointed.fill"))
    }

    @Test func addStep() {
        let result = toolbox.addStep(query: "ci/cd", stepTitle: "Add lint step")
        #expect(result.message == "Added step 'Add lint step' to 'Set Up CI/CD Pipeline'.")
        #expect(store.task(titled: "Set Up CI/CD Pipeline")?.steps.last?.title == "Add lint step")
        #expect(toolbox.addStep(query: "ci/cd", stepTitle: " ").activity.outcome == .failure(.emptyTitle))
    }

    @Test func findTasksReturnsIDsAndState() throws {
        let result = toolbox.findTasks(query: "audit")
        let audit = try #require(store.task(titled: "Accessibility Audit"))
        #expect(result.message.contains("'Accessibility Audit' (id: \(audit.id.uuidString), category: testing, priority: normal, status: open, steps: 0/2)"))
        #expect(toolbox.findTasks(query: "").activity.taskIDs.count == 6)
        #expect(toolbox.findTasks(query: "zebra").activity.outcome == .failure(.noMatch(query: "zebra")))
    }

    @Test func idQueriesWork() throws {
        let audit = try #require(store.task(titled: "Accessibility Audit"))
        #expect(toolbox.completeTask(query: audit.id.uuidString).activity.outcome == .success)
    }
}
