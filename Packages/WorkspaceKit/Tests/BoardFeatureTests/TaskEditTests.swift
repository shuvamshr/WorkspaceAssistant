import Foundation
import Testing
@testable import BoardFeature
@testable import WorkspaceDomain

@Suite("TaskEdit")
struct TaskEditTests {
    var draft = TaskItem(title: "Draft", category: .design, steps: [TaskStep(title: "a"), TaskStep(title: "b"), TaskStep(title: "c")])

    @Test mutating func appliesToDraft() {
        TaskEdit.title("Final").apply(to: &draft)
        TaskEdit.priority(.high).apply(to: &draft)
        TaskEdit.addStep("  d ").apply(to: &draft)
        TaskEdit.addStep("   ").apply(to: &draft)
        TaskEdit.moveSteps([0], 4).apply(to: &draft)
        TaskEdit.deleteSteps([0]).apply(to: &draft)
        #expect(draft.title == "Final")
        #expect(draft.priority == .high)
        #expect(draft.steps.map(\.title) == ["c", "d", "a"])
    }

    @Test func mapsToCommands() {
        let ids = draft.steps.map(\.id)
        #expect(TaskEdit.title("x").commands(for: draft) == [.updateTask(id: draft.id, changes: TaskChanges(title: "x"))])
        #expect(TaskEdit.status(.done).commands(for: draft) == [.setStatus(ids: [draft.id], .done)])
        #expect(TaskEdit.deleteSteps([0, 2]).commands(for: draft) == [
            .deleteStep(taskID: draft.id, stepID: ids[0]), .deleteStep(taskID: draft.id, stepID: ids[2]),
        ])
    }

    @Test func searchMatchesTitlesNotesAndSteps() {
        var tasks = SampleData.tasks()
        tasks[2].notes = "Talk to marketing about illustrations"
        #expect(TaskSearch.results(for: "marketing", in: tasks).map(\.title) == ["Redesign Onboarding Flow"])
        #expect(TaskSearch.results(for: "testflight", in: tasks).map(\.title) == ["Set Up CI/CD Pipeline"])
        #expect(TaskSearch.results(for: "", in: tasks).count == tasks.count)
        #expect(TaskSearch.results(for: "zzz", in: tasks).isEmpty)
    }

    @Test func plainTextExport() {
        let text = draft.plainTextExport
        #expect(text.hasPrefix("Draft\n"))
        #expect(text.contains("☐ a"))
    }
}
