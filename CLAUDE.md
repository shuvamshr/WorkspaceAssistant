# CLAUDE.md — Workspace Assistant v2

Rules for future sessions. The full build brief lives with the project owner; this is the short version.

## Platform
- Xcode 27, Swift 6 language mode, strict concurrency complete. iOS 26.0 deployment target (Foundation Models needs it). **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`).
- No third-party dependencies without approval. Bundle ID: `au.edu.uts.WorkspaceAssistant` (UI tests: `au.edu.uts.WorkspaceAssistantUITests`).
- Check Foundation Models signatures against the SDK swiftinterface before using them. The iOS 27 SDK deprecates
  `LanguageModelSession.GenerationError` in favour of `LanguageModelError` / `LanguageModelSession.Error`; handle both.

## Architecture
- A single SwiftUI app target (no local packages), organised by folder:
  `App/` (composition root), `Domain/`, `Persistence/`, `Agent/`, `DesignSystem/`, `Features/{Board,Assistant,Settings}/`, `Resources/`.
  Tests live in `WorkspaceAssistantTests/` (one hosted unit-test target) and `WorkspaceAssistantUITests/`.
- Default actor isolation is Swift's standard (nonisolated). Views get `MainActor` from their protocols;
  stores, models and engines are annotated `@MainActor` explicitly.
- Keep the layering by convention: only `Agent/` imports FoundationModels and only `Persistence/` imports SwiftData.
  Features talk to protocols in `Domain/` (`AssistantEngine`, `TaskRepository`).
- **Every mutation goes through `WorkspaceStore.perform(_:actor:)`** with a `WorkspaceCommand`. Each command registers
  its inverse with the `UndoManager`. New capability = command case + handler (+ optional tool).
- Tools are thin adapters: `@Generable` args → `WorkspaceCommand` → truthful result string. Never claim success a command didn't produce.
- `ScriptedEngine` stands in when Apple Intelligence is unavailable, and must always be labelled "Simulated assistant".
- "Clear conversation" only clears the conversation.

## Design
- Shortcuts-inspired tiles; quiet system chrome. Glass only on custom floating controls (composer), never on content.
- Dynamic Type text styles only — no fixed point sizes. Semantic colours for chrome; `TileColor` palette for content.
- Accent applied once at the root with `.tint`. Priority/status never by colour alone.
- Every component has previews (light, dark, AX5, RTL). Respect Reduce Motion / Transparency.

## Quality
- Swift Testing for unit tests. UI tests launch with `-UITestScriptedAssistant`.
- No warnings, no force unwraps outside tests, no `print` (use `Logger`). One primary type per file; doc comment on public types.
- After each change: build and run tests on an iPhone simulator; report honestly.
- All strings live in `Resources/Localizable.xcstrings` (main bundle).

## Current focus & workflow notes
- **iPhone only.** No iPad-specific UI; the root always uses the tab bar and an assistant sheet. Phase 7 (intents, widget, sync) is on hold.
- Launch switches (`-UITestScriptedAssistant`, `-DesignGallery`) only work in DEBUG builds.
- Use a dedicated simulator you boot yourself for manual runs — the owner may be using other booted simulators.
- `AccessibilityAuditTests` runs Xcode's accessibility audit; accepted exceptions are listed in the test and in `docs/accessibility.md`.
- After command-line builds, run `scripts/sync-strings.sh` to update the String Catalogs.
