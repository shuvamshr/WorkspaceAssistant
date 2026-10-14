import Foundation

/// Resolves free-text queries ("the network refactor") to tasks.
///
/// Matching is case-, diacritic- and width-insensitive. It tries, in order: an id, an exact title,
/// a title containing the phrase, then titles containing every meaningful word (prefix match, so
/// "testing" matches "Test"). Open tasks are searched first; done tasks only if nothing open matches.
public enum TaskMatcher {
    /// Words ignored when matching word-by-word.
    static let stopWords: Set<String> = [
        "a", "an", "the", "my", "our", "this", "that", "task", "tasks", "item", "to", "for", "of", "on", "in", "and",
    ]

    /// Resolves `query` against `tasks`.
    public static func match(_ query: String, in tasks: [TaskItem]) -> TaskMatch {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = UUID(uuidString: trimmed), let task = tasks.first(where: { $0.id == id }) {
            return .unique(task)
        }
        let open = tasks.filter { !$0.isDone }
        let firstPass = match(normalized: normalize(trimmed), in: open)
        if firstPass != .none { return firstPass }
        return match(normalized: normalize(trimmed), in: tasks.filter(\.isDone))
    }

    /// Folds case, diacritics and width, strips punctuation, and collapses whitespace.
    public static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        let cleaned = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(cleaned).split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func match(normalized query: String, in tasks: [TaskItem]) -> TaskMatch {
        guard !query.isEmpty, !tasks.isEmpty else { return .none }
        let titled = tasks.map { (task: $0, title: normalize($0.title)) }

        let exact = titled.filter { $0.title == query }.map(\.task)
        if let result = resolve(exact) { return result }

        let phrase = titled.filter { $0.title.contains(query) }.map(\.task)
        if let result = resolve(phrase) { return result }

        let tokens = query.split(separator: " ").map(String.init).filter { !stopWords.contains($0) }
        guard !tokens.isEmpty else { return .none }
        let wordMatches = titled.filter { entry in
            let words = entry.title.split(separator: " ").map(String.init)
            return tokens.allSatisfy { token in words.contains { wordMatches(token: token, word: $0) } }
        }.map(\.task)
        return resolve(wordMatches) ?? .none
    }

    private static func wordMatches(token: String, word: String) -> Bool {
        if word.hasPrefix(token) { return true }
        // Allow simple inflections: "testing" → "test", "refactoring" → "refactor".
        return word.count >= 4 && token.hasPrefix(word)
    }

    private static func resolve(_ candidates: [TaskItem]) -> TaskMatch? {
        switch candidates.count {
        case 0: nil
        case 1: .unique(candidates[0])
        default: .ambiguous(candidates)
        }
    }
}
