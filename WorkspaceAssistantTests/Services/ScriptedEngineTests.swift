import Foundation
import Testing
@testable import WorkspaceAssistant

@Suite("Scripted intent parsing")
struct ScriptedIntentParserTests {
    @Test func suggestedPrompts() {
        #expect(ScriptedIntentParser.parse("Prioritise the network refactor and switch to Focus") == [.setPriority(query: "network refactor", .high), .switchLayout(.focus)])
        #expect(ScriptedIntentParser.parse("Show my tasks as a Board") == [.switchLayout(.board)])
        #expect(ScriptedIntentParser.parse("Add a priority task for code review") == [.addTask(title: "Code Review", category: .development, priority: .high)])
        #expect(ScriptedIntentParser.parse("Change the accent colour to green") == [.setAccent(.green)])
        #expect(ScriptedIntentParser.parse("Prioritise all testing tasks and use List view") == [.setCategoryPriority(.testing, .high), .switchLayout(.list)])
    }

    @Test func prototypePrompts() {
        #expect(ScriptedIntentParser.parse("Prioritize the network refactor and switch to Focus mode") == [.setPriority(query: "network refactor", .high), .switchLayout(.focus)])
        #expect(ScriptedIntentParser.parse("Switch to Kanban layout") == [.switchLayout(.board)])
        #expect(ScriptedIntentParser.parse("Add a new task for code review, mark it as priority") == [.addTask(title: "Code Review", category: .development, priority: .high)])
        #expect(ScriptedIntentParser.parse("Change the accent color to green") == [.setAccent(.green)])
        #expect(ScriptedIntentParser.parse("Prioritize all testing tasks and switch to Compact view") == [.setCategoryPriority(.testing, .high), .switchLayout(.list)])
    }

    @Test func otherIntents() {
        #expect(ScriptedIntentParser.parse("complete the accessibility audit") == [.complete(query: "accessibility audit")])
        #expect(ScriptedIntentParser.parse("mark the memory leak as done") == [.complete(query: "memory leak")])
        #expect(ScriptedIntentParser.parse("delete the onboarding task") == [.delete(query: "onboarding")])
        #expect(ScriptedIntentParser.parse("deprioritise the network refactor") == [.setPriority(query: "network refactor", .normal)])
        #expect(ScriptedIntentParser.parse("make the onboarding tile purple") == [.setTaskColor(query: "onboarding", .purple)])
        #expect(ScriptedIntentParser.parse("add a step write docs to the network refactor") == [.addStep(query: "network refactor", step: "Write Docs")])
        #expect(ScriptedIntentParser.parse("create a task called update icons") == [.addTask(title: "Update Icons", category: .design, priority: .normal)])
        #expect(ScriptedIntentParser.parse("find audit") == [.find(query: "audit")])
        #expect(ScriptedIntentParser.parse("tell me a joke").isEmpty)
    }
}

@MainActor
@Suite("ScriptedEngine")
struct ScriptedEngineTests {
    @Test(arguments: [
        "Prioritise the network refactor and switch to Focus",
        "Show my tasks as a Board",
        "Add a priority task for code review",
        "Change the accent colour to green",
        "Prioritise all testing tasks and use List view",
    ])
    func everySuggestedPromptChangesTheWorkspace(prompt: String) async throws {
        let store = makeStore()
        let before = (store.tasks, store.preferences)
        let engine = ScriptedEngine(executor: store, reason: .simulatedByConfiguration, wordDelay: .zero)
        let events = try await collect(engine.send(prompt))
        #expect(!events.activities.isEmpty)
        #expect(events.activities.allSatisfy { $0.succeeded })
        #expect(store.tasks != before.0 || store.preferences != before.1)
        #expect(events.finalText?.hasPrefix("Done") == true)
    }

    @Test func firstPromptHasExpectedEffects() async throws {
        let store = makeStore()
        let engine = ScriptedEngine(executor: store, reason: .simulatedByConfiguration, wordDelay: .zero)
        let events = try await collect(engine.send("Prioritise the network refactor and switch to Focus"))
        #expect(store.task(titled: "Refactor Network Layer")?.isHighPriority == true)
        #expect(store.preferences.layout == .focus)
        #expect(events.finalText == "Done — I prioritised “Refactor Network Layer” and switched to Focus.")
    }

    @Test func categoryPrioritisationTouchesEveryTestingTask() async throws {
        let store = makeStore()
        let engine = ScriptedEngine(executor: store, reason: .simulatedByConfiguration, wordDelay: .zero)
        _ = try await collect(engine.send("Prioritise all testing tasks"))
        #expect(store.tasks.filter { $0.category == .testing }.allSatisfy { $0.isHighPriority })
        #expect(store.tasks.filter { $0.category != .testing }.allSatisfy { !$0.isHighPriority })
    }

    @Test func failuresAreReportedHonestly() async throws {
        let store = makeStore()
        let engine = ScriptedEngine(executor: store, reason: .deviceNotEligible, wordDelay: .zero)
        let events = try await collect(engine.send("prioritise pipeline-x"))
        #expect(events.activities.first?.outcome == .failure(.noMatch(query: "pipeline-x")))
        #expect(events.finalText == "I couldn't find a task matching “pipeline-x”.")
        #expect(engine.simulationReason == .deviceNotEligible)
    }

    @Test func unknownRequestsExplainLimits() async throws {
        let engine = ScriptedEngine(executor: makeStore(), reason: .simulatedByConfiguration, wordDelay: .zero)
        let events = try await collect(engine.send("what's the weather"))
        #expect(events.activities.isEmpty)
        #expect(events.finalText?.contains("simulated assistant") == true)
    }

    @Test func streamsTextIncrementally() async throws {
        let engine = ScriptedEngine(executor: makeStore(), reason: .simulatedByConfiguration, wordDelay: .zero)
        let events = try await collect(engine.send("Switch to Kanban layout"))
        let partials = events.compactMap { if case let .partialText(text) = $0 { text } else { nil } }
        #expect(partials.count > 1)
        #expect(partials.last == events.finalText)
    }

    @Test func cancellationStopsTheStream() async throws {
        let engine = ScriptedEngine(executor: makeStore(), reason: .simulatedByConfiguration, wordDelay: .milliseconds(50))
        let task = Task { try await collect(engine.send("Switch to Kanban layout")) }
        try await Task.sleep(for: .milliseconds(80))
        task.cancel()
        // Cancelling the consumer terminates the stream early: no completed reply is delivered.
        let events = try await task.value
        #expect(events.finalText == nil)
        #expect(!engine.isResponding)
    }
}
