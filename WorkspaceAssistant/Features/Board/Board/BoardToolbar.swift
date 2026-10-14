import SwiftUI

/// Board toolbar: layout and sort menu, new task, select, and the selection action bar.
struct BoardToolbar: ToolbarContent {
    let collection: BoardCollection
    @Environment(BoardModel.self) private var model

    var body: some ToolbarContent {
        if model.isSelecting {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.isSelecting = false
                } label: {
                    Text("Done")
                }
                .buttonStyle(.glassProminent)
            }
            ToolbarItem(placement: .topBarLeading) {
                Text("\(model.selection.count) Selected")
                    .font(.headline)
                    .fixedSize()
            }
            ToolbarItemGroup(placement: .bottomBar) { selectionActions }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    model.isShowingSettings = true
                } label: {
                    Label { Text("Settings") } icon: { Image(systemName: "gearshape") }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                viewMenu
                Button {
                    model.isSelecting = true
                } label: {
                    Label { Text("Select") } icon: { Image(systemName: "checkmark.circle") }
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.createTask(in: collection)
                } label: {
                    Label { Text("New Task") } icon: { Image(systemName: "plus") }
                }
            }
        }
    }

    private var viewMenu: some View {
        @Bindable var model = model
        return Menu {
            Picker(selection: Binding(get: { model.store.preferences.layout }, set: { model.setLayout($0) })) {
                ForEach(BoardLayout.allCases) { layout in
                    Label(layout.displayName, systemImage: layout.symbolName).tag(layout)
                }
            } label: {
                Text("Layout")
            }
            .pickerStyle(.inline)

            Picker(selection: $model.sort) {
                ForEach(BoardSort.allCases) { sort in Text(sort.displayName).tag(sort) }
            } label: {
                Label { Text("Sort By") } icon: { Image(systemName: "arrow.up.arrow.down") }
            }
            .pickerStyle(.menu)
        } label: {
            Label { Text("View Options") } icon: { Image(systemName: model.store.preferences.layout.symbolName) }
        }
    }

    @ViewBuilder private var selectionActions: some View {
        let empty = model.selection.isEmpty
        Button {
            model.prioritiseSelection()
        } label: {
            Label { Text("Prioritise") } icon: { Image(systemName: "star") }
        }
        .disabled(empty)
        Spacer()
        Button {
            model.completeSelection()
        } label: {
            Label { Text("Complete") } icon: { Image(systemName: "checkmark.circle") }
        }
        .disabled(empty)
        Spacer()
        Menu {
            ForEach(TaskCategory.allCases) { category in
                Button {
                    model.moveSelection(to: category)
                } label: {
                    Label(category.displayName, systemImage: category.symbolName)
                }
            }
        } label: {
            Label { Text("Move") } icon: { Image(systemName: "folder") }
        }
        .disabled(empty)
        Spacer()
        Button(role: .destructive) {
            model.requestDelete(model.orderedSelection)
        } label: {
            Label { Text("Delete") } icon: { Image(systemName: "trash") }
        }
        .disabled(empty)
        .keyboardShortcut(.delete, modifiers: [])
    }
}
