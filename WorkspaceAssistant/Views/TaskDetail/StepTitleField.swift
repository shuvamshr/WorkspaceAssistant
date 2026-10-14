import SwiftUI

/// An inline-editable step title that commits on submit or when focus leaves.
struct StepTitleField: View {
    let step: TaskStep
    let onCommit: (String) -> Void
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(text: $text, axis: .vertical) { Text("Step") }
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit(commit)
            .onAppear { text = step.title }
            .onChange(of: step.title) { _, newValue in if !isFocused { text = newValue } }
            .onChange(of: isFocused) { _, focused in if !focused { commit() } }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            text = step.title
        } else if trimmed != step.title {
            onCommit(trimmed)
        }
    }
}
