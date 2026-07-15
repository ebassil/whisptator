## 1. AppSettings persistence

- [x] 1.1 Add `isLoggingPaused: Bool` property to AppSettings with UserDefaults key `logPaused` defaulting to `false`
- [x] 1.2 Add `logEnabledCategories: [String]` property to AppSettings with UserDefaults key `logEnabledCategories` using Codable JSON encoding, defaulting to all categories enabled

## 2. AppLogger core changes

- [x] 2.1 Add `isPaused: Bool` property to AppLogger, initialized from AppSettings
- [x] 2.2 Add `enabledCategories: Set<LogCategory>` property to AppLogger, initialized from AppSettings
- [x] 2.3 Guard `log(category:message:)` to return early if `isPaused` is true or `category` is not in `enabledCategories`
- [x] 2.4 Add `setPaused(_:)` method that updates both AppLogger and AppSettings
- [x] 2.5 Add `setCategoryEnabled(_:enabled:)` method that updates both AppLogger and AppSettings
- [x] 2.6 Add `enableAllCategories()` and `disableAllCategories()` convenience methods

## 3. Logs settings tab UI — Start/Stop button

- [x] 3.1 Add Start/Stop button to LogsSettingsTab bottom toolbar, toggling `AppLogger.shared.isPaused`
- [x] 3.2 Update button label and icon based on pause state (play.fill for Start, pause.fill for Stop)

## 4. Logs settings tab UI — Config sheet

- [x] 4.1 Add Config Logs icon button (gear/ellipsis icon) to LogsSettingsTab bottom toolbar
- [x] 4.2 Create LogConfigSheet view with a list of all LogCategory cases with toggle switches
- [x] 4.3 Add Enable All / Disable All buttons in the config sheet header or footer
- [x] 4.4 Wire config sheet as a `.sheet` modifier on LogsSettingsTab

## 5. Logs settings tab UI — Save to CSV

- [x] 5.1 Add Save button to LogsSettingsTab bottom toolbar
- [x] 5.2 Implement CSV export: present NSSavePanel, write header + rows (timestamp ISO 8601, category, message), quote fields containing commas/newlines

## 6. Settings window resizable

- [x] 6.1 Remove fixed `.frame(width:height:)` on SettingsView TabView
- [x] 6.2 Add `.frame(minWidth:minHeight:)` to set reasonable minimum size (e.g., 480x380)
- [x] 6.3 Ensure all tab content uses flexible layouts that adapt to window resize
