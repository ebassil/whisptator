## Context

Whisptator's menu bar menu currently offers Start Dictation, Start Meeting, Settings, and Quit. There is no "About" option to inform users about the app. The change adds an About dialog accessible from the menu bar.

## Goals / Non-Goals

**Goals:**
- Add an "About" menu item in the menu bar, separated by a divider
- Show a dialog with: app name ("Whisptator"), description, developer ("Émile Bassil"), and a clickable link to https://github.com/ebassil/whisptator
- The GitHub link opens in the default browser via NSWorkspace.shared.open
- Version number display (default to "Beta" if not available)
- Credits and aknowledgements for using open source software and AI models such as Whisper

**Non-Goals:**
- Custom styling or theming — use standard macOS dialog appearance

## Decisions

- **Approach: `.sheet` modifier on MenuBarView** — A SwiftUI sheet is the simplest way to present a modal dialog from a menu bar menu. Alternative considered: a separate NSWindowController popover, which adds unnecessary complexity.
- **New `AboutView` struct** — Keeps the dialog code separate from MenuBarView, following the existing code pattern.
- **`NSWorkspace.shared.open` for the link** — Standard macOS API for opening URLs in the default browser. No need for external dependencies.
- **Store `AboutView` in `Sources/Whisptator/`** — Same module as MenuBarView, shared across the existing target.

## Risks / Trade-offs

- **Sheet dismissal on menu collapse**: If the menu bar menu collapses while the sheet is open, the sheet will dismiss automatically. Acceptable — users can re-open from the menu.
