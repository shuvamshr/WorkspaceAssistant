import DesignSystem
import SwiftUI

/// The assistant in a navigation container with a title and a toolbar menu (Clear Conversation).
public struct AssistantContainer: View {
    private let showsCloseButton: Bool
    private let onClose: () -> Void
    private let onSelectTask: (UUID) -> Void
    @Environment(AssistantModel.self) private var model
    @State private var isConfirmingClear = false

    public init(showsCloseButton: Bool, onClose: @escaping () -> Void, onSelectTask: @escaping (UUID) -> Void) {
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.onSelectTask = onSelectTask
    }

    public var body: some View {
        NavigationStack {
            AssistantPanel(onSelectTask: onSelectTask)
                .navigationTitle(Text("Assistant", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button(role: .destructive) {
                                isConfirmingClear = true
                            } label: {
                                Label { Text("Clear Conversation", bundle: .module) } icon: { Image(systemName: "trash") }
                            }
                            .disabled(!model.hasConversation)
                        } label: {
                            Label { Text("Conversation Options", bundle: .module) } icon: { Image(systemName: "ellipsis") }
                        }
                    }
                    if showsCloseButton {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(role: .close, action: onClose)
                        }
                    }
                }
                .confirmationDialog(
                    Text("Clear the conversation?", bundle: .module),
                    isPresented: $isConfirmingClear,
                    titleVisibility: .visible
                ) {
                    Button(role: .destructive, action: model.clear) {
                        Text("Clear Conversation", bundle: .module)
                    }
                } message: {
                    Text("Your tasks and layout won’t change.", bundle: .module)
                }
        }
    }
}
