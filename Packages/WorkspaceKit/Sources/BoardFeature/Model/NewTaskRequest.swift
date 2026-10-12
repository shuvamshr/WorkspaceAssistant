import Foundation
import WorkspaceDomain

/// A request to present the new-task sheet.
public struct NewTaskRequest: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let category: TaskCategory

    public init(category: TaskCategory = .development) {
        self.category = category
    }
}
