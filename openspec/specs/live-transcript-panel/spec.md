# Live Transcript Panel

## Purpose

Provide a floating, movable/resizable panel that shows the meeting transcript as it lands, driven by the transcript file on disk, with tail-following auto-scroll that yields to manual reading.

## Requirements

### Requirement: Floating live transcript panel
The system SHALL provide a floating panel window that displays the current meeting's live transcript. The panel SHALL be movable by dragging and resizable, SHALL never be modal, SHALL NOT steal keyboard focus from other applications, and SHALL remain usable (open, closed, or ignored) without affecting recording. One panel instance exists at a time; opening it again focuses the existing panel.

#### Scenario: Panel during active meeting
- **WHEN** the user opens the panel from the menu bar during a live meeting
- **THEN** the transcript lines of the current session appear in the panel and a new panel does not spawn on repeated open

#### Scenario: Closing the panel does not stop recording
- **WHEN** the user closes the panel while a meeting is recording
- **THEN** capture, transcription, and file writing continue uninterrupted

### Requirement: File-driven content updates
The system SHALL populate and update the panel by observing the session transcript file on disk, reading only newly appended bytes after each change notification, and performing a full reload when the file shrinks (e.g., after the speaker-label rewrite).

#### Scenario: Incremental append rendering
- **WHEN** a new line is appended to the transcript file
- **THEN** the panel shows the new line within one second without re-reading the whole file

#### Scenario: Relabel reload
- **WHEN** the transcript file is atomically replaced by the relabel write-back
- **THEN** the panel detects the replacement and redisplays the full relabeled transcript

### Requirement: Auto-scroll with manual override
The system SHALL follow new transcript lines by default (auto-scroll enabled). When the user scrolls the view away from the bottom, the system SHALL disengage auto-scroll and SHALL NOT move the viewport on new lines while showing an indicator of pending new lines. When the user scrolls back to within 40 points of the bottom, the system SHALL re-engage auto-scroll and immediately jump to the newest line.

#### Scenario: Follow by default
- **WHEN** auto-scroll is engaged and a new line arrives
- **THEN** the view scrolls so the newest line is visible

#### Scenario: User scrolls up
- **WHEN** the user scrolls to a position more than 40 points above the bottom
- **THEN** auto-scroll disengages, incoming lines do not move the viewport, and a "new lines" indicator with a jump-to-latest action appears

#### Scenario: User returns to bottom
- **WHEN** the user scrolls back to within 40 points of the bottom or activates jump-to-latest
- **THEN** auto-scroll re-engages and the indicator clears

### Requirement: Panel state persistence
The system SHALL persist the panel's frame (position and size) and restore it on reopen and next app launch.

#### Scenario: Reopen after close
- **WHEN** the user closes and later reopens the panel
- **THEN** it appears at the same position and size

### Requirement: Panel session controls and status
The panel SHALL display: the session elapsed time (MM:SS), the microphone mute state, a mic mute/unmute button, a stop-recording button, and speaker-identification/finalization status when applicable. The mute button and menu bar state SHALL always reflect the authoritative mute state.

#### Scenario: Mute from the panel
- **WHEN** the user clicks the mute button in the panel
- **THEN** the microphone channel is muted and the button, panel, and menu bar all reflect the muted state

#### Scenario: Finalization visible
- **WHEN** the meeting stops with speaker identification enabled
- **THEN** the panel shows a finalizing status until the relabel completes, after which the relabeled lines appear

### Requirement: Auto-show on meeting start
The system SHALL show the panel automatically when a meeting recording starts, controllable by a setting defaulting to ON.

#### Scenario: Meeting begins
- **WHEN** meeting recording starts and auto-show is ON
- **THEN** the panel appears with the empty transcript view ready for incoming lines
