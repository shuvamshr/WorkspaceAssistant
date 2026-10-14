# Workspace Assistant (v2)

A personal task workspace with an on-device AI assistant built on Apple's Foundation Models framework.
You can manage tasks directly (tap, swipe, drag) or ask the assistant in natural language. The assistant
acts through typed tools that issue the same `WorkspaceCommand`s as the UI, so every change is undoable and visible.

The design language is modelled on Apple's Shortcuts app: colourful glyph tiles, collections in a sidebar,
a block-based editor, and assistant tool calls rendered as Shortcuts-style action blocks.

## Requirements

- Xcode 27, Swift 6 (strict concurrency: complete)
- iOS 26.0+ (iPhone)
- Apple Intelligence is optional. Without it, a clearly-labelled scripted assistant stands in.

## Layout

```
WorkspaceAssistant/            The app (single target)
  App/                         @main, composition root, root view, commands
  Domain/                      Models, commands, store, protocols (no SwiftUI / SwiftData)
  Persistence/                 SwiftData repository + UserDefaults preferences
  Agent/                       Foundation Models engine, tools, scripted engine
  DesignSystem/                Tokens, tile colours, reusable components
  Features/Board/              Board, four layouts, task editor, search, collections
  Features/Assistant/          Assistant transcript, composer, suggestions
  Features/Settings/           Settings form
  Resources/                   Assets and the String Catalog
WorkspaceAssistantTests/       Swift Testing unit tests
WorkspaceAssistantUITests/     UI tests (run with -UITestScriptedAssistant)
docs/                          Accessibility report, app icon
```

Layering (by convention): `Domain ← Persistence`, `Domain ← Agent`, `Domain + DesignSystem ← Features`, `everything ← App`.

## Build and test

```bash
xcodebuild -project WorkspaceAssistant.xcodeproj -scheme WorkspaceAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The shared scheme runs the unit tests and the UI tests.
