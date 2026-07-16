# Menu Bar App

## Purpose

TBD

## Requirements

### Requirement: Menu bar status item
The system SHALL display a status item in the macOS menu bar when the application is running. The status item SHALL show the app icon and provide access to primary actions.

#### Scenario: Status item visible
- **WHEN** the application is running
- **THEN** a status item with the app icon is visible in the menu bar

#### Scenario: Status item menu
- **WHEN** the user clicks the status item
- **THEN** a popover or menu is displayed with options: Start Dictation, Start Meeting, About, Settings, Quit

### Requirement: Floating recording HUD
The system SHALL display a small floating panel during active recording (dictation or meeting) showing the recording status and elapsed time.

#### Scenario: HUD appearance
- **WHEN** recording starts
- **THEN** a floating panel appears near the top of the screen with a recording indicator and elapsed timer (MM:SS format)

#### Scenario: HUD stays on top
- **WHEN** the HUD is displayed
- **THEN** the panel has `.floating` window level and stays above all other windows

#### Scenario: HUD dismissed on stop
- **WHEN** recording stops
- **THEN** the HUD panel is dismissed after a 500ms delay

### Requirement: Settings window
The system SHALL provide a Settings window accessible from the menu bar with tabbed sections: General, Dictation, Model, Cleanup, Meeting.

#### Scenario: Settings opened from menu bar
- **WHEN** the user clicks "Settings" in the menu bar menu
- **THEN** the Settings window opens with the General tab selected

#### Scenario: Settings persist across launches
- **WHEN** the user changes a setting
- **THEN** the change is persisted and applied on next launch

### Requirement: Launch at login
The system SHALL optionally launch automatically at login using the ServiceManagement framework.

#### Scenario: Launch at login enabled
- **WHEN** the user enables "Launch at login" in Settings
- **THEN** the app registers as a login item using SMAppService

#### Scenario: Launch at login disabled
- **WHEN** the user disables "Launch at login" in Settings
- **THEN** the app is removed from login items

### Requirement: Dock visibility toggle
The system SHALL allow the user to choose whether the app appears in the Dock.

#### Scenario: Show in Dock enabled
- **WHEN** the user enables "Show in Dock" in Settings
- **THEN** the app icon appears in the Dock

#### Scenario: Show in Dock disabled
- **WHEN** the user disables "Show in Dock" in Settings
- **THEN** the app runs as an agent (menu bar only, no Dock icon)
