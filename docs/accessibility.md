# Accessibility & polish report (Phase 6)

Scope: **iPhone** (iPad review deferred — the product is iPhone-only for now; iPad layouts exist but weren't re-reviewed).
Tested on iPhone 17 Pro Max simulator, iOS 26.3. Date: 12 Oct 2026.

Legend: ✅ verified · 🔍 verified by code review only · ⚠️ known limitation · ⏭ not done

## How it was checked

- **Automated audit**: `AccessibilityAuditTests` runs `XCUIApplication.performAccessibilityAudit()` on the Grid, Focus,
  List and Board layouts, the task editor, and the assistant with a transcript. It runs with the rest of the UI tests.
- **Screenshots** at standard, XXXL and accessibility text sizes; light and dark mode; Increase Contrast on and off.
- **Unit tests** for palette contrast (`TilePaletteContrastTests`) and for VoiceOver strings (`AssistantModelTests.actionPresentation`).

## Checklist

### VoiceOver
- ✅ Each tile and row is a single element with a label such as
  "Refactor Network Layer, Development, high priority, 1 of 3 steps done, added by assistant".
  This is asserted indirectly by the UI tests, which find tiles by label.
- 🔍 Tiles and rows have custom actions: Toggle Priority, Complete/Reopen, Edit, Delete (`taskAccessibilityActions`).
- ✅ Decorative glyphs, badges and progress rings are hidden from VoiceOver.
- ✅ Action blocks read as sentences, e.g. "Assistant prioritised Refactor Network Layer".
  The UI test locates the block by exactly this label.
- 🔍 Tool results are announced with `AccessibilityNotification.Announcement`.
- 🔍 Headers ("Everything Else", Board column titles, picker sections) have the header trait.
- ⏭ Hands-on VoiceOver walkthrough on a physical device. Recommended before release; the simulator can't run VoiceOver.

### Dynamic Type
- ✅ Only text styles are used; there are no fixed point sizes for text. Glyph sizes derive from `@ScaledMetric`.
- ✅ The grid collapses to one column at accessibility sizes, and tiles grow taller.
- ✅ Line limits apply only at the default size and below; larger sizes wrap instead of truncating
  (tiles, rows, compact Focus rows).
- ✅ The task editor header stacks the glyph above the title at accessibility sizes.
- ✅ The Board layout falls back to paging columns at accessibility sizes, even on regular width.
- ⚠️ The audit reports "Dynamic Type partially unsupported" on tile text and on the transcript timestamp.
  Screenshots at XXXL and AX-L show this text scaling and wrapping correctly, so the finding is accepted.
- ⚠️ The audit reports the `Toggle` labels as clipped at the very largest sizes. This is the system toggle row; the
  labels are allowed to wrap. Accepted.

### Colour & contrast
- ✅ White text meets WCAG AA (≥ 4.5:1) on the base colour of all 12 tile colours. Gradient tops are ≥ 3:1 for
  glyphs, and Increase Contrast variants are ≥ 7:1. These are unit tested, and *Settings → Tile Contrast* shows the measured ratios.
- ✅ Mini tiles (Board layout) use the solid base colour, because their text sits near the top of the tile.
  The audit caught this.
- ✅ Increase Contrast switches tiles to darker, solid colours in light and dark mode (screenshots reviewed).
- ✅ The assistant panel has an opaque content background, so transcript text never sits over the board showing
  through the glass sheet. The audit caught this.
- ✅ The task editor hides the tab bar, so no content is layered under the floating bar and the assistant pill.
- ✅ Priority and status are never conveyed by colour alone: star / checkmark symbols plus text in the spoken label.
- ⚠️ The audit reports "nearly passed" contrast on system secondary label colours (section headers, placeholders, the
  "Drop tasks here" hint). These are Apple's semantic colours, kept intentionally.

### Motion
- 🔍 Reduce Motion: layout changes cross-fade instead of scale; the tile pulse becomes a glow without scaling; symbol
  bounces are skipped; scrolling to tasks is instant. The zoom transition into the editor is cross-faded by the system.
- ✅ Haptics: success when a task is completed, light impact on priority changes, selection feedback on steps.

### Transparency, Bold Text, Smart Invert
- 🔍 Reduce Transparency: the composer swaps its custom glass for a solid fill. System bars, sheets and menus handle themselves.
- ✅ Glass is used only on the custom floating composer. Tiles, blocks and rows have no glass.
- 🔍 Bold Text: only system fonts and text styles are used, so Bold Text applies automatically.
- 🔍 Smart Invert: tiles and glyph squares use `accessibilityIgnoresInvertColors()` so their colours stay true.
- 🔍 Differentiate Without Colour: every state has a symbol (star, checkmark, sparkles) as well as colour.

### Targets & input
- ✅ The tile "⋯" button, step checkboxes, composer send/stop button and colour swatches are at least 44×44pt.
  The audit reports no hit-region issues.
- 🔍 Keyboard: ⌘N new task, ⌘1–4 layouts, ⌘K assistant, ⌘F search, ⌘Z / ⇧⌘Z undo/redo (system), ⌫ deletes the selection.
- 🔍 Pointer: tiles use `.hoverEffect(.lift)`; rows and buttons use the system hover effects.

### Localisation
- ✅ The String Catalog is populated (191 keys) with English plural rules for counted strings.
  Run `scripts/sync-strings.sh` after command-line builds; Xcode syncs them automatically when building in the IDE.
- ✅ RTL layouts render correctly (design-system gallery reviewed in dark + RTL).
- ⚠️ The simulated assistant's replies are English-only. The real model replies in the user's language.

## Fixed during this pass
1. Assistant transcript text over the translucent sheet failed contrast → opaque panel background.
2. Mini tiles' text on the light top of the gradient (4.07:1 on blue) → solid tiles.
3. Truncated text at large sizes (tiles, rows, Focus) → line limits lifted above the default size.
4. Editor title squeezed beside the glyph at accessibility sizes → stacked header.
5. Editor content under the floating tab bar → tab bar hidden while editing.
6. Simulated-assistant banner and Board column used translucent fills → opaque fills; banner text uses the primary colour.
7. iPad inspector reopened on launch (system restoration) → fixed, later removed when the app went iPhone-only.
8. "Ask Assistant…" pill and the editor's "Created…" footer were borderline grey → primary colour; the editor audit now waits for its push transition.
