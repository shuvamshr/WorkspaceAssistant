import Foundation
import Testing
@testable import WorkspaceAssistant

@MainActor
@Suite("AssistantViewModel")
struct AssistantViewModelTests {
    let engine = FakeEngine()
    let model: AssistantViewModel

    init() {
        model = AssistantViewModel(engine: engine)
    }

    let activity = ToolActivity(kind: .setPriority, parameters: [.task(title: "Refactor Network Layer", id: UUID()), .priority(.high)], outcome: .success)

    @Test func sendTrimsAndAppendsUserMessage() {
        model.draft = "  Switch to Board view \n\n"
        model.send()
        #expect(engine.prompts == ["Switch to Board view"])
        #expect(model.draft.isEmpty)
        #expect(model.phase == .responding)
        #expect(model.items.first?.content == .user("Switch to Board view"))
    }

    @Test func blankDraftIsIgnored() {
        model.draft = " \n "
        model.send()
        #expect(engine.prompts.isEmpty)
        #expect(model.items.isEmpty)
    }

    @Test func secondSendWhileRespondingIsIgnored() {
        model.draft = "one"
        model.send()
        model.draft = "two"
        model.send()
        #expect(engine.prompts == ["one"])
        #expect(model.draft == "two")
    }

    @Test func streamsToolCallsThenText() async {
        model.draft = "prioritise network"
        model.send()
        engine.emit(.toolCalled(activity))
        engine.emit(.partialText("Done"))
        await settle()
        #expect(model.items.count == 3)
        #expect(model.items[1].content == .action(activity))
        #expect(model.items[2].content == .assistant("Done", isStreaming: true))
        #expect(model.lastActivity == activity)

        engine.emit(.partialText("Done — prioritised."))
        engine.emit(.completed("Done — prioritised."))
        engine.finish()
        await settle()
        #expect(model.items.last?.content == .assistant("Done — prioritised.", isStreaming: false))
        #expect(model.phase == .idle)
    }

    @Test func lateToolCallIsInsertedBeforeStreamingReply() async {
        model.draft = "x"
        model.send()
        engine.emit(.partialText("Working"))
        engine.emit(.toolCalled(activity))
        await settle()
        #expect(model.items[1].content == .action(activity))
        #expect(model.items[2].content == .assistant("Working", isStreaming: true))
    }

    @Test func cancelStopsAndMarksTranscript() async {
        model.draft = "x"
        model.send()
        engine.emit(.partialText("Half"))
        await settle()
        model.cancel()
        await settle()
        #expect(model.phase == .idle)
        #expect(model.items.contains { $0.content == .assistant("Half", isStreaming: false) })
        #expect(model.items.last?.content == .notice(.stopped))
        #expect(engine.wasTerminated)
    }

    @Test func errorsBecomeNotices() async {
        model.draft = "x"
        model.send()
        engine.finish(throwing: AssistantError.guardrailViolation)
        await settle()
        #expect(model.phase == .idle)
        #expect(model.items.last?.content == .notice(.error(.guardrailViolation)))
        // A new prompt can be sent after an error.
        model.draft = "again"
        model.send()
        #expect(engine.prompts.count == 2)
    }

    @Test func clearOnlyClearsConversation() async {
        model.draft = "x"
        model.send()
        engine.emit(.completed("ok"))
        engine.finish()
        await settle()
        model.clear()
        await settle()
        #expect(model.items.isEmpty)
        #expect(engine.resetCount == 1)
    }

    @Test func suggestionSendsItsPrompt() {
        let suggestion = AssistantSuggestion.defaults[0]
        model.send(suggestion: suggestion)
        #expect(engine.prompts == [suggestion.prompt])
    }

    @Test func availabilityReflectsEngine() {
        engine.simulationReason = .deviceNotEligible
        model.refreshAvailability()
        #expect(model.simulationReason == .deviceNotEligible)
    }

    @Test func timestampsOnlyAfterFiveMinuteGaps() {
        let start = Date(timeIntervalSince1970: 0)
        let items = [0, 60, 400, 420].map { TranscriptItem(date: start.addingTimeInterval(Double($0)), content: .user("x")) }
        #expect((0..<4).map { TranscriptTimestamps.shows(at: $0, in: items) } == [true, false, true, false])
    }

    @Test func actionPresentation() {
        #expect(activity.spokenSentence == "Assistant prioritised Refactor Network Layer")
        #expect(activity.blockParts == [.verb("Prioritise"), .token("Refactor Network Layer")])
        let failed = ToolActivity(kind: .setPriority, parameters: [.query("pipeline-x"), .priority(.high)], outcome: .failure(.noMatch(query: "pipeline-x")))
        #expect(failed.failureReason == "No task matches “pipeline-x”.")
        #expect(ToolKind.deleteTask.color == .red)
        #expect(ToolKind.switchLayout.glyph == "square.grid.2x2")
    }
}
