import DesignSystem
import SwiftUI
import WorkspaceDomain

/// Presents the board's sheets and confirmations (new task, appearance, delete). Apply once at the root.
struct BoardPresentations: ViewModifier {
    @Environment(BoardModel.self) private var model

    func body(content: Content) -> some View {
        @Bindable var model = model
        content
            .sheet(item: $model.newTask) { request in
                NewTaskSheet(request: request)
            }
            .sheet(item: Binding(
                get: { model.appearanceTaskID.flatMap(model.store.task(id:)) },
                set: { model.appearanceTaskID = $0?.id }
            )) { task in
                AppearanceEditorSheet(task: task) { appearance in
                    model.perform(.setAppearance(id: task.id, appearance))
                }
            }
            .confirmationDialog(
                deletionTitle,
                isPresented: Binding(get: { model.pendingDeletion != nil }, set: { if !$0 { model.pendingDeletion = nil } }),
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    model.confirmPendingDeletion()
                } label: {
                    Text("Delete", bundle: .module)
                }
            } message: {
                Text("You can undo this with Undo or by shaking your device.", bundle: .module)
            }
    }

    private var deletionTitle: String {
        let count = model.pendingDeletion?.taskIDs.count ?? 0
        return String(localized: "Delete \(count) Tasks?", bundle: .module)
    }
}

extension View {
    /// Attaches the board's sheets and confirmation dialogs.
    public func boardPresentations() -> some View {
        modifier(BoardPresentations())
    }
}
