import Testing
@testable import DesignSystem
import WorkspaceDomain

@Suite("Tile palette contrast")
struct TilePaletteContrastTests {
    @Test(arguments: TileColor.allCases)
    func baseMeetsAAForWhiteText(color: TileColor) {
        #expect(TilePalette.base(color).contrast(with: .white) >= 4.5)
    }

    @Test(arguments: TileColor.allCases)
    func gradientTopMeetsLargeGraphicContrast(color: TileColor) {
        #expect(TilePalette.top(color).contrast(with: .white) >= 3.0)
    }

    @Test(arguments: TileColor.allCases)
    func increaseContrastVariantMeetsAAA(color: TileColor) {
        #expect(TilePalette.highContrast(color).contrast(with: .white) >= 7.0)
    }

    @Test func contrastMath() {
        #expect(abs(RGB.white.contrast(with: .black) - 21) < 0.01)
        #expect(abs(RGB(hex: 0x777777).contrast(with: .white) - 4.48) < 0.01)
    }

    @Test func symbolSearch() {
        #expect(SymbolCatalog.search("bug").map(\.name).contains("ladybug.fill"))
        #expect(SymbolCatalog.search("").count == SymbolCatalog.entries.count)
        #expect(Set(SymbolCatalog.entries.map(\.name)).count == SymbolCatalog.entries.count)
        #expect(SymbolCatalog.spokenName(for: "paintbrush.pointed.fill") == "paintbrush pointed")
    }
}
