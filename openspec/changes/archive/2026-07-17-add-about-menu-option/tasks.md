## 1. AboutView

- [x] 1.1 Create `AboutView.swift` with app name, description, developer credit, and clickable GitHub link
- [x] 1.2 Use `NSWorkspace.shared.open` to open the GitHub URL in the default browser when the link is tapped

## 2. Menu bar integration

- [x] 2.1 Create `AboutMenuView.swift` with `@State private var showAbout` and `Button("About")` presenting `AboutView` via `.sheet`
- [x] 2.2 Add `AboutMenuView()` to `MenuBarExtra` in `WhisptatorApp.swift` under `MenuBarView`
- [x] 2.3 Remove About-related code from `MenuBarView.swift` (revert to original)
