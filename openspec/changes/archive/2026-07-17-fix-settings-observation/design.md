## Context

`AppSettings` is annotated with `@Observable` but 27 of its 29 properties are computed get/set wrappers around `UserDefaults.standard`. The `@Observable` macro only generates observation tracking for stored properties — computed properties are invisible to it. When SwiftUI controls (Pickers, Toggles, Steppers, Sliders) bind to `$settings.<property>`, the setter writes to UserDefaults but never triggers a re-render, so the UI appears to ignore the change.

Two properties already use the correct pattern:
- `audioFormat` (line 324): stored property with `didSet` syncing to UserDefaults
- `mp3Bitrate` (line 331): stored property with `didSet` syncing to UserDefaults

## Goals / Non-Goals

**Goals:**
- Every `AppSettings` property bound in the SwiftUI settings UI correctly persists and visually reflects user changes
- All properties follow the stored-property-with-didSet pattern already established by `audioFormat`/`mp3Bitrate`

**Non-Goals:**
- No UI layout or behavior changes
- No public API changes — property names and types remain identical
- Spec changes for `settings-ui` and other existing specs are out of scope (requirements unchanged)

## Decisions

**Decision**: Convert all computed UserDefaults-backed properties to stored properties with `didSet`.

**Pattern** (matches `audioFormat` / `mp3Bitrate`):
```swift
// Init: load from UserDefaults
public init() {
    if let raw = UserDefaults.standard.string(forKey: Key.language) {
        language = raw
    }
    // ... existing init ...
}

// Property: stored with didSet to sync back
public var language: String = "auto" {
    didSet {
        UserDefaults.standard.set(language, forKey: Key.language)
        onSettingChange?("language")
    }
}
```

**Rationale:**
- Stored properties are automatically tracked by `@Observable` — mutations trigger SwiftUI re-render
- `didSet` provides a single sync point to UserDefaults consistent with existing conventions
- Property names and types remain identical — zero impact on callers

**Alternatives considered:**
- `@ObservationTracked` on computed properties — not supported by the macro (stored properties only)
- `withObservationTracking` — fragile, ad-hoc, inconsistent with project patterns
- Keeping computed properties and adding a separate observable wrapper — over-engineered

## Risks / Trade-offs

- [Low] The three shortcut properties (`pushToTalkShortcut`, `handsFreeShortcut`, `meetingShortcut`) use JSON encode/decode helpers. These will follow the same stored + didSet pattern; JSON encoding moves to the didSet handler.
- [Low] Properties with computed defaults (e.g., `overlayOpacity` returns 0.85 when UserDefaults is 0) need care in the getter to distinguish "never set" from "set to 0". The stored initial value in the declaration handles this.
