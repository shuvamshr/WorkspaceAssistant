import Foundation
import WorkspaceDomain

/// A suggested prompt shown as a tile in the empty state.
public struct AssistantSuggestion: Identifiable, Hashable, Sendable {
    public let id: String
    public let prompt: String
    public let glyph: String
    public let color: TileColor

    /// The five starter prompts.
    public static var defaults: [AssistantSuggestion] {
        [
            AssistantSuggestion(id: "focus", prompt: String(localized: "Prioritise the network refactor and switch to Focus", bundle: .module), glyph: "scope", color: .orange),
            AssistantSuggestion(id: "board", prompt: String(localized: "Show my tasks as a Board", bundle: .module), glyph: "rectangle.split.3x1.fill", color: .blue),
            AssistantSuggestion(id: "add", prompt: String(localized: "Add a priority task for code review", bundle: .module), glyph: "plus", color: .green),
            AssistantSuggestion(id: "accent", prompt: String(localized: "Change the accent colour to green", bundle: .module), glyph: "paintpalette.fill", color: .purple),
            AssistantSuggestion(id: "testing", prompt: String(localized: "Prioritise all testing tasks and use List view", bundle: .module), glyph: "checkmark.seal.fill", color: .teal),
        ]
    }
}
