import BoardFeature
import DesignSystem
import SwiftUI
import WorkspaceDomain

/// Keyboard shortcuts and menu-bar commands (iPad hardware keyboard).
struct AppCommands: Commands {
    let board: BoardModel
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
