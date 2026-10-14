import Foundation

/// Full-text search across titles, notes and step titles.
public enum TaskSearch {
    /// Tasks matching every word of `query`. An empty query returns all tasks (open first).
    public static func results(for query: String, in tasks: [TaskItem]) -> [TaskItem] {
        let words = TaskMatcher.normalize(query).split(separator: " ").map(String.init)
        let ordered = tasks.filter { !$0.isDone } + tasks.filter(\.isDone)
        guard !words.isEmpty else { return ordered }
        return ordered.filter { task in
            let haystack = TaskMatcher.normalize(([task.title, task.notes] + task.steps.map(\.title)).joined(separator: " "))
            return words.allSatisfy { haystack.contains($0) }
        }
    }
}
