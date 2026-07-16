# Log Controls

## Purpose

TBD

## Requirements

### Requirement: Log pause/resume
The system SHALL allow users to pause and resume log entry collection from the Logs settings tab.

#### Scenario: Pause logging
- **WHEN** the user clicks "Stop" in the Logs settings tab
- **THEN** new log entries are no longer added to the in-memory log buffer
- **AND** the button label changes to "Start"

#### Scenario: Resume logging
- **WHEN** the user clicks "Start" in the Logs settings tab
- **THEN** new log entries resume being added to the in-memory log buffer
- **AND** the button label changes to "Stop"

#### Scenario: Pause state persists across app restart
- **WHEN** the user pauses logging and restarts the app
- **THEN** logging remains paused on launch

### Requirement: Per-category log enable/disable
The system SHALL allow users to enable or disable individual log categories, controlling which categories are recorded by the logger.

#### Scenario: Open log config sheet
- **WHEN** the user clicks the config icon button in the Logs settings tab
- **THEN** a sheet opens showing a list of all available log categories with toggle switches

#### Scenario: Disable a category
- **WHEN** the user toggles off a category in the config sheet
- **THEN** log entries for that category are no longer recorded
- **AND** existing entries for that category remain in the log buffer

#### Scenario: Re-enable a category
- **WHEN** the user toggles on a previously disabled category in the config sheet
- **THEN** log entries for that category resume being recorded

#### Scenario: Enable all categories
- **WHEN** the user clicks "Enable All" in the log config sheet
- **THEN** all log categories are enabled

#### Scenario: Disable all categories
- **WHEN** the user clicks "Disable All" in the log config sheet
- **THEN** all log categories are disabled
- **AND** no new log entries are recorded regardless of origin

#### Scenario: Category settings persist across app restart
- **WHEN** the user disables a category and restarts the app
- **THEN** that category remains disabled on launch
