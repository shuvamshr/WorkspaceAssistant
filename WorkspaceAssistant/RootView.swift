import AssistantFeature
import BoardFeature
import DesignSystem
import SettingsFeature
import SwiftUI
import WorkspaceDomain

/// The app's root: a tab bar on iPhone that becomes a sidebar on iPad, with the assistant
/// always reachable from the bottom accessory (sheet on iPhone, inspector on iPad).
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(BoardModel.self) private var board
    @Environment(AssistantModel.self) private var assistant
    @Environment(\.undoManager) private var undoManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("sidebarCustomization") private var customization = TabViewCustomization()
    @State private var sheetDetent: PresentationDetent = .medium

    private var usesInspector: Bool { sizeClass == .regular }

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
        .tabViewBottomAccessory {
            AskAssistantAccessory {
                router.isShowingAssistant.toggle()
                if router.isShowingAssistant { assistant.requestFocus() }
            }
        }
        .inspector(isPresented: assistantBinding(inspector: true)) {
            AssistantContainer(showsCloseButton: true, onClose: { router.isShowingAssistant = false }, onSelectTask: reveal)
                .inspectorColumnWidth(min: 320, ideal: 380, max: 480)
        }
        .sheet(isPresented: assistantBinding(inspector: false)) {
            AssistantContainer(showsCloseButton: true, onClose: { router.isShowingAssistant = false }, onSelectTask: reveal)
                .presentationDetents([.medium, .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationContentInteraction(.scrolls)
        }
        .boardPresentations()
        .sheet(isPresented: $board.isShowingSettings) {
            SettingsView(store: board.store, assistant: assistantInfo)
        }
        .tint(board.store.preferences.accent.color)
        .onAppear { board.store.undoManager = undoManager }
        .onChange(of: undoManager) { _, manager in board.store.undoManager = manager }
        .onChange(of: sizeClass) { _, newValue in
            if newValue == .compact, case .collection = router.tab { router.tab = .collections }
            if newValue == .regular, router.tab == .collections { router.tab = .tasks }
        }
    }

    /// Presentation binding for the assistant container. Only dismissals are written back, so the
    /// system restoring inspector visibility can't open the assistant on launch.
    private func assistantBinding(inspector: Bool) -> Binding<Bool> {
        Binding(
            get: { usesInspector == inspector && router.isShowingAssistant },
            set: { isPresented in if !isPresented { router.isShowingAssistant = false } }
        )
    }

    /// Shows a task the assistant referred to: lower the sheet, switch to Tasks and scroll to it.
    private func reveal(_ id: UUID) {
        sheetDetent = .medium
        if case .search = router.tab { router.tab = .tasks }
        board.reveal(id)
    }

    private var assistantInfo: AssistantSettingsInfo {
        let status: String
        let detail: String
        if let reason = assistant.simulationReason {
            status = String(localized: "Simulated")
            detail = String(localized: "\(simulatedExplanation(reason)) A simple rule-based assistant is standing in.")
        } else {
            status = String(localized: "Apple Intelligence")
            detail = String(localized: "The assistant runs on device with Apple Intelligence.")
        }
        return AssistantSettingsInfo(status: status, detail: detail, hasConversation: assistant.hasConversation) {
            assistant.clear()
        }
    }

    private func simulatedExplanation(_ reason: AssistantUnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible: String(localized: "Apple Intelligence isn’t available on this device.")
        case .appleIntelligenceNotEnabled: String(localized: "Apple Intelligence is turned off in Settings.")
        case .modelNotReady: String(localized: "Apple Intelligence is still getting ready.")
        case .unsupportedLanguage: String(localized: "Apple Intelligence doesn’t support your language yet.")
        case .simulatedByConfiguration: String(localized: "The simulated assistant is on for testing.")
        }
    }
}
