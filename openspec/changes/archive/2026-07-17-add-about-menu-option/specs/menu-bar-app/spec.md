## MODIFIED Requirements

### Requirement: Menu bar status item
The system SHALL display a status item in the macOS menu bar when the application is running. The status item SHALL show the app icon and provide access to primary actions.

#### Scenario: Status item visible
- **WHEN** the application is running
- **THEN** a status item with the app icon is visible in the menu bar

#### Scenario: Status item menu
- **WHEN** the user clicks the status item
- **THEN** a popover or menu is displayed with options: Start Dictation, Start Meeting, About, Settings, Quit
