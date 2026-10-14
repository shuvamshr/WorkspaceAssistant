import SwiftUI

/// Choose a tile colour and glyph, like Shortcuts' "Choose Icon".
/// Place inside a `NavigationStack`; it adds a search field for symbols.
public struct AppearancePicker: View {
    @Binding private var appearance: TileAppearance
    @State private var query = ""
    @ScaledMetric(relativeTo: .body) private var swatch: CGFloat = 44
    @ScaledMetric(relativeTo: .title2) private var symbolCell: CGFloat = 52

    public init(appearance: Binding<TileAppearance>) {
        _appearance = appearance
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                GlyphSquare(appearance, size: .extraLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.s)

                section(Text("Colour")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: swatch + Spacing.s), spacing: Spacing.s)], spacing: Spacing.s) {
                        ForEach(TileColor.allCases) { color in colorSwatch(color) }
                    }
                }

                section(Text("Glyph")) {
                    let results = SymbolCatalog.search(query)
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: symbolCell), spacing: Spacing.xs)], spacing: Spacing.xs) {
                            ForEach(results) { entry in symbolButton(entry.name) }
                        }
                    }
                }
            }
            .padding(Spacing.m)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $query, prompt: Text("Search Glyphs"))
    }

    private func section<Content: View>(_ title: Text, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            title.font(.headline).accessibilityAddTraits(.isHeader)
            content()
                .padding(Spacing.s)
                .background(Color(.secondarySystemGroupedBackground), in: Radius.blockShape)
        }
    }

    private func colorSwatch(_ color: TileColor) -> some View {
        let isSelected = appearance.color == color
        return Button {
            appearance.color = color
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: swatch, height: swatch)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(.white)
                    }
                }
                .padding(3)
                .overlay { Circle().strokeBorder(isSelected ? Color.primary : .clear, lineWidth: 2) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func symbolButton(_ name: String) -> some View {
        let isSelected = appearance.glyph == name
        return Button {
            appearance.glyph = name
        } label: {
            Image(systemName: name)
                .font(.title2)
                .frame(width: symbolCell, height: symbolCell)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .background(
                    isSelected ? AnyShapeStyle(appearance.color.color) : AnyShapeStyle(.fill.tertiary),
                    in: Radius.chipShape
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SymbolCatalog.spokenName(for: name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct AppearancePickerPreview: View {
    @State var appearance = TaskCategory.design.defaultAppearance
    var body: some View {
        NavigationStack { AppearancePicker(appearance: $appearance).navigationTitle("Appearance") }
    }
}

#Preview("Light") { AppearancePickerPreview() }
#Preview("Dark") { AppearancePickerPreview().preferredColorScheme(.dark) }
#Preview("AX5") { AppearancePickerPreview().dynamicTypeSize(.accessibility5) }
#Preview("RTL") { AppearancePickerPreview().environment(\.layoutDirection, .rightToLeft) }
