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
WorkspaceAssistant/          App target: @main, composition root, assets
WorkspaceAssistantUITests/   UI tests (run with -UITestScriptedAssistant)
Packages/WorkspaceKit/
  Sources/
    WorkspaceDomain/         Models, commands, store, protocols (no SwiftUI / SwiftData)
    WorkspacePersistence/    SwiftData repository + UserDefaults preferences
    WorkspaceAgent/          Foundation Models engine, tools, scripted engine
    DesignSystem/            Tokens, tile colours, reusable components
    BoardFeature/            Board, four layouts, task editor, search, collections
    AssistantFeature/        Assistant transcript, composer, suggestions
    SettingsFeature/         Settings form
  Tests/                     Swift Testing suites per module
docs/                        Accessibility report and other notes
```

Dependency direction: `Domain ← Persistence`, `Domain ← Agent`, `Domain + DesignSystem ← Features`, `everything ← App`.

## Build and test

```bash
xcodebuild -project WorkspaceAssistant.xcodeproj -scheme WorkspaceAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The shared scheme runs every package test target plus the UI tests.
