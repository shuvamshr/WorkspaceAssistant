import Foundation
import FoundationModels
import Testing
@testable import WorkspaceAgent
@testable import WorkspaceDomain

@MainActor
@Suite("Foundation Models tool adapters")
struct FoundationModelsToolTests {
    let store = makeStore()
    let recorder = ToolActivityRecorder()
    var toolbox: WorkspaceToolbox { WorkspaceToolbox(executor: store) }

    @Test func setPriorityToolMapsArgumentsAndReportsActivity() async throws {
        var recorded: [ToolActivity] = []
        recorder.onActivity = { recorded.append($0) }
        let tool = SetTaskPriorityTool(toolbox: toolbox, recorder: recorder)
        let output = try await tool.call(arguments: .init(query: "network refactor", priority: .high))
        #expect(output == "Marked 'Refactor Network Layer' as high priority.")
        #expect(recorded.map(\.kind) == [.setPriority])
        #expect(store.task(titled: "Refactor Network Layer")?.isHighPriority == true)
    }

    @Test func addTaskToolUsesTypedEnums() async throws {
        let tool = AddTaskTool(toolbox: toolbox, recorder: recorder)
        let output = try await tool.call(arguments: .init(title: "Code Review", category: .testing, priority: .normal))
        #expect(output == "Added 'Code Review' to testing with normal priority.")
        #expect(store.task(titled: "Code Review")?.category == .testing)
    }

    @Test func switchLayoutAndColourTools() async throws {
        _ = try await SwitchLayoutTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(layout: .board))
        _ = try await SetAccentColorTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(theme: .teal))
        _ = try await SetTaskColorTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(query: "audit", color: .mint))
        #expect(store.preferences.layout == .board)
        #expect(store.preferences.accent == .teal)
        #expect(store.task(titled: "Accessibility Audit")?.resolvedAppearance.color == .mint)
    }

    @Test func remainingToolsReturnTruthfulResults() async throws {
        let find = try await FindTasksTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(query: "zzz"))
        let complete = try await CompleteTaskTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(query: "onboarding"))
        let step = try await AddStepTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(query: "feed", stepTitle: "Profile"))
        let delete = try await DeleteTaskTool(toolbox: toolbox, recorder: recorder).call(arguments: .init(query: "feed"))
        #expect(find.hasPrefix("No task matches 'zzz'"))
        #expect(complete == "Marked 'Redesign Onboarding Flow' as done.")
        #expect(step == "Added step 'Profile' to 'Fix Memory Leak in Feed'.")
        #expect(delete.hasSuffix("The user can undo this from the board."))
    }

    @Test func toolSetHasUniqueNames() {
        let tools = WorkspaceTools.make(toolbox: toolbox, recorder: recorder)
        #expect(Set(tools.map(\.name)) == ["findTasks", "addTask", "setTaskPriority", "completeTask", "deleteTask", "switchLayout", "setAccentColor", "setTaskColor", "addStep"])
    }

    @Test func generableEnumsMirrorDomain() {
        #expect(CategoryArgument.allCases.map(\.domain) == TaskCategory.allCases)
        #expect(LayoutArgument.allCases.map(\.domain) == BoardLayout.allCases)
        #expect(AccentArgument.allCases.map(\.domain) == AccentTheme.allCases)
        #expect(TileColorArgument.allCases.map(\.domain) == TileColor.allCases)
        #expect(PriorityArgument.allCases.map(\.domain) == TaskPriority.allCases)
    }

    @Test func generationErrorsMapToSpecificCases() {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "test")
        #expect(AssistantErrorMapping.map(LanguageModelSession.GenerationError.exceededContextWindowSize(context)) == .contextWindowExceeded)
        #expect(AssistantErrorMapping.map(LanguageModelSession.GenerationError.guardrailViolation(context)) == .guardrailViolation)
        #expect(AssistantErrorMapping.map(LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(context)) == .unsupportedLanguage)
        #expect(AssistantErrorMapping.map(LanguageModelSession.GenerationError.rateLimited(context)) == .rateLimited)
        #expect(AssistantErrorMapping.map(LanguageModelSession.GenerationError.concurrentRequests(context)) == .busy)
        #expect(AssistantErrorMapping.map(LanguageModelSession.GenerationError.assetsUnavailable(context)) == .assetsUnavailable)
        #expect(AssistantErrorMapping.map(AssistantError.timeout) == .timeout)
    }

    @Test func availabilityMapping() {
        #expect(AssistantErrorMapping.map(SystemLanguageModel.Availability.available) == .available)
        #expect(AssistantErrorMapping.map(.unavailable(.deviceNotEligible)) == .unavailable(.deviceNotEligible))
        #expect(AssistantErrorMapping.map(.unavailable(.appleIntelligenceNotEnabled)) == .unavailable(.appleIntelligenceNotEnabled))
        #expect(AssistantErrorMapping.map(.unavailable(.modelNotReady)) == .unavailable(.modelNotReady))
    }
}
