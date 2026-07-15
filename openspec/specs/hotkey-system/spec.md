# Hotkey System

## Purpose

TBD

## Requirements

### Requirement: Global keyboard shortcut monitoring
The system SHALL monitor keyboard events system-wide using a CGEvent tap to detect configured shortcuts, regardless of which application has focus.

#### Scenario: Event tap active
- **WHEN** the application is running and Accessibility permission is granted
- **THEN** a CGEvent tap is active on a dedicated thread with its own RunLoop

#### Scenario: Event tap re-enabled periodically
- **WHEN** 5 seconds have passed since the last tap re-enable
- **THEN** the CGEvent tap is re-enabled to prevent macOS from disabling it

### Requirement: Push-to-talk shortcut
The system SHALL support a configurable push-to-talk shortcut where holding the key starts recording and releasing it stops recording and triggers transcription.

#### Scenario: Key down starts recording
- **WHEN** the user presses the configured push-to-talk key
- **THEN** audio recording begins and the floating HUD is displayed

#### Scenario: Key up stops and transcribes
- **WHEN** the user releases the push-to-talk key while recording
- **THEN** recording stops, audio is transcribed, text is cleaned, and the result is pasted

### Requirement: Hands-free shortcut
The system SHALL support a configurable hands-free shortcut where tapping the key toggles recording on and off.

#### Scenario: First tap starts recording
- **WHEN** the user taps the hands-free shortcut while not recording
- **THEN** audio recording begins and the floating HUD is displayed

#### Scenario: Second tap stops and transcribes
- **WHEN** the user taps the hands-free shortcut while recording is active
- **THEN** recording stops, audio is transcribed, text is cleaned, and the result is pasted

### Requirement: Shortcut recording UI
The system SHALL provide a shortcut recorder control in Settings that captures a key combination when the user clicks a button and presses the desired keys.

#### Scenario: Record shortcut
- **WHEN** the user clicks the shortcut recorder button and presses a key combination
- **THEN** the recorded combination is displayed in the button and saved to Settings

#### Scenario: Modifier-only chords
- **WHEN** the user clicks the recorder button and presses one or more modifier keys without a regular key
- **THEN** the shortcut is accepted, displayed with side-specific symbols (e.g., `R-⌘+R-⌃`), and saved

#### Scenario: Modifier-only recording — all modifiers released captures combo
- **WHEN** the user presses modifier keys during recording and releases all of them
- **THEN** the combination is captured as a modifier-only shortcut and recording ends

#### Scenario: Modifier-only recording — regular key press takes priority
- **WHEN** the user presses a regular key during recording while modifiers are held
- **THEN** the shortcut is recorded as a regular key+modifiers shortcut, not modifier-only

#### Scenario: Modifier-only recording — cancel by clicking button
- **WHEN** the user clicks the recorder button again without pressing any keys
- **THEN** recording is cancelled without changing the shortcut

#### Scenario: Clear shortcut
- **WHEN** the user clicks a clear/reset button next to a shortcut
- **THEN** the shortcut is removed and no key combination triggers that action

### Requirement: Data model — ShortcutKeyCode
The system SHALL use a `ShortcutKeyCode` struct with three fields to represent both regular and modifier-only shortcuts.

| Field | Type | Regular shortcut | Modifier-only shortcut |
|-------|------|-----------------|----------------------|
| `keyCode` | `UInt32` | The key code of the main key (e.g., 96 for F5) | 0 (unused) |
| `modifierFlags` | `UInt32` | Device-independent modifier flags (Cmd/Opt/Ctrl/Shift) | 0 (unused) |
| `modifierKeyCodes` | `[UInt32]` | Empty `[]` | Physical key codes of held modifiers (e.g., `[0x36, 0x3E]` for Right-Command+Right-Control) |

The `isModifierOnly` computed property is `true` when `modifierKeyCodes` is non-empty. The `isEmpty` property returns `true` only when all three fields are zero/empty and `isModifierOnly` is false.

#### Backward compatibility
The `modifierKeyCodes` field uses `decodeIfPresent` so old persisted data (without the field) defaults to `[]` and continues to work as regular shortcuts. On encode, empty `modifierKeyCodes` is omitted to keep the stored representation compact.

#### Scenario: Old shortcut deserialization
- **WHEN** persisted data without `modifierKeyCodes` is decoded
- **THEN** the field defaults to `[]` and the shortcut behaves as a regular shortcut

#### Scenario: New shortcut serialization
- **WHEN** a modifier-only shortcut is encoded
- **THEN** `modifierKeyCodes` is included in the JSON
- **WHEN** a regular shortcut is encoded
- **THEN** `modifierKeyCodes` is omitted from the JSON

### Requirement: Modifier-only shortcut detection (flagsChanged handling)
The system SHALL detect modifier-only shortcuts by tracking `.flagsChanged` events in the CGEvent tap and comparing the set of currently-held modifier key codes against stored shortcut definitions.

#### Tracked modifier key codes
The CGEvent tap tracks these key codes for left/right modifier keys:

| Key | Key Code (hex) | Key Code (dec) |
|-----|----------------|-----------------|
| Right Command | 0x36 | 54 |
| Left Command | 0x37 | 55 |
| Left Shift | 0x38 | 56 |
| Left Option | 0x3A | 58 |
| Left Control | 0x3B | 59 |
| Right Shift | 0x3C | 60 |
| Right Option | 0x3D | 61 |
| Right Control | 0x3E | 62 |

#### Matching rules
- Matching uses **exact set equality**: the set of currently-pressed modifier key codes must equal the shortcut's `modifierKeyCodes` exactly. Additional modifiers not in the shortcut cause a non-match.
- `.flagsChanged` events are never swallowed — they always pass through to the active application.

#### Scenario: Push-to-talk held/released
- **WHEN** the user holds exactly the modifier combination matching the push-to-talk shortcut
- **THEN** `didDetectPushToTalkDown` fires and a `pushToTalkModifierHeld` flag is set
- **WHEN** the user releases any modifier so the set no longer matches
- **THEN** `didDetectPushToTalkUp` fires and the flag is cleared

#### Scenario: Hands-free toggle on combo press
- **WHEN** the user presses a modifier combination matching the hands-free shortcut (transitioning from not-held to held)
- **THEN** `didDetectHandsFreeTap` fires once, toggling the recording state

#### Scenario: Meeting toggle on combo press
- **WHEN** the user presses a modifier combination matching the meeting shortcut
- **THEN** `didDetectMeetingToggle` fires once

### Requirement: Display formatting for modifier-only shortcuts
The system SHALL display modifier-only shortcuts using human-readable symbols that distinguish right-side from left-side modifiers.

#### Display mapping
| Modifier Key | Display |
|-------------|---------|
| Right Command | `R-⌘` |
| Left Command | `⌘` |
| Right Shift | `R-⇧` |
| Left Shift | `⇧` |
| Right Control | `R-⌃` |
| Left Control | `⌃` |
| Right Option | `R-⌥` |
| Left Option | `⌥` |

#### Scenario: Display modifier-only combo
- **WHEN** a recorder button shows a modifier-only shortcut with key codes `[0x36, 0x3E]`
- **THEN** the button displays `R-⌘+R-⌃`

### Requirement: Shortcut persistence
The system SHALL persist all configured shortcuts in UserDefaults and restore them on application launch.

#### Scenario: Shortcuts restored on launch
- **WHEN** the application launches
- **THEN** previously configured shortcuts are loaded from UserDefaults and the CGEvent tap is configured to match them
