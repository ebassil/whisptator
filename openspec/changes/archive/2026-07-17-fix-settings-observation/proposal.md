## Why

Every computed property in `AppSettings` that reads/writes UserDefaults directly bypasses the `@Observable` macro's observation tracking. When SwiftUI controls (Pickers, Toggles, Steppers, Sliders) bind to these properties via `$settings`, setting a value never triggers a re-render, so the UI appears to ignore the user's change.

The language picker in Dictation settings was the first reported symptom: selecting French or Spanish reverts instantly to "Auto-detect". The same bug affects 27 other properties: shortcuts, paste mode, cleanup rules, meeting settings, overlay controls, audio save paths, model selection, logging config, and more.

## What Changes

- Convert all computed UserDefaults-backed properties in `AppSettings` to stored properties with `didSet` that persist to UserDefaults, matching the pattern already used by `audioFormat` and `mp3Bitrate`.
- Initialize stored properties from UserDefaults in `AppSettings.init()`.
- This is purely a storage pattern change — no UI, API, or behavioral changes.

## Capabilities

### New Capabilities
- `settings-observation`: Observation-compliant property storage for all AppSettings values

### Modified Capabilities
- (none — requirements unchanged, only implementation fix)

## Impact

- `Sources/WhisptatorCore/Settings/AppSettings.swift` — rewrite all computed properties to stored + didSet
- Callers of `settings.*` continue to work identically (get/set via the same property name)
- Every SwiftUI binding in Settings tabs will now correctly reflect user changes
