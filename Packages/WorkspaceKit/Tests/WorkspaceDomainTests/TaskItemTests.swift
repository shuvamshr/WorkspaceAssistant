import Testing
@testable import WorkspaceDomain

@Suite("TaskItem")
struct TaskItemTests {
    @Test func appearanceFallsBackToCategory() {
        for category in TaskCategory.allCases {
            #expect(TaskItem(title: "x", category: category).resolvedAppearance == category.defaultAppearance)
        }
    }

    @Test func stepProgress() {
        var task = TaskItem(title: "x", category: .design)
        #expect(task.stepProgress == nil)
        task.steps = [TaskStep(title: "a", isDone: true), TaskStep(title: "b")]
        #expect(task.stepProgress == 0.5)
        #expect(task.completedStepCount == 1)
    }

    @Test func categoryDefaults() {
        #expect(TaskCategory.development.defaultAppearance == TileAppearance(color: .blue, glyph: "hammer.fill"))
        #expect(TaskCategory.testing.defaultAppearance == TileAppearance(color: .green, glyph: "checkmark.seal.fill"))
        #expect(TaskCategory.design.defaultAppearance == TileAppearance(color: .pink, glyph: "paintbrush.pointed.fill"))
        #expect(TaskCategory.operations.defaultAppearance == TileAppearance(color: .orange, glyph: "gearshape.2.fill"))
    }
}
