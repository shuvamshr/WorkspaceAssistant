import SwiftUI

/// A piece of an action block's sentence.
public enum ActionBlockPart: Hashable, Sendable {
    /// The leading verb, drawn in bold ("Prioritise").
    case verb(String)
    /// Plain connecting text ("to").
    case text(String)
    /// A parameter, drawn as a token pill.
    case token(String)
}

/// A Shortcuts-editor-style action card: coloured glyph square, a verb, and inline token pills.
/// Used to show exactly what the assistant did.
public struct ActionBlock<Accessory: View>: View {
    public typealias Part = ActionBlockPart

    private let glyph: String
    private let color: TileColor
    private let parts: [Part]
    private let failureReason: String?
    private let accessibilitySentence: String
    private let accessory: Accessory

    /// - Parameters:
    ///   - failureReason: When set, the block shows a warning glyph and this reason.
    ///   - accessibilitySentence: What VoiceOver reads, e.g. "Assistant prioritised Refactor Network Layer".
    public init(
        glyph: String,
        color: TileColor,
        parts: [Part],
        failureReason: String? = nil,
        accessibilitySentence: String,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.glyph = glyph
        self.color = color
        self.parts = parts
        self.failureReason = failureReason
        self.accessibilitySentence = accessibilitySentence
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            if failureReason == nil {
                GlyphSquare(glyph: glyph, color: color, size: .medium)
            } else {
                GlyphSquare(glyph: "exclamationmark.triangle.fill", color: .yellow, size: .medium)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                FlowLayout {
                    ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                        partView(part)
                    }
                }
                if let failureReason {
                    Text(failureReason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory
        }
        .padding(Spacing.s)
        .background(Color(.secondarySystemGroupedBackground), in: Radius.blockShape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySentence)
    }

    @ViewBuilder private func partView(_ part: Part) -> some View {
        switch part {
        case let .verb(text): Text(text).font(.subheadline.weight(.semibold))
        case let .text(text): Text(text).font(.subheadline)
        case let .token(text): TokenPill(text)
        }
    }
}

extension ActionBlock where Accessory == EmptyView {
    /// Creates an action block without a trailing accessory.
    public init(glyph: String, color: TileColor, parts: [Part], failureReason: String? = nil, accessibilitySentence: String) {
        self.init(
            glyph: glyph, color: color, parts: parts, failureReason: failureReason,
            accessibilitySentence: accessibilitySentence
        ) { EmptyView() }
    }
}

private struct ActionBlockGallery: View {
    var body: some View {
        VStack(spacing: Spacing.s) {
            ActionBlock(glyph: "star.fill", color: .orange, parts: [.verb("Prioritise"), .token("Refactor Network Layer")], accessibilitySentence: "Assistant prioritised Refactor Network Layer")
            ActionBlock(glyph: "square.grid.2x2", color: .blue, parts: [.verb("Switch layout to"), .token("Focus")], accessibilitySentence: "Assistant switched layout to Focus")
            ActionBlock(glyph: "star.fill", color: .orange, parts: [.verb("Prioritise"), .token("pipeline-x")], failureReason: "No task matches “pipeline-x”.", accessibilitySentence: "Assistant couldn't prioritise pipeline-x")
            ActionBlock(glyph: "trash", color: .red, parts: [.verb("Delete"), .token("Accessibility Audit")], accessibilitySentence: "Assistant deleted Accessibility Audit") {
                Button("Undo") {}.buttonStyle(.bordered).controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("Light") { ActionBlockGallery() }
#Preview("Dark") { ActionBlockGallery().preferredColorScheme(.dark) }
#Preview("AX5") { ScrollView { ActionBlockGallery() }.dynamicTypeSize(.accessibility5) }
#Preview("RTL") { ActionBlockGallery().environment(\.layoutDirection, .rightToLeft) }
