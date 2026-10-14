import SwiftUI

/// Keyboard shortcuts and menu-bar commands (iPad hardware keyboard).
struct AppCommands: Commands {
    let board: BoardViewModel
    let assistant: AssistantViewModel
    let router: AppRouter

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Task") { board.createTask() }
                .keyboardShortcut("n")
        }
        CommandGroup(after: .textEditing) {
            Button("Search") { router.tab = .search }
                .keyboardShortcut("f")
        }
        CommandMenu("Assistant") {
            Button("Ask Assistant") {
                router.isShowingAssistant = true
                assistant.requestFocus()
            }
            .keyboardShortcut("k")
        }
        CommandMenu("Layout") {
            ForEach(Array(BoardLayout.allCases.enumerated()), id: \.element) { index, layout in
                Button {
                    board.setLayout(layout)
                } label: {
                    Label(layout.displayName, systemImage: layout.symbolName)
                }
                .keyboardShortcut(KeyEquivalent(Character(String(index + 1))))
            }
        }
    }
}
