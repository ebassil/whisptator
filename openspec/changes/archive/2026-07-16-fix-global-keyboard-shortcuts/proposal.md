## Why

The global keyboard shortcuts for recording audio and transcribing are configured in application settings but not functioning. Users expect pressing these shortcuts to trigger recording and display visual feedback via an overlay animation. The current implementation fails to respond to shortcut events, preventing users from initiating dictation or meeting recording from any application without switching focus.

## What Changes

- Fix global keyboard shortcut monitoring to ensure configured shortcuts trigger recording
- Add overlay animation to indicate recording state (microphone active)
- Add distinct overlay animation to indicate transcribing/AI model processing state
- Ensure overlay is displayed on top of all open windows on all connected displays
- Support dual-screen setups by showing overlay on both displays simultaneously

## Capabilities

### New Capabilities

- `overlay-visual-feedback`: Overlay animations to indicate recording, transcribing, and pasting states visible system-wide

### Modified Capabilities

- `hotkey-system`: Fix shortcut detection and event handling to ensure configured shortcuts trigger recording actions
- `dictation`: Add visual feedback overlay during recording and transcription phases
- `meeting-recording`: Add visual feedback overlay during recording and transcription phases

## Impact

- Core event handling system (CGEvent tap monitoring)
- Overlay UI layer and window management
- Screen capture for dual-display support
- Audio recording pipeline integration
- Transcription service integration
- Settings persistence for overlay preferences