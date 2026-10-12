# CLAUDE.md — Workspace Assistant v2

Rules for future sessions. The full build brief lives with the project owner; this is the short version.

## Platform
- Xcode 27, Swift 6 language mode, strict concurrency complete. iOS 26.0 deployment target (Foundation Models needs it). iPhone + iPad.
- No third-party dependencies without approval. Bundle ID placeholder: `com.example.WorkspaceAssistant` (confirm with owner).
- Check Foundation Models signatures against the SDK swiftinterface before using them. The iOS 27 SDK deprecates
  `LanguageModelSession.GenerationError` in favour of `LanguageModelError` / `LanguageModelSession.Error`; handle both.

## Architecture
- App target is a thin composition root. Code lives in `Packages/WorkspaceKit`.
- `WorkspaceDomain`, `WorkspacePersistence`, `WorkspaceAgent` are nonisolated by default (be explicit).
  UI modules (`DesignSystem`, `*Feature`) default to `MainActor` isolation.
- Features never import FoundationModels or SwiftData; they use protocols from Domain (`AssistantEngine`, `TaskRepository`).
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
- Strings in package modules use `bundle: .module` and the module's `Localizable.xcstrings`.
