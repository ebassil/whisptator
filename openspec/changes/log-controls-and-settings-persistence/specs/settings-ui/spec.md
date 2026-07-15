## MODIFIED Requirements

### Requirement: Logs settings tab
The system SHALL provide a Logs settings tab that displays real-time log entries from all subsystems with controls for pause/resume, category configuration, and export.

#### Scenario: Log entries displayed
- **WHEN** the user opens Logs settings
- **THEN** a scrollable list of log entries is displayed, newest first, with timestamp, category badge, and message

#### Scenario: Log entries auto-update
- **WHEN** a new log entry is emitted from any subsystem
- **AND** logging is not paused
- **AND** the entry's category is enabled
- **THEN** the log list automatically updates and scrolls to show the newest entry

#### Scenario: Clear logs
- **WHEN** the user clicks "Clear"
- **THEN** all log entries are removed

#### Scenario: Pause/resume logging
- **WHEN** the user clicks "Stop" in the Logs tab toolbar
- **THEN** log collection pauses
- **AND** the button changes to "Start"
- **WHEN** the user clicks "Start"
- **THEN** log collection resumes
- **AND** the button changes to "Stop"

#### Scenario: Open log config sheet
- **WHEN** the user clicks the config icon button in the Logs tab toolbar
- **THEN** a modal sheet appears with toggle switches for each log category

#### Scenario: Save logs to CSV
- **WHEN** the user clicks "Save" in the Logs tab toolbar
- **THEN** an NSSavePanel is presented to export log entries as CSV

### Requirement: Resizable settings window
The system SHALL allow users to resize the Settings window to their preferred dimensions.

#### Scenario: Window resize drag handle
- **WHEN** the user drags the edge or corner of the Settings window
- **THEN** the window resizes freely
- **AND** all tab content reflows to fit the new dimensions

#### Scenario: Minimum window size
- **WHEN** the user attempts to resize the Settings window below its minimum dimensions
- **THEN** the window stops at its minimum size
