import SwiftUI

/// A rounded, tile-coloured square with a white SF Symbol — the app's icon vocabulary.
public struct GlyphSquare: View {
    /// Preset sizes (scaled with Dynamic Type).
    public enum Size: Sendable {
        case small, medium, large, extraLarge

        var points: CGFloat {
            switch self {
            case .small: 28
            case .medium: 36
            case .large: 56
            case .extraLarge: 88
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: 7
            case .medium: 9
            case .large: Radius.block
            case .extraLarge: Radius.tile
            }
        }
    }

    private let glyph: String
    private let color: TileColor
    private let size: Size
    @ScaledMetric private var side: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast

    /// Creates a glyph square from a tile appearance.
    public init(_ appearance: TileAppearance, size: Size = .medium) {
        self.init(glyph: appearance.glyph, color: appearance.color, size: size)
    }

    /// Creates a glyph square from a symbol name and colour.
    public init(glyph: String, color: TileColor, size: Size = .medium) {
        self.glyph = glyph
        self.color = color
        self.size = size
        _side = ScaledMetric(wrappedValue: size.points, relativeTo: .body)
    }

    public var body: some View {
        // The glyph is sized relative to the scaled square so it tracks Dynamic Type.
        Image(systemName: glyph)
            .font(.system(size: side * 0.48, weight: .semibold))
            .foregroundStyle(color.foreground)
            .frame(width: side, height: side)
            .background(color.background(contrast: contrast), in: RoundedRectangle(cornerRadius: size.cornerRadius * side / size.points, style: .continuous))
            .accessibilityIgnoresInvertColors()
            .accessibilityHidden(true)
    }
}

#Preview("Light") {
    HStack {
        ForEach(TaskCategory.allCases) { GlyphSquare($0.defaultAppearance, size: .large) }
    }
    .padding()
}

#Preview("Dark") {
    HStack {
        ForEach(TaskCategory.allCases) { GlyphSquare($0.defaultAppearance, size: .medium) }
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("AX5") {
    GlyphSquare(TaskCategory.design.defaultAppearance, size: .small)
        .dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    HStack {
        GlyphSquare(glyph: "arrow.forward", color: .indigo)
        Text(verbatim: "مهمة")
    }
    .environment(\.layoutDirection, .rightToLeft)
}
