import SwiftUI

/// Shows every tile colour with its gradient, solid Increase Contrast variant, and measured
/// WCAG contrast against white. Used to verify the palette in light and dark mode.
public struct TileContrastSheet: View {
    public init() {}

    public var body: some View {
        List {
            Section {
                ForEach(TileColor.allCases) { color in
                    HStack(spacing: Spacing.s) {
                        sample(color, style: color.background(contrast: .standard), label: "Aa")
                        sample(color, style: color.background(contrast: .increased), label: "Aa")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(color.displayName).font(.headline)
                            Text(verbatim: ratioLine(color)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        let passes = TilePalette.base(color).contrast(with: .white) >= 4.5
                        Label(passes ? "AA" : "Fail", systemImage: passes ? "checkmark.seal.fill" : "xmark.octagon.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption.bold())
                            .foregroundStyle(passes ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
                    }
                }
            } footer: {
                Text("Base = text background; Top = glyph background (needs 3:1); HC = Increase Contrast.")
            }
        }
    }

    private func sample(_ color: TileColor, style: AnyShapeStyle, label: String) -> some View {
        Text(verbatim: label)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 56, height: 56, alignment: .bottomLeading)
            .padding(Spacing.xs)
            .background(style, in: Radius.blockShape)
            .accessibilityHidden(true)
    }

    private func ratioLine(_ color: TileColor) -> String {
        let base = TilePalette.base(color).contrast(with: .white)
        let top = TilePalette.top(color).contrast(with: .white)
        let high = TilePalette.highContrast(color).contrast(with: .white)
        return String(format: "Base %.2f · Top %.2f · HC %.2f", base, top, high)
    }
}

#Preview("Light") { TileContrastSheet() }
#Preview("Dark") { TileContrastSheet().preferredColorScheme(.dark) }
#Preview("AX5") { TileContrastSheet().dynamicTypeSize(.accessibility5) }
#Preview("RTL") { TileContrastSheet().environment(\.layoutDirection, .rightToLeft) }
