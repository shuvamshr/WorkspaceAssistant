import SwiftUI
import WorkspaceDomain

/// Hosts the assistant container with a model, optionally pre-filled with a conversation.
private struct AssistantPreview: View {
    @State private var model: AssistantModel

    init(withConversation: Bool = false, simulated: Bool = true) {
        let model = AssistantModel(engine: PreviewAssistantEngine(simulationReason: simulated ? .deviceNotEligible : nil))
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
#Preview("Apple Intelligence") { AssistantPreview(simulated: false) }

#Preview("Accessory") {
    AskAssistantAccessory {}
        .environment(AssistantModel(engine: PreviewAssistantEngine()))
        .padding()
}
