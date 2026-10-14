# App icon

Flat, minimal mark: three white rounded tiles and a four-point sparkle (tasks + assistant) on indigo.

| File | Use |
|---|---|
| `WorkspaceAssistant/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | Complete icon, opaque 1024×1024 (used by the app). |
| `AppIcon-Foreground.png` | White artwork on transparency — drop into **Icon Composer** as the foreground layer. |

In Icon Composer, set the background fill to **#4B3FD1** (indigo, the app's default accent). For dark and tinted
appearances, leave the foreground white and let the system handle tinting.

Shapes are custom paths (no SF Symbols, which Apple's licence doesn't allow in app icons).
Regenerate with `swift scripts/render-app-icon.swift WorkspaceAssistant/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png 1`
(use `0` for the transparent foreground).
