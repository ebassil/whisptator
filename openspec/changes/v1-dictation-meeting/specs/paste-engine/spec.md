## ADDED Requirements

### Requirement: Clipboard paste mode
The system SHALL support pasting transcribed text into the frontmost application using the clipboard (Cmd+V) mechanism. This SHALL be the default paste mode.

#### Scenario: Clipboard paste execution
- **WHEN** transcription completes and paste mode is "Clipboard"
- **THEN** the system saves the current pasteboard, sets the pasteboard to the transcribed text, simulates Cmd+V, waits 100ms, and restores the original pasteboard

#### Scenario: Pasteboard preserved
- **WHEN** clipboard paste is executed
- **THEN** the user's original clipboard contents are restored after the paste

### Requirement: Typing paste mode
The system SHALL support pasting transcribed text by simulating keyboard input character-by-character using CGEvent.

#### Scenario: Character-by-character typing
- **WHEN** transcription completes and paste mode is "Typing"
- **THEN** the system simulates keyboard events for each character in the transcribed text, appearing as if typed by the user

#### Scenario: Special character handling
- **WHEN** the transcribed text contains characters that require modifier keys (e.g., uppercase letters, punctuation)
- **THEN** the system correctly generates the appropriate CGEvent with the required modifier flags

### Requirement: Paste mode configuration
The system SHALL allow the user to select between Clipboard and Typing paste modes in Settings. The setting SHALL be persisted and applied immediately.

#### Scenario: Change paste mode
- **WHEN** the user changes the paste mode in Settings
- **THEN** the new mode is used for all subsequent dictation sessions

### Requirement: Paste into frontmost app
The system SHALL paste transcribed text into whichever application has focus at the time the paste is triggered.

#### Scenario: Paste targets focused app
- **WHEN** the user completes a dictation while a text editor is focused
- **THEN** the transcribed text appears in the text editor's input field

#### Scenario: Paste works across different app types
- **WHEN** the user completes a dictation while a browser, terminal, or messaging app is focused
- **THEN** the transcribed text is inserted at the cursor position in that application
