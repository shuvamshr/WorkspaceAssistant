import SwiftUI

/// The new-task sheet: the same block editor over a draft, committed with one undoable command.
public struct NewTaskSheet: View {
    @State private var draft: TaskItem
    @State private var isEditingAppearance = false
    @Environment(BoardModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    public init(request: NewTaskRequest) {
        _draft = State(initialValue: TaskItem(title: "", category: request.category))
    }

    private var canAdd: Bool { !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    public var body: some View {
        NavigationStack {
            TaskEditorForm(task: draft, commitsLive: true, apply: { $0.apply(to: &draft) }) {
                isEditingAppearance = true
            }
            .navigationTitle(Text("New Task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: add) {
                        Text("Add")
                    }
                    .disabled(!canAdd)
                }
            }
            .sheet(isPresented: $isEditingAppearance) {
                AppearanceEditorSheet(task: draft) { draft.appearance = $0 }
            }
        }
    }

    private func add() {
        var task = draft
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.createdAt = .now
        task.sortIndex = (model.store.tasks.map(\.sortIndex).min() ?? 0) - 1
        model.perform(.insertTasks([task]))
        model.reveal(task.id)
        dismiss()
    }
}
