import SwiftUI

/// Small status symbols for a task: priority star, done checkmark and assistant sparkles.
/// Decorative — the owning tile or row carries the spoken label.
public struct TaskBadges: View {
    private let task: TaskItem

    public init(task: TaskItem) {
        self.task = task
    }

    public var body: some View {
        HStack(spacing: Spacing.xxs) {
            if task.isHighPriority { Image(systemName: "star.fill") }
            if task.isDone { Image(systemName: "checkmark.circle.fill") }
            if task.origin == .assistant { Image(systemName: "sparkles") }
        }
        .accessibilityHidden(true)
    }
}
