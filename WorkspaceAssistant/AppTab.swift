import BoardFeature

/// Top-level navigation destinations.
enum AppTab: Hashable {
    case tasks
    case collections
    case collection(BoardCollection)
    case search
}
