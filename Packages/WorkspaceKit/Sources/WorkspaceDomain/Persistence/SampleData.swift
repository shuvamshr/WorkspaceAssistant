import Foundation

/// The six tasks seeded on first launch (carried over from the prototype).
public enum SampleData {
    /// Fresh copies of the sample tasks, ordered by `sortIndex`.
    public static func tasks(now: Date = .now) -> [TaskItem] {
        let specs: [(String, TaskCategory, [String])] = [
            ("Refactor Network Layer", .development, ["Audit URLSession call sites", "Introduce async API client", "Migrate feed endpoints"]),
            ("Write Unit Test Suite", .testing, ["Cover the command layer", "Add persistence round-trip tests"]),
            ("Redesign Onboarding Flow", .design, []),
            ("Set Up CI/CD Pipeline", .operations, ["Configure build workflow", "Add TestFlight upload"]),
            ("Fix Memory Leak in Feed", .development, []),
            ("Accessibility Audit", .testing, ["VoiceOver pass", "Dynamic Type at AX5"]),
        ]
        return specs.enumerated().map { index, spec in
            TaskItem(
                title: spec.0,
                category: spec.1,
                steps: spec.2.map { TaskStep(title: $0) },
                createdAt: now.addingTimeInterval(Double(-index) * 3600),
                sortIndex: Double(index)
            )
        }
    }
}
