## ADDED Requirements

### Requirement: About dialog
The system SHALL provide an About dialog accessible from the menu bar that displays application information and a link to the GitHub repository.

#### Scenario: About dialog opened from menu bar
- **WHEN** the user clicks "About" in the menu bar menu
- **THEN** a modal dialog is displayed with the application name "Whisptator"

#### Scenario: About dialog shows app description
- **WHEN** the About dialog is displayed
- **THEN** it SHALL show a description of what the app does

#### Scenario: About dialog shows developer credit
- **WHEN** the About dialog is displayed
- **THEN** it SHALL show the developer name "Émile Bassil"

#### Scenario: About dialog has clickable GitHub link
- **WHEN** the user clicks the GitHub link in the About dialog
- **THEN** the URL https://github.com/ebassil/whisptator opens in the default browser
