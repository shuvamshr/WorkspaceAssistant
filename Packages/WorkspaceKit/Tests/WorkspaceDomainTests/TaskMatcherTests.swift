import Foundation
import Testing
@testable import WorkspaceDomain

@Suite("Task matching")
struct TaskMatcherTests {
    let tasks = SampleData.tasks()

    func titles(_ match: TaskMatch) -> [String] {
        switch match {
        case .none: []
        case let .unique(task): [task.title]
        case let .ambiguous(tasks): tasks.map(\.title)
        }
    }

    @Test func noMatch() {
        #expect(TaskMatcher.match("pipeline-x", in: tasks) == .none)
        #expect(TaskMatcher.match("   ", in: tasks) == .none)
        #expect(TaskMatcher.match("the task", in: tasks) == .none)
    }

    @Test func exactTitleIsUnique() {
        #expect(titles(TaskMatcher.match("Accessibility Audit", in: tasks)) == ["Accessibility Audit"])
    }

    @Test func wordsInAnyOrderMatch() {
        #expect(titles(TaskMatcher.match("the network refactor", in: tasks)) == ["Refactor Network Layer"])
    }

    @Test func inflectedWordsMatch() {
        #expect(titles(TaskMatcher.match("testing suite", in: tasks)) == ["Write Unit Test Suite"])
        #expect(titles(TaskMatcher.match("refactoring", in: tasks)) == ["Refactor Network Layer"])
    }

    @Test func caseAndDiacriticInsensitive() {
        #expect(titles(TaskMatcher.match("ACCESSIBILITY AUDIT", in: tasks)) == ["Accessibility Audit"])
        #expect(titles(TaskMatcher.match("Rédesign Onboárding", in: tasks)) == ["Redesign Onboarding Flow"])
        #expect(titles(TaskMatcher.match("ci/cd", in: tasks)) == ["Set Up CI/CD Pipeline"])
    }

    @Test func ambiguousReturnsAllCandidates() {
        let extra = tasks + [TaskItem(title: "Refactor Settings Screen", category: .development)]
        #expect(Set(titles(TaskMatcher.match("refactor", in: extra))) == ["Refactor Network Layer", "Refactor Settings Screen"])
    }

    @Test func exactTitleBeatsPartialMatches() {
        let extra = tasks + [TaskItem(title: "Accessibility Audit Follow-up", category: .testing)]
        #expect(titles(TaskMatcher.match("accessibility audit", in: extra)) == ["Accessibility Audit"])
    }

    @Test func idMatches() {
        let target = tasks[2]
        #expect(TaskMatcher.match(target.id.uuidString, in: tasks) == .unique(target))
    }

    @Test func openTasksArePreferredOverDone() {
        var list = tasks
        list.append(TaskItem(title: "Refactor Network Layer", category: .development, status: .done))
        #expect(TaskMatcher.match("network", in: list) == .unique(tasks[0]))
    }

    @Test func doneTasksMatchWhenNothingOpenDoes() {
        let done = TaskItem(title: "Ship v1", category: .operations, status: .done)
        #expect(TaskMatcher.match("ship", in: tasks + [done]) == .unique(done))
    }
}
