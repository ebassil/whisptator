## ADDED Requirements

### Requirement: Save logs to CSV
The system SHALL allow users to export the current in-memory log entries to a CSV file.

#### Scenario: Open save panel
- **WHEN** the user clicks "Save" in the Logs settings tab
- **THEN** an NSSavePanel is presented with a suggested filename containing the current date

#### Scenario: Write CSV file
- **WHEN** the user selects a location and confirms the save panel
- **THEN** a CSV file is written with columns: Timestamp, Category, Message
- **AND** the timestamp is formatted as ISO 8601
- **AND** the message field is quoted if it contains commas or newlines

#### Scenario: Empty log export
- **WHEN** the user clicks "Save" with no log entries
- **THEN** a CSV file with only the header row (Timestamp, Category, Message) is written

#### Scenario: Cancel save
- **WHEN** the user clicks "Cancel" in the save panel
- **THEN** no file is written and no error is shown
