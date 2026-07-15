## ADDED Requirements

### Requirement: General settings tab
The system SHALL provide a General settings tab with options for launch at login and dock visibility.

#### Scenario: Launch at login toggle
- **WHEN** the user toggles "Launch at login" in General settings
- **THEN** the app is added to or removed from macOS login items via SMAppService

#### Scenario: Show in Dock toggle
- **WHEN** the user toggles "Show in Dock" in General settings
- **THEN** the app's Dock visibility is updated (requires restart for some changes)

### Requirement: Dictation settings tab
The system SHALL provide a Dictation settings tab with shortcut configuration, paste mode, audio device, and language settings.

#### Scenario: Push-to-talk shortcut display
- **WHEN** the user opens Dictation settings
- **THEN** the current push-to-talk shortcut is displayed with a recorder button to change it
- **AND** modifier-only shortcuts use side-specific symbols (e.g., `R-⌘+R-⌃`)

#### Scenario: Hands-free shortcut display
- **WHEN** the user opens Dictation settings
- **THEN** the current hands-free shortcut is displayed with a recorder button to change it
- **AND** modifier-only shortcuts use side-specific symbols (e.g., `R-⌘+R-⌃`)

#### Scenario: Record modifier-only shortcut
- **WHEN** the user clicks a shortcut recorder button and presses one or more modifier keys
- **AND** releases all of them without pressing a regular key
- **THEN** the modifier-only combination is captured and saved with the modifiers' physical key codes
- **AND** recording ends automatically

#### Scenario: Paste mode selection
- **WHEN** the user opens Dictation settings
- **THEN** radio buttons for "Clipboard (Cmd+V)" and "Typing" are displayed with the current selection

#### Scenario: Audio device dropdown
- **WHEN** the user opens Dictation settings
- **THEN** a dropdown lists all available audio input devices with the current selection

#### Scenario: Language selection
- **WHEN** the user opens Dictation settings
- **THEN** a dropdown shows "Auto-detect" and common language options

### Requirement: Model settings tab
The system SHALL provide a Model settings tab showing the available Whisper models with download status and selection.

#### Scenario: Model list display
- **WHEN** the user opens Model settings
- **THEN** a list shows available models with name, size, download status, and a download/select button

#### Scenario: Model download trigger
- **WHEN** the user clicks "Download" next to a model
- **THEN** the model is downloaded from HuggingFace to the model cache directory

#### Scenario: Download progress display
- **WHEN** a model is downloading
- **THEN** a progress indicator shows bytes downloaded and estimated time remaining

### Requirement: Cleanup settings tab
The system SHALL provide a Cleanup settings tab with toggleable pipeline steps and configurable rules.

#### Scenario: Pipeline mode selection
- **WHEN** the user opens Cleanup settings
- **THEN** radio buttons for "Raw" and "Clean" modes are displayed

#### Scenario: Filler word configuration
- **WHEN** the user opens Cleanup settings with Clean mode selected
- **THEN** a list of filler words with toggle switches and an "Add custom" button is displayed

#### Scenario: Word replacement table
- **WHEN** the user opens Cleanup settings
- **THEN** a table of word replacement rules (trigger → replacement) with add/edit/delete controls is displayed

#### Scenario: Snippet table
- **WHEN** the user opens Cleanup settings
- **THEN** a table of snippet rules (trigger → expansion) with add/edit/delete controls is displayed

### Requirement: Meeting settings tab
The system SHALL provide a Meeting settings tab with audio source, retention, shortcut, and save location configuration.

#### Scenario: Audio source selection
- **WHEN** the user opens Meeting settings
- **THEN** radio buttons for "System + Microphone", "Microphone only", and "System only" are displayed

#### Scenario: Audio retention selection
- **WHEN** the user opens Meeting settings
- **THEN** radio buttons for "Keep audio", "Delete after transcription", and "Auto-delete after N days" are displayed

#### Scenario: Meeting shortcut configuration
- **WHEN** the user opens Meeting settings
- **THEN** a shortcut recorder for the meeting start/stop shortcut is displayed

#### Scenario: Save location display
- **WHEN** the user opens Meeting settings
- **THEN** the save location path is displayed with a button to change it
