import SwiftUI

extension BoardViewModel {
    /// A board over in-memory sample data, for previews. No Apple Intelligence or SwiftData needed.
    static func preview(layout: BoardLayout = .grid) -> BoardViewModel {
        let store = WorkspaceStore(
            repository: InMemoryTaskRepository(),
            preferencesStore: InMemoryPreferencesStore(preferences: WorkspacePreferences(layout: layout))
        )
        if let first = store.tasks.first {
            _ = try? store.perform(.setPriority(ids: [first.id], .high), actor: .user)
        }
        return BoardViewModel(store: store)
    }
}

/// Board screen previews in each layout and accessibility variant.
private struct BoardPreview: View {
    var layout: BoardLayout = .grid
    @State private var model: BoardViewModel

    init(layout: BoardLayout = .grid) {
        self.layout = layout
        _model = State(initialValue: .preview(layout: layout))
    }

    var body: some View {
        BoardScreen(collection: .all)
            .environment(model)
            .boardPresentations()
    }
}

#Preview("Grid · Light") { BoardPreview() }
#Preview("Grid · Dark") { BoardPreview().preferredColorScheme(.dark) }
#Preview("Grid · AX5") { BoardPreview().dynamicTypeSize(.accessibility5) }
#Preview("Grid · RTL") { BoardPreview().environment(\.layoutDirection, .rightToLeft) }
#Preview("List") { BoardPreview(layout: .list) }
#Preview("Focus") { BoardPreview(layout: .focus) }
#Preview("Board") { BoardPreview(layout: .board) }

#Preview("Task Detail") {
    let model = BoardViewModel.preview()
    return NavigationStack {
        TaskDetailView(taskID: model.store.tasks[0].id) {}
    }
    .environment(model)
}

#Preview("New Task") {
    NewTaskSheet(request: NewTaskRequest(category: .design)).environment(BoardViewModel.preview())
}

#Preview("Collections") {
    CollectionsScreen().environment(BoardViewModel.preview())
}

#Preview("Search") {
    @Previewable @State var query = "test"
    SearchScreen(query: $query).environment(BoardViewModel.preview())
}
