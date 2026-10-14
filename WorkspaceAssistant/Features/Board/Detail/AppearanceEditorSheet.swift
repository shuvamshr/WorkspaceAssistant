import SwiftUI

/// A sheet wrapping `AppearancePicker` with Cancel / Done and "Use Category Default".
struct AppearanceEditorSheet: View {
    let task: TaskItem
    let onSave: (TileAppearance?) -> Void
    @State private var appearance: TileAppearance
    @Environment(\.dismiss) private var dismiss

    init(task: TaskItem, onSave: @escaping (TileAppearance?) -> Void) {
        self.task = task
        self.onSave = onSave
        _appearance = State(initialValue: task.resolvedAppearance)
    }

    var body: some View {
        NavigationStack {
            AppearancePicker(appearance: $appearance)
                .navigationTitle(Text("Appearance"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            onSave(appearance == task.category.defaultAppearance ? nil : appearance)
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            appearance = task.category.defaultAppearance
                        } label: {
                            Text("Use Category Default")
                        }
                        .disabled(appearance == task.category.defaultAppearance)
                    }
                }
        }
    }
}
