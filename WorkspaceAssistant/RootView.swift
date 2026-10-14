import AssistantFeature
import BoardFeature
import DesignSystem
import SettingsFeature
import SwiftUI
import WorkspaceDomain

/// The app's root: a tab bar (Tasks, Collections, Search) with the assistant always reachable
/// from the bottom accessory as a sheet.
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(BoardModel.self) private var board
    @Environment(AssistantModel.self) private var assistant
    @Environment(\.undoManager) private var undoManager
    @State private var sheetDetent: PresentationDetent = .medium

    var body: some View {
        @Bindable var router = router
        @Bindable var board = board
        TabView(selection: $router.tab) {
            Tab(value: AppTab.tasks) {
                BoardScreen(collection: .all)
            } label: {
                Label { Text("Tasks") } icon: { Image(systemName: "square.grid.2x2") }
            }

            Tab(value: AppTab.collections) {
                CollectionsScreen()
            } label: {
                Label { Text("Collections") } icon: { Image(systemName: "folder") }
            }

            Tab(value: AppTab.search, role: .search) {
                SearchScreen(query: $router.searchQuery)
            } label: {
                Label { Text("Search") } icon: { Image(systemName: "magnifyingglass") }
            }
        }
        .tabViewBottomAccessory {
            AskAssistantAccessory {
                router.isShowingAssistant.toggle()
                if router.isShowingAssistant { assistant.requestFocus() }
            }
        }
        .sheet(isPresented: $router.isShowingAssistant) {
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
    }

    /// Shows a task the assistant referred to: lower the sheet, switch to Tasks and scroll to it.
    private func reveal(_ id: UUID) {
        sheetDetent = .medium
        router.tab = .tasks
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
