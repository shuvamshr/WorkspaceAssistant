import SwiftUI

/// Searches task titles, notes and steps.
public struct SearchScreen: View {
    @Binding private var query: String
    @State private var path = NavigationPath()
    @Environment(BoardViewModel.self) private var model

    public init(query: Binding<String>) {
        _query = query
    }

    public var body: some View {
        NavigationStack(path: $path) {
            let results = TaskSearch.results(for: query, in: model.store.tasks)
            List {
                ForEach(results) { task in
                    NavigationLink(value: TaskRoute(taskID: task.id)) {
                        TaskRow(task: task)
                    }
                    .contextMenu { TaskMenuItems(task: task) }
                }
            }
            .overlay {
                if results.isEmpty && !query.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle(Text("Search"))
            .searchable(text: $query, prompt: Text("Titles, notes and steps"))
            .navigationDestination(for: TaskRoute.self) { route in
                TaskDetailView(taskID: route.taskID) { path.removeLast(path.count) }
            }
        }
    }
}
