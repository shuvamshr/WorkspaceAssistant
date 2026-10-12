import BoardFeature
import DesignSystem
import SettingsFeature
import SwiftUI
import WorkspaceDomain

/// The app's root: a tab bar on iPhone that becomes a sidebar on iPad.
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(BoardModel.self) private var board
    @Environment(\.undoManager) private var undoManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("sidebarCustomization") private var customization = TabViewCustomization()

    var body: some View {
        @Bindable var router = router
        @Bindable var board = board
        TabView(selection: $router.tab) {
            Tab(value: AppTab.tasks) {
                BoardScreen(collection: .all)
            } label: {
                Label { Text("Tasks") } icon: { Image(systemName: "square.grid.2x2") }
            }
            .customizationID("tasks")

            if sizeClass == .compact {
                Tab(value: AppTab.collections) {
                    CollectionsScreen()
                } label: {
                    Label { Text("Collections") } icon: { Image(systemName: "folder") }
                }
                .customizationID("collections")
            } else {
                TabSection {
                    ForEach(BoardCollection.allCases.filter { $0 != .all }) { collection in
                        Tab(value: AppTab.collection(collection)) {
                            BoardScreen(collection: collection)
                        } label: {
                            Label(collection.title, systemImage: collection.symbolName)
                        }
                        .customizationID(collection.id)
                    }
                } header: {
                    Text("Collections")
                }
                .customizationID("collectionsSection")
            }

            Tab(value: AppTab.search, role: .search) {
                SearchScreen(query: $router.searchQuery)
            } label: {
                Label { Text("Search") } icon: { Image(systemName: "magnifyingglass") }
            }
            .customizationID("search")
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
        .boardPresentations()
        .sheet(isPresented: $board.isShowingSettings) {
            SettingsView(store: board.store, assistant: nil)
        }
        .tint(board.store.preferences.accent.color)
        .onAppear { board.store.undoManager = undoManager }
        .onChange(of: undoManager) { _, manager in board.store.undoManager = manager }
        .onChange(of: sizeClass) { _, newValue in
            if newValue == .compact, case .collection = router.tab { router.tab = .collections }
            if newValue == .regular, router.tab == .collections { router.tab = .tasks }
        }
    }
}
