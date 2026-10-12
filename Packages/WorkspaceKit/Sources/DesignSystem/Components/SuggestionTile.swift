import SwiftUI
import WorkspaceDomain

/// A small Shortcuts-style tile for a suggested prompt.
public struct SuggestionTile: View {
    private let text: String
    private let glyph: String
    private let color: TileColor
    private let action: () -> Void
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .subheadline) private var width: CGFloat = 168
    @ScaledMetric(relativeTo: .subheadline) private var minHeight: CGFloat = 96

    public init(_ text: String, glyph: String, color: TileColor, action: @escaping () -> Void) {
        self.text = text
        self.glyph = glyph
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: glyph)
                    .font(.headline)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(color.foreground)
            .padding(Spacing.s)
            .frame(width: width, alignment: .leading)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background(color.background(contrast: contrast), in: Radius.blockShape)
            .contentShape(Radius.blockShape)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .accessibilityLabel(text)
        .accessibilityHint(Text("Sends this request to the assistant", bundle: .module))
    }
}

#Preview("Light") {
    ScrollView(.horizontal) {
        HStack {
            SuggestionTile("Prioritise the network refactor and switch to Focus", glyph: "star.fill", color: .orange) {}
            SuggestionTile("Show my tasks as a Board", glyph: "rectangle.split.3x1", color: .blue) {}
        }
        .padding()
    }
}

#Preview("Dark") {
    SuggestionTile("Change the accent colour to green", glyph: "paintpalette.fill", color: .purple) {}.preferredColorScheme(.dark)
}

#Preview("AX5") {
    SuggestionTile("Add a priority task for code review", glyph: "plus", color: .green) {}.dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    SuggestionTile("Show my tasks as a Board", glyph: "rectangle.split.3x1", color: .blue) {}.environment(\.layoutDirection, .rightToLeft)
}
