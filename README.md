# Workspace Assistant

A task list for iPhone with a built-in AI assistant that runs **entirely on device** using Apple's
[Foundation Models](https://developer.apple.com/documentation/foundationmodels) framework (Apple Intelligence).

You can manage tasks by tapping, swiping and dragging — or type something like
*"prioritise the network refactor and switch to Focus"* and watch the assistant do it for you.

This README is written for iOS students: it explains **how the app works** and gives you a **step-by-step path to build
something like it yourself**.

---

## 1. What you'll learn from this project

| Topic | Where to look |
|---|---|
| SwiftUI app structure, `TabView`, sheets, navigation | `WorkspaceAssistant/App/` |
| Observation (`@Observable`) for app state | `Domain/Store/WorkspaceStore.swift`, `Features/*/Model/` |
| SwiftData for saving data | `Persistence/` |
| Foundation Models: sessions, streaming, **tool calling** | `Agent/` |
| Undo/redo with `UndoManager` | `Domain/Store/WorkspaceStore.swift` |
| Reusable UI components and a small design system | `DesignSystem/` |
| Accessibility (VoiceOver, Dynamic Type, contrast) | everywhere — see `docs/accessibility.md` |
| Unit tests with Swift Testing, UI tests with XCTest | `WorkspaceAssistantTests/`, `WorkspaceAssistantUITests/` |

---

## 2. Run it

**You need:** a Mac with Xcode 27 (or newer). The app targets **iOS 26+** on iPhone.

1. Open `WorkspaceAssistant.xcodeproj` in Xcode.
2. Choose an iPhone simulator (e.g. *iPhone 17*) and press **⌘R**.
3. To run all tests, press **⌘U**.

**No Apple Intelligence? No problem.** On the Simulator or on a phone without Apple Intelligence, the app automatically
uses a **"Simulated assistant"** — a simple rule-based stand-in that understands short requests like the suggestion
tiles. It's clearly labelled in the app so you always know which one you're using.

### Try these
- Tap a tile to open a task. Tap **+** to add one. Press and hold a tile for more actions.
- Use the view button (top right) to switch between **Grid**, **List**, **Focus** and **Board**.
- Tap **Ask Assistant…** and try: *"Add a priority task for code review"* or *"Show my tasks as a Board"*.
- Shake the device (or press ⌘Z in the Simulator) to **undo** — even things the assistant did.

---

## 3. The big idea (read this first)

The whole app is built around one rule:

> **Every change goes through one place, as a "command".**

Whether you tap the ★ button or the AI decides to prioritise a task, the same thing happens:

```
   You tap ★                     AI calls a tool
       │                               │
       ▼                               ▼
  BoardModel.togglePriority     SetTaskPriorityTool.call
       │                               │
       └──────────────┬────────────────┘
                      ▼
     WorkspaceCommand.setPriority(ids:, .high)
                      ▼
           WorkspaceStore.perform(...)
          ┌───────────┼─────────────────┐
          ▼           ▼                 ▼
     update tasks   save to disk   register undo
                      ▼
           SwiftUI views refresh automatically
```

Why this matters:
- **Undo works for everything**, including AI changes, because each command knows how to reverse itself.
- **The AI can't do anything you can't do** — it only has access to the same commands.
- **It's easy to test**: every behaviour is a command you can run in a unit test.
- **Adding a feature** = add a command case, handle it in the store, optionally add a tool for the AI.

Open these two files side by side and read them — they are the heart of the app:
- [`WorkspaceCommand.swift`](WorkspaceAssistant/Domain/Commands/WorkspaceCommand.swift) — the list of every possible change.
- [`WorkspaceStore.swift`](WorkspaceAssistant/Domain/Store/WorkspaceStore.swift) — applies commands, saves, and registers undo.

---

## 4. How the AI part works

Foundation Models gives you an on-device language model. On its own it can only produce text. **Tool calling** lets it
*do* things: you describe some functions ("tools"), and the model decides when to call them.

### Following one request

When you type *"prioritise the network refactor"*:

1. **`AssistantModel`** (the assistant screen's state) sends the text to the engine.
2. **`FoundationModelsEngine`** passes it to a long-lived `LanguageModelSession` that was created with the app's tools.
   Keeping one session means the model **remembers the conversation**, so follow-ups like "now undo that" make sense.
3. The model decides to call **`setTaskPriority`** with arguments `query: "network refactor", priority: high`.
4. The tool asks **`WorkspaceToolbox`** to find the task (`TaskMatcher` handles "network refactor" →
   "Refactor Network Layer") and performs a `WorkspaceCommand`.
5. The tool returns a **truthful** sentence to the model, e.g. *"Marked 'Refactor Network Layer' as high priority."*
   If nothing matched, it says so — the model is instructed never to claim success a tool didn't report.
6. The model replies (*"Done!"*), streamed word by word into the chat. The tool call also appears as an
   **action block**, and the changed tile pulses on the board.

### Key techniques to study

```swift
// A tool's arguments are a @Generable struct. Using enums (not strings) means the model
// can only choose valid values — no "unknown layout" bugs.
@Generable
enum PriorityArgument: String { case normal, high }

struct SetTaskPriorityTool: Tool {
    let name = "setTaskPriority"
    let description = "Sets a task's priority to high (prioritise) or normal (deprioritise)."

    @Generable
    struct Arguments {
        @Guide(description: "The task's title or words from it")
        var query: String
        var priority: PriorityArgument
    }

    func call(arguments: Arguments) async throws -> String {
        // Hop to the main actor, perform a WorkspaceCommand, return what really happened.
    }
}
```

| File | What it shows |
|---|---|
| [`Agent/Tools/WorkspaceTools.swift`](WorkspaceAssistant/Agent/Tools/WorkspaceTools.swift) | All nine tools as thin adapters |
| [`Agent/Toolbox/WorkspaceToolbox.swift`](WorkspaceAssistant/Agent/Toolbox/WorkspaceToolbox.swift) | The logic behind the tools, with honest results |
| [`Agent/FoundationModels/FoundationModelsEngine.swift`](WorkspaceAssistant/Agent/FoundationModels/FoundationModelsEngine.swift) | Session, streaming, cancelling, error handling |
| [`Agent/FoundationModels/AssistantInstructions.swift`](WorkspaceAssistant/Agent/FoundationModels/AssistantInstructions.swift) | The system prompt (short and specific works best) |
| [`Agent/Scripted/ScriptedEngine.swift`](WorkspaceAssistant/Agent/Scripted/ScriptedEngine.swift) | The simulated assistant, using the *same* toolbox |

Both engines follow the same `AssistantEngine` protocol (`Domain/Assistant/AssistantEngine.swift`), so the UI doesn't
care which one it's talking to. `AutomaticAssistantEngine` picks the real one when Apple Intelligence is available.

---

## 5. Project map

```
WorkspaceAssistant/
  App/                 Start here: @main app, creates everything and wires it together (AppDependencies)
  Domain/              Plain Swift — models (TaskItem), commands, the store, protocols. No UI code.
  Persistence/         Saving tasks with SwiftData; preferences with UserDefaults
  Agent/               The AI: Foundation Models engine, tools, simulated assistant
  DesignSystem/        Colours, spacing, and reusable views (TaskTile, ActionBlock, ComposerBar…)
  Features/
    Board/             The task board: 4 layouts, task editor, search, collections
    Assistant/         The chat: transcript, action blocks, composer, suggestions
    Settings/          Settings screen
  Resources/           App icon, colours, and all text (Localizable.xcstrings)
WorkspaceAssistantTests/     Unit tests (Swift Testing) — mirror the folders above
WorkspaceAssistantUITests/   UI tests, including automated accessibility audits
docs/                        Accessibility report and app icon files
scripts/                     Helper scripts (sync strings, render the icon)
```

**Layers depend inwards:** Features and Agent use Domain; Domain uses nothing app-specific. Only `Agent/` imports
FoundationModels and only `Persistence/` imports SwiftData. Keeping it this way makes each part easy to test and swap.

---

## 6. Build your own version, step by step

You don't need to build everything at once. Each step gives you a working app.

**Step 1 — A plain task list (SwiftUI basics)**
- Make a `struct TaskItem: Identifiable` with a `title` and `isDone`.
- Show an array of them in a `List`; add a text field and a button to add tasks.

**Step 2 — One source of truth (Observation)**
- Move the array into an `@Observable` class (your "store") and inject it with `.environment(...)`.
- Views read from the store; buttons call methods on it.

**Step 3 — Commands and undo**
- Create an `enum Command { case add(String), toggle(UUID), delete(UUID) }`.
- Give the store one `perform(_:)` method that switches over the command.
- Before applying a command, work out its *inverse* and register it with `UndoManager`
  (get it from `@Environment(\.undoManager)`). Now shake-to-undo just works.

**Step 4 — Save data (SwiftData)**
- Create a `@Model` class for storage and save after each command. Load on launch.
- Tip: keep your `TaskItem` struct for the UI and convert to/from the `@Model` — see `Persistence/TaskRecord.swift`.

**Step 5 — Make it look good**
- Build a reusable `TaskTile` view. Use only Dynamic Type text styles (`.headline`, `.caption`…).
- Use a `LazyVGrid` with `GridItem(.adaptive(minimum: 160))` for a Shortcuts-style grid.

**Step 6 — Add the AI**
- Check `SystemLanguageModel.default.availability` first and show a message if it's unavailable.
- Write one tool (e.g. `addTask`) with a `@Generable` `Arguments` struct. Inside `call`, perform your command.
- Create `LanguageModelSession(tools: [AddTaskTool(...)], instructions: "...")` **once** and reuse it.
- Call `session.respond(to:)` first; switch to `streamResponse(to:)` once it works.

**Step 7 — Make the AI trustworthy**
- Return what actually happened from each tool, including "no match" and "already done".
- Show each tool call in the chat so the user can see exactly what changed.

**Step 8 — Test it**
- Write Swift Testing tests for each command and its undo (see `WorkspaceAssistantTests/Domain/`).
- Test your tools by calling `tool.call(arguments:)` directly — no model needed.

---

## 7. Ideas to extend it (good exercises)

- **Due dates**: add `dueDate: Date?` to `TaskItem`, a new command, a date picker in the editor, and a tool argument.
- **An undo tool**: let the assistant undo its last change through the store's `UndoManager`.
- **App Intents**: expose "Add task" to Siri and the Shortcuts app by reusing `WorkspaceCommand`.
- **A widget** showing priority tasks.
- **More languages**: add a translation to `Resources/Localizable.xcstrings`.

---

## 8. Testing and quality

- **⌘U** runs everything: about 100 unit tests plus UI tests.
- UI tests launch the app with `-UITestScriptedAssistant` so they're repeatable (in-memory data, simulated assistant).
- `AccessibilityAuditTests` runs Xcode's built-in accessibility audit on each main screen.
- The code builds with **Swift 6 strict concurrency** and no warnings.

### Useful scripts
- `scripts/sync-strings.sh` — updates the String Catalog after a command-line build (Xcode does this automatically).
- `swift scripts/render-app-icon.swift <out.png> 1` — redraws the app icon (see `docs/app-icon/`).

### Command-line build (optional)
```bash
xcodebuild -project WorkspaceAssistant.xcodeproj -scheme WorkspaceAssistant -destination 'platform=iOS Simulator,name=iPhone 17' test
```

---

## 9. Requirements and notes

- Xcode 27+, Swift 6, iOS 26.0+ (Foundation Models needs iOS 26), iPhone only.
- No third-party libraries — everything uses Apple frameworks.
- The real assistant needs a device with Apple Intelligence turned on (Settings ▸ Apple Intelligence & Siri).
  Everything else works on any iOS 26 device or simulator.
