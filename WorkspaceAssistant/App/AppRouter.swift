import Observation

/// App-level navigation state shared by the root view and keyboard commands.
@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .tasks
    var searchQuery = ""
    /// Whether the assistant sheet is showing.
    var isShowingAssistant = false
}
