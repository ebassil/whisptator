## Context

The Settings window (`SettingsView.swift`) uses a fixed `TabView` with 7 tabs at `500x400`. The Logs tab (`LogsSettingsTab`) displays an in-memory ring buffer of `LogEntry` objects from `AppLogger.shared`. Currently all 9 `LogCategory` values are always recorded; there is no pause, filtering, category toggling, or export capability.

`AppLogger` is a singleton `@Observable` class backed by `NSLock` and an array of up to 1000 entries. It is called from ~8 subsystems. `AppSettings` already persists to `UserDefaults` for all other settings.

## Goals / Non-Goals

**Goals:**
- Add a Start/Stop button that pauses/resumes log entry collection (state persisted)
- Make the Settings window resizable by the user
- Add a Config Logs button that opens a sheet with per-category enable/disable toggles
- Provide Enable All / Disable All in the config sheet
- When a category is disabled, `AppLogger.log()` silently drops the entry
- Persist `isPaused` and enabled-categories set to `UserDefaults`
- Add a Save to CSV button that opens an `NSSavePanel` and writes log entries

**Non-Goals:**
- File-based logging or `os_log` integration
- Log level filtering (info/warn/error) — only category-level on/off
- Search or filter within the log list
- Truncation or formatting of CSV output

## Decisions

1. **Start/Stop = pause flag on AppLogger** rather than removing/add subscribers. A simple `isPaused: Bool` property on `AppLogger`; `log()` returns early when paused. Persisted via `AppSettings.isLoggingPaused`.

2. **Category enable/disable = Set<LogCategory> on AppLogger** rather than individual booleans. `AppLogger` holds a `Set<LogCategory>` of enabled categories; `log()` returns early if the entry's category is not in the set. Default: all categories enabled. Persisted via `AppSettings.logEnabledCategories` as `Data` (Codable).

3. **Config sheet as a `.sheet` modifier on LogsSettingsTab** rather than a separate window. Simpler UX, consistent with macOS sheet patterns.

4. **Settings resizable via `.frame(minWidth:minHeight:)` + `.windowResizability(.contentSize)`** rather than removing the frame entirely. Keep the preferred initial size but allow resizing.

5. **CSV export via `NSSavePanel` + synchronous write** rather than a dedicated export manager. The log buffer is small (max 1000 entries) so the write is near-instant. Columns: timestamp, category, message.

6. **Persist settings in `AppSettings`** (existing `@Observable` + `UserDefaults` pattern) rather than a separate plist or file. Follows the existing convention for all other settings.

7. **Observability via `@MainActor`** on `AppLogger` methods rather than `Sendable` concurrency. The logger is already `@unchecked Sendable`; entry writes happen from various contexts. The existing `NSLock` guard is sufficient; the new checks are read-only on the enabled set which is mutated only on the main actor.

## Risks / Trade-offs

- **[Thread safety]** `Set<LogCategory>` and `isPaused` are read on every `log()` call across threads. **Mitigation**: Use `os_unfair_lock` or extend the existing `NSLock` scope to cover these reads.
- **[Backward compatibility]** Old `UserDefaults` without `logEnabledCategories` or `isLoggingPaused` keys. **Mitigation**: `AppSettings` defaults enable all categories and unpaused — safe for existing users.
- **[CSV encoding]** Messages may contain commas or newlines. **Mitigation**: Wrap message field in quotes when saving to CSV.
