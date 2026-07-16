## Why

Whisptator is a menu bar app with no way for users to learn about the application — its purpose, who built it, or where to find more information. Adding an "About" dialog provides a simple, standard way to display this information and link to the GitHub repository.

## What Changes

- Add a new "About" menu item in the menu bar menu beneath the existing items, separated by a divider
- Show a dialog/popover with: app name, description, developer credit, and a clickable GitHub link
- The GitHub link opens the default browser when clicked

## Capabilities

### New Capabilities

- `about-dialog`: About dialog shown from the menu bar with app information and a clickable link to the GitHub repository

### Modified Capabilities

- `menu-bar-app`: Add a new "About" menu item in the menu bar menu that opens the about dialog

## Impact

- No new dependencies required
- Uses existing SwiftUI and AppKit APIs (NSWorkspace.shared.open for browser link)
- Changes are scoped to `Sources/Whisptator/MenuBarView.swift` and a new view file for the about dialog
