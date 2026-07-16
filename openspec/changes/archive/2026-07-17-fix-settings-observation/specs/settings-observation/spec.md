## ADDED Requirements

### Requirement: Language setting persists selection
The Dictation settings language picker SHALL persist the user's selection and visually reflect the chosen value after selection.

#### Scenario: Language selection persists
- **WHEN** user selects a language from the Dictation settings Language picker
- **THEN** the picker SHALL show the selected language as the current value
- **THEN** the selected language SHALL be persisted in UserDefaults
- **THEN** after app restart, the picker SHALL show the previously selected language

#### Scenario: Auto-detect default
- **WHEN** user has never selected a language
- **THEN** the picker SHALL show "Auto-detect" as the default value
- **THEN** `settings.language` SHALL be `"auto"`

#### Scenario: Language value reaches transcription
- **WHEN** dictation is performed with a specific language selected
- **THEN** `DictationOrchestrator.performTranscription()` SHALL pass the selected language code to the transcription engine
- **THEN** the transcription engine SHALL use the selected language for ASR

### Requirement: Paste mode setting persists selection
The paste mode radio group in Dictation settings SHALL persist and visually reflect the user's selection.

#### Scenario: Paste mode selection persists
- **WHEN** user selects a paste mode (Clipboard/Typing) from the Dictation settings
- **THEN** the radio group SHALL show the selected mode as checked
- **THEN** the selected mode SHALL be persisted in UserDefaults

### Requirement: Shortcut settings persist
All shortcut recorder bindings SHALL persist their values and visually reflect the recorded shortcut after assignment.

#### Scenario: Push-to-talk shortcut persists
- **WHEN** user records a push-to-talk shortcut
- **THEN** the shortcut recorder SHALL display the recorded keys
- **THEN** the shortcut SHALL be persisted in UserDefaults
- **THEN** the shortcut SHALL be active for dictation

#### Scenario: Hands-free shortcut persists
- **WHEN** user records a hands-free shortcut
- **THEN** the shortcut recorder SHALL display the recorded keys
- **THEN** the shortcut SHALL be persisted in UserDefaults

#### Scenario: Meeting shortcut persists
- **WHEN** user records a meeting recording shortcut
- **THEN** the shortcut recorder SHALL display the recorded keys
- **THEN** the shortcut SHALL be persisted in UserDefaults

### Requirement: Cleanup settings persist
All cleanup settings in the Cleanup tab SHALL persist user changes and visually reflect the current state.

#### Scenario: Cleanup mode selection persists
- **WHEN** user switches cleanup mode between Raw and Clean
- **THEN** the radio group SHALL show the selected mode as checked
- **THEN** the selected mode SHALL be persisted in UserDefaults

#### Scenario: Filler word toggles persist
- **WHEN** user toggles a filler word on or off
- **THEN** the toggle SHALL show the correct state
- **THEN** the filler word state SHALL be persisted in UserDefaults

#### Scenario: Word replacements persist
- **WHEN** user modifies word replacement rules
- **THEN** the list SHALL display the current rules
- **THEN** the rules SHALL be persisted in UserDefaults

#### Scenario: Snippets persist
- **WHEN** user modifies snippet expansions
- **THEN** the list SHALL display the current snippets
- **THEN** the snippets SHALL be persisted in UserDefaults

### Requirement: Meeting settings persist
All meeting recording settings SHALL persist user changes and visually reflect the current state.

#### Scenario: Meeting audio source persists
- **WHEN** user changes the meeting audio source
- **THEN** the radio group SHALL show the selected source as checked
- **THEN** the selection SHALL be persisted in UserDefaults

#### Scenario: Meeting retention setting persists
- **WHEN** user changes the audio retention mode
- **THEN** the picker SHALL show the selected mode
- **THEN** the retention mode SHALL be persisted in UserDefaults

#### Scenario: Meeting retention days persists
- **WHEN** user adjusts the auto-delete days stepper
- **THEN** the stepper SHALL display the current value
- **THEN** the value SHALL be persisted in UserDefaults

#### Scenario: Meeting save location persists
- **WHEN** user changes the meeting save directory
- **THEN** the path SHALL display the selected location
- **THEN** the location SHALL be persisted in UserDefaults

### Requirement: General settings persist
General settings toggles SHALL persist user changes and visually reflect the current state.

#### Scenario: Launch at login persists
- **WHEN** user toggles "Launch at login"
- **THEN** the toggle SHALL show the correct state
- **THEN** the state SHALL be persisted in UserDefaults

#### Scenario: Show in Dock persists
- **WHEN** user toggles "Show in Dock"
- **THEN** the toggle SHALL show the correct state
- **THEN** the state SHALL be persisted in UserDefaults

### Requirement: Overlay settings persist
All overlay settings SHALL persist user changes and visually reflect the current state.

#### Scenario: Overlay enable toggle persists
- **WHEN** user toggles overlay on or off
- **THEN** the toggle SHALL show the correct state
- **THEN** the state SHALL be persisted in UserDefaults

#### Scenario: Overlay position persists
- **WHEN** user changes the overlay position
- **THEN** the picker SHALL show the selected position
- **THEN** the position SHALL be persisted in UserDefaults

#### Scenario: Overlay opacity persists
- **WHEN** user adjusts the overlay opacity slider
- **THEN** the slider SHALL show the current opacity value
- **THEN** the opacity SHALL be persisted in UserDefaults

#### Scenario: Overlay size persists
- **WHEN** user adjusts the overlay size slider
- **THEN** the slider SHALL show the current size value
- **THEN** the size SHALL be persisted in UserDefaults

#### Scenario: Dual-screen mode persists
- **WHEN** user changes the multi-display behavior
- **THEN** the picker SHALL show the selected mode
- **THEN** the mode SHALL be persisted in UserDefaults

### Requirement: Audio save settings persist
Audio save settings SHALL persist user changes and visually reflect the current state.

#### Scenario: Save audio toggle persists
- **WHEN** user toggles "Save audio files"
- **THEN** the toggle SHALL show the correct state
- **THEN** the state SHALL be persisted in UserDefaults

#### Scenario: Audio save location persists
- **WHEN** user changes the audio save directory
- **THEN** the path SHALL display the selected location
- **THEN** the location SHALL be persisted in UserDefaults

### Requirement: Model selection persists
The selected ASR model SHALL persist across app restarts.

#### Scenario: Model selection persists
- **WHEN** user selects an ASR model in the Model tab
- **THEN** the selected model SHALL be highlighted
- **THEN** the selection SHALL be persisted in UserDefaults
- **THEN** after app restart, the same model SHALL remain selected

### Requirement: Logging settings persist
Logging controls SHALL persist user changes and visually reflect the current state.

#### Scenario: Log pause toggle persists
- **WHEN** user pauses or resumes logging
- **THEN** the button SHALL show the correct state
- **THEN** the pause state SHALL be persisted in UserDefaults

#### Scenario: Log category configuration persists
- **WHEN** user enables or disables log categories
- **THEN** the toggles SHALL show the correct states
- **THEN** the enabled categories SHALL be persisted in UserDefaults
