import Foundation
import WorkspaceDomain

/// Deterministic, rule-based parsing of simple workspace requests (English).
/// Covers the suggested prompts and common variations; anything else returns no intents.
public enum ScriptedIntentParser {
    /// Parses a prompt into zero or more intents, in order.
    public static func parse(_ prompt: String) -> [ScriptedIntent] {
        var intents: [ScriptedIntent] = []
        for clause in clauses(of: prompt) {
            if isPriorityFollowUp(clause), case let .addTask(title, category, _)? = intents.last {
                intents[intents.count - 1] = .addTask(title: title, category: category, priority: .high)
                continue
            }
            if let intent = parseClause(clause) { intents.append(intent) }
        }
        return intents
    }

    // MARK: - Clauses

    static func clauses(of prompt: String) -> [String] {
        var text = " " + prompt.lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "’", with: "'") + " "
        for separator in [", and then ", " and then ", ", then ", " then ", ", and ", " and ", ";", ","] {
            text = text.replacingOccurrences(of: separator, with: "|")
        }
        return text.split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters.subtracting(CharacterSet(charactersIn: "/-")))) }
            .filter { !$0.isEmpty }
    }

    private static func isPriorityFollowUp(_ clause: String) -> Bool {
        let words = clause.split(separator: " ")
        return words.count <= 6 && (clause.hasPrefix("mark it") || clause.hasPrefix("make it") || clause.hasPrefix("set it"))
            && (clause.contains("priority") || clause.contains("urgent") || clause.contains("important"))
    }

    private static func parseClause(_ clause: String) -> ScriptedIntent? {
        if let intent = parseLayout(clause) { return intent }
        if let intent = parseAccent(clause) { return intent }
        if let intent = parseAddStep(clause) { return intent }
        if let intent = parseAddTask(clause) { return intent }
        if let intent = parsePriority(clause) { return intent }
        if let intent = parseComplete(clause) { return intent }
        if let intent = parseDelete(clause) { return intent }
        if let intent = parseTaskColor(clause) { return intent }
        if let intent = parseFind(clause) { return intent }
        return nil
    }

    // MARK: - Layout and accent

    private static func parseLayout(_ clause: String) -> ScriptedIntent? {
        let cues = ["switch", "show", "use", "view", "layout", "mode", "display", "change to", "go to", "as a", "as"]
        guard cues.contains(where: clause.contains) else { return nil }
        let words = Set(clause.split(separator: " ").map(String.init))
        let mapping: [(String, BoardLayout)] = [
            ("grid", .grid), ("tiles", .grid), ("list", .list), ("compact", .list), ("rows", .list),
            ("focus", .focus), ("board", .board), ("kanban", .board), ("columns", .board),
        ]
        guard !clause.contains("task for"), !clause.contains("accent") else { return nil }
        return mapping.first { words.contains($0.0) }.map { .switchLayout($0.1) }
    }

    private static func parseAccent(_ clause: String) -> ScriptedIntent? {
        guard clause.contains("accent") || clause.contains("theme") || clause.contains("tint")
            || (clause.contains("app") && (clause.contains("colour") || clause.contains("color"))) else { return nil }
        let words = clause.split(separator: " ").map(String.init)
        return words.compactMap(AccentTheme.init(rawValue:)).last.map(ScriptedIntent.setAccent)
    }

    // MARK: - Tasks

    private static func parseAddStep(_ clause: String) -> ScriptedIntent? {
        guard let match = clause.firstMatch(of: /^add (?:a )?(?:new )?step (?:called |named )?["']?(.+?)["']? (?:to|on|for) (?:the )?(.+)$/) else { return nil }
        return .addStep(query: cleanQuery(String(match.2)), step: titleCase(String(match.1)))
    }

    private static func parseAddTask(_ clause: String) -> ScriptedIntent? {
        guard let match = clause.firstMatch(of: /^(?:please )?(?:add|create|make|new)(?: me)?(?: an?| another)?(?: new)?(?: (high[- ]priority|priority|urgent|important))?(?: new)? (?:task|to-?do|item)(?: (?:for|called|named|to|about))?\s*(.*)$/) else { return nil }
        var rest = String(match.2)
        var priority: TaskPriority = match.1 == nil ? .normal : .high
        for suffix in [" as priority", " as a priority", " as high priority", " with high priority", " high priority", " priority"] where rest.hasSuffix(suffix) {
            rest.removeLast(suffix.count)
            priority = .high
        }
        let title = rest.trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
        guard !title.isEmpty else { return nil }
        return .addTask(title: titleCase(title), category: inferCategory(title), priority: priority)
    }

    private static func parsePriority(_ clause: String) -> ScriptedIntent? {
        let deprioritise = /^(?:please )?(?:deprioriti[sz]e|unprioriti[sz]e|lower(?: the)? priority (?:of|for)|remove(?: the)? priority (?:from|of|on)) (.+)$/
        let prioritise = /^(?:please )?(?:prioriti[sz]e|star|flag|focus on|bump up|raise(?: the)? priority (?:of|for)) (.+)$/
        let makePriority = /^make (.+?) (?:a |high )?priority$/

        var query: String?
        var priority: TaskPriority = .high
        if let match = clause.firstMatch(of: deprioritise) {
            query = String(match.1)
            priority = .normal
        } else if let match = clause.firstMatch(of: prioritise) {
            query = String(match.1)
        } else if let match = clause.firstMatch(of: makePriority) {
            query = String(match.1)
        }
        guard let query else { return nil }

        if let category = categoryReference(in: query) {
            return .setCategoryPriority(category, priority)
        }
        return .setPriority(query: cleanQuery(query), priority)
    }

    private static func parseComplete(_ clause: String) -> ScriptedIntent? {
        if let match = clause.firstMatch(of: /^(?:please )?(?:complete|finish|close|check off|tick off) (.+)$/) {
            return .complete(query: cleanQuery(String(match.1)))
        }
        if let match = clause.firstMatch(of: /^mark (.+?) (?:as )?(?:done|complete|completed|finished)$/) {
            return .complete(query: cleanQuery(String(match.1)))
        }
        return nil
    }

    private static func parseDelete(_ clause: String) -> ScriptedIntent? {
        guard let match = clause.firstMatch(of: /^(?:please )?(?:delete|remove|trash|get rid of) (.+)$/) else { return nil }
        return .delete(query: cleanQuery(String(match.1)))
    }

    private static func parseTaskColor(_ clause: String) -> ScriptedIntent? {
        guard let match = clause.firstMatch(of: /^(?:make|colou?r|turn|change|paint) (?:the )?(.+?) (?:tile )?(?:to |into |in )?(red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|gray|grey)$/),
              let color = TileColor(rawValue: match.2 == "grey" ? "gray" : String(match.2)) else { return nil }
        let query = cleanQuery(String(match.1).replacingOccurrences(of: " tile", with: ""))
        guard !query.isEmpty else { return nil }
        return .setTaskColor(query: query, color)
    }

    private static func parseFind(_ clause: String) -> ScriptedIntent? {
        guard let match = clause.firstMatch(of: /^(?:find|search for|look up|show me|where is|where's) (.+)$/) else { return nil }
        return .find(query: cleanQuery(String(match.1)))
    }

    // MARK: - Helpers

    /// "all testing tasks", "the design tasks", "every ops task" → category.
    static func categoryReference(in query: String) -> TaskCategory? {
        guard query.contains("tasks") || query.hasPrefix("all ") || query.hasPrefix("every ") else { return nil }
        let words = Set(query.split(separator: " ").map(String.init))
        let mapping: [(Set<String>, TaskCategory)] = [
            (["testing", "test", "qa"], .testing),
            (["development", "dev", "engineering", "coding"], .development),
            (["design", "ui", "ux"], .design),
            (["operations", "ops", "devops", "infrastructure"], .operations),
        ]
        return mapping.first { !$0.0.isDisjoint(with: words) }?.1
    }

    /// Strips filler words around a task reference.
    static func cleanQuery(_ text: String) -> String {
        var words = text.split(separator: " ").map(String.init)
        while let first = words.first, ["the", "my", "a", "an", "task", "item"].contains(first) { words.removeFirst() }
        while let last = words.last, ["task", "item", "please", "now"].contains(last) { words.removeLast() }
        return words.joined(separator: " ")
    }

    /// A best guess at the category for a new task title.
    static func inferCategory(_ title: String) -> TaskCategory {
        let text = title.lowercased()
        if ["test", "qa", "audit", "verify", "review"].contains(where: text.contains) { return text.contains("code review") ? .development : .testing }
        if ["design", "ui", "ux", "mockup", "icon", "layout"].contains(where: text.contains) { return .design }
        if ["deploy", "ci", "pipeline", "server", "release", "infra", "monitor"].contains(where: text.contains) { return .operations }
        return .development
    }

    /// Capitalises the first letter of each word.
    static func titleCase(_ text: String) -> String {
        text.split(separator: " ").map { word in
            word.prefix(1).uppercased() + word.dropFirst()
        }.joined(separator: " ")
    }
}
