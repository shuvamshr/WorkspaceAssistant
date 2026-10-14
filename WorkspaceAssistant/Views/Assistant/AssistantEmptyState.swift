import SwiftUI

/// The empty transcript: a short greeting, with suggestion tiles kept just above the composer
/// so they stay visible at the sheet's medium height.
struct AssistantEmptyState: View {
    let onSuggestion: (AssistantSuggestion) -> Void

    var body: some View {
        VStack(spacing: Spacing.s) {
            ScrollView {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)
                    Text("Ask me to organise your workspace")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("I can prioritise, add, complete and recolour tasks, or change the layout.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.m)
            }
            .scrollBounceBehavior(.basedOnSize)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    ForEach(AssistantSuggestion.defaults) { suggestion in
                        SuggestionTile(suggestion.prompt, glyph: suggestion.glyph, color: suggestion.color) {
                            onSuggestion(suggestion)
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Suggestions"))
        }
        .padding(.bottom, Spacing.xs)
    }
}
