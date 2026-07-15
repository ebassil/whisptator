## Why

The Logs tab in Settings provides real-time visibility into app internals but lacks controls to manage what gets logged, when logging runs, or how to export the data. Users need the ability to pause/resume logging, selectively enable/disable log categories, and export logs for debugging or sharing. The Settings dialog is also non-resizable, which makes viewing long log entries or using the app on smaller/larger screens cumbersome.

## What Changes

- Add a **Start / Stop** button in the Logs tab to pause/resume log collection
- Make the **Settings dialog resizable** via window resize handles
- Add a **Config Logs** icon button that opens a sheet with checkboxes per `LogCategory` (enable/disable)
- Add **Enable All / Disable All** controls in the config sheet
- Respect disabled categories: `AppLogger.log()` drops entries for disabled categories
- Persist `isLoggingPaused` and `enabledCategories` to `UserDefaults` (via `AppSettings`)
- Add a **Save to CSV** button that exports current log entries to a `.csv` file

## Capabilities

### New Capabilities
- `log-controls`: Pause/resume log collection, per-category enable/disable, enable-all/disable-all, with persisted state
- `log-export-csv`: Export current in-memory log entries to a CSV file via a Save panel

### Modified Capabilities
- `settings-ui`: REQUIREMENTS changed for the Logs tab to add stop/start, config, and save buttons; setting window must be resizable

## Impact

- `Sources/WhisptatorCore/Settings/AppLogger.swift`: Add `isPaused`, `isCategoryEnabled()` logic; guard `log()` on pause/disabled state
- `Sources/WhisptatorCore/Settings/AppSettings.swift`: Add `logEnabledCategories: Set<LogCategory>` and `isLoggingPaused: Bool` persisted settings
- `Sources/Whisptator/SettingsView.swift`: Redesign `LogsSettingsTab` with start/stop, config button, save-to-CSV button; remove fixed frame on `TabView`
- New `LogConfigSheet.swift` (optional standalone view or inline in SettingsView): Sheet with per-category toggles + enable-all/disable-all
