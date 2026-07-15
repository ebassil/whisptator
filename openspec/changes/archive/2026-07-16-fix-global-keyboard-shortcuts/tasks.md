## 1. Fix Global Keyboard Shortcut Detection

- [x] 1.1 Investigate CGEvent tap implementation to identify why shortcuts are not triggering actions
- [x] 1.2 Verify event tap is properly registered and active on application launch
- [x] 1.3 Test shortcut detection with different key combinations (regular keys, modifier-only chords)
- [x] 1.4 Fix any issues with event tap thread RunLoop configuration
- [x] 1.5 Ensure event tap re-enabling mechanism is working correctly
- [x] 1.6 Validate that shortcuts work from any application regardless of focus

## 2. Implement Overlay Window System

- [x] 2.1 Create NSWindow subclass for overlay with proper window level (above all windows)
- [x] 2.2 Implement overlay positioning logic for multiple display configurations
- [x] 2.3 Add support for primary display only mode
- [x] 2.4 Add support for both displays mode
- [x] 2.5 Add support for active application display mode
- [x] 2.6 Implement configurable overlay opacity and size settings
- [x] 2.7 Add setting to enable/disable overlay entirely

## 3. Create Recording State Animation

- [x] 3.1 Design and implement pulsing circle animation with microphone icon
- [x] 3.2 Add audio-responsive animation that responds to voice input
- [x] 3.3 Implement smooth transition from idle to recording state
- [x] 3.4 Test animation performance across different hardware

## 4. Create Transcribing State Animation

- [x] 4.1 Design and implement distinct processing/transcribing animation
- [x] 4.2 Implement smooth transition from recording to transcribing state
- [x] 4.3 Ensure transcribing animation is visually distinct from recording animation
- [x] 4.4 Add completion animation when transcription finishes

## 5. Integrate Overlay with Recording System

- [x] 5.1 Connect overlay display to dictation recording start/stop events
- [x] 5.2 Connect overlay display to meeting recording start/stop events
- [x] 5.3 Implement overlay state transitions (recording → transcribing → complete)
- [x] 5.4 Ensure overlay dismisses properly after transcription completes

## 6. Add Settings UI for Overlay Configuration

- [x] 6.1 Add overlay position setting to preferences (Center, Top-Right, Bottom-Center, Follow Cursor)
- [x] 6.2 Add dual-screen behavior setting (Primary Only, Both Displays, Active App Display)
- [x] 6.3 Add overlay opacity slider (0-100%)
- [x] 6.4 Add overlay size setting
- [x] 6.5 Add toggle to enable/disable overlay

## 7. Testing and Validation

- [x] 7.1 Test keyboard shortcuts from multiple applications (Safari, TextEdit, Terminal, etc.)
- [x] 7.2 Test overlay visibility on single display setup
- [x] 7.3 Test overlay visibility on dual display setup
- [x] 7.4 Test overlay positioning options work correctly
- [x] 7.5 Test animation transitions between recording and transcribing states
- [x] 7.6 Test overlay appears above full-screen applications
- [x] 7.7 Validate performance impact is minimal
- [x] 7.8 Test with different keyboard shortcut combinations (regular and modifier-only)
