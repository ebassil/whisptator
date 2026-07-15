## MODIFIED Requirements

### Requirement: Global keyboard shortcut monitoring
The system SHALL monitor keyboard events system-wide using a CGEvent tap to detect configured shortcuts, regardless of which application has focus. The CGEvent tap SHALL properly invoke the associated actions when shortcuts are detected.

#### Scenario: Event tap active
- **WHEN** the application is running and Accessibility permission is granted
- **THEN** a CGEvent tap is active on a dedicated thread with its own RunLoop

#### Scenario: Event tap re-enabled periodically
- **WHEN** 5 seconds have passed since the last tap re-enable
- **THEN** the CGEvent tap is re-enabled to prevent macOS from disabling it

#### Scenario: Shortcut triggers action
- **WHEN** the user presses a configured keyboard shortcut
- **THEN** the associated action (start recording, toggle meeting, etc.) is executed

#### Scenario: Shortcut works from any application
- **WHEN** the user presses a configured shortcut while any application is in focus
- **THEN** the shortcut is detected and the action is triggered regardless of the active application

### Requirement: Push-to-talk shortcut
The system SHALL support a configurable push-to-talk shortcut where holding the key starts recording and releasing it stops recording and triggers transcription. The shortcut SHALL properly trigger the recording action when pressed.

#### Scenario: Key down starts recording
- **WHEN** the user presses the configured push-to-talk key
- **THEN** audio recording begins and the floating HUD is displayed

#### Scenario: Key up stops and transcribes
- **WHEN** the user releases the push-to-talk key while recording
- **THEN** recording stops, audio is transcribed, text is cleaned, and the result is pasted

#### Scenario: Push-to-talk action fires reliably
- **WHEN** the user holds the push-to-talk shortcut
- **THEN** the recording action is triggered immediately and consistently

### Requirement: Hands-free shortcut
The system SHALL support a configurable hands-free shortcut where tapping the key toggles recording on and off. The shortcut SHALL properly toggle the recording state when tapped.

#### Scenario: First tap starts recording
- **WHEN** the user taps the hands-free shortcut while not recording
- **THEN** audio recording begins and the floating HUD is displayed

#### Scenario: Second tap stops and transcribes
- **WHEN** the user taps the hands-free shortcut while recording is active
- **THEN** recording stops, audio is transcribed, text is cleaned, and the result is pasted

#### Scenario: Hands-free toggle fires reliably
- **WHEN** the user taps the hands-free shortcut
- **THEN** the recording state toggles immediately and consistently