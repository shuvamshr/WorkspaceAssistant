import SwiftUI

/// Hosts the assistant container with a model, optionally pre-filled with a conversation.
private struct AssistantPreview: View {
    @State private var model: AssistantViewModel

    init(withConversation: Bool = false, reason: AssistantUnavailableReason = .deviceNotEligible) {
        let store = WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore())
        let model = AssistantViewModel(engine: ScriptedEngine(executor: store, reason: reason, wordDelay: .zero))
        if withConversation {
            model.draft = "Switch to Focus"
            model.send()
        }
        _model = State(initialValue: model)
    }

    var body: some View {
        AssistantContainer(showsCloseButton: true, onClose: {}, onSelectTask: { _ in })
            .environment(model)
    }
}

#Preview("Empty · Light") { AssistantPreview() }
#Preview("Empty · Dark") { AssistantPreview().preferredColorScheme(.dark) }
#Preview("Conversation") { AssistantPreview(withConversation: true) }
#Preview("Conversation · AX5") { AssistantPreview(withConversation: true).dynamicTypeSize(.accessibility5) }
#Preview("Conversation · RTL") { AssistantPreview(withConversation: true).environment(\.layoutDirection, .rightToLeft) }
#Preview("Apple Intelligence Off") { AssistantPreview(reason: .appleIntelligenceNotEnabled) }

#Preview("Accessory") {
    AskAssistantAccessory {}
        .environment(AssistantViewModel(engine: ScriptedEngine(
            executor: WorkspaceStore(repository: InMemoryTaskRepository(), preferencesStore: InMemoryPreferencesStore()),
            reason: .deviceNotEligible
        )))
        .padding()
}
