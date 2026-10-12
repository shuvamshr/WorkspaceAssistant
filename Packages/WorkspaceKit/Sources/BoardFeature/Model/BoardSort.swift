import Foundation
import WorkspaceDomain

/// How the board orders tasks. Drag-to-reorder is only available in `manual`.
public enum BoardSort: String, CaseIterable, Identifiable, Sendable {
    case manual, title, newest

    public var id: String { rawValue }

    /// Localised name.
    public var displayName: String {
        switch self {
        case .manual: String(localized: "Manual", bundle: .module)
        case .title: String(localized: "Title", bundle: .module)
        case .newest: String(localized: "Newest First", bundle: .module)
        }
    }

    func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        switch self {
        case .manual: tasks
        case .title: tasks.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .newest: tasks.sorted { $0.createdAt > $1.createdAt }
        }
    }
}
