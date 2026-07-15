## Context

The global keyboard shortcuts for recording audio and transcribing are configured in application settings but not functioning. Users expect pressing these shortcuts to trigger recording and display visual feedback via an overlay animation. The current implementation fails to respond to shortcut events, preventing users from initiating dictation or meeting recording from any application without switching focus.

Current state:
- CGEvent tap monitoring exists in `hotkey-system` spec
- Dictation and meeting recording functionality is implemented
- No visual feedback overlay exists for recording/transcribing states
- Dual-screen support is not implemented

## Goals / Non-Goals

**Goals:**
- Fix global keyboard shortcut detection and event handling
- Create visual overlay to indicate recording state
- Create distinct visual overlay to indicate transcribing/AI processing state
- Ensure overlay is visible on top of all windows
- Support dual-screen setups with overlay on both displays
- Provide multiple design options for overlay positioning and animation

**Non-Goals:**
- Modify the underlying audio recording or transcription logic
- Change shortcut configuration UI or persistence
- Implement new shortcut types (push-to-talk vs hands-free)
- Modify the paste engine behavior

## Decisions

### Decision 1: Overlay Position Strategy

**Option A: Center of Screen (Modal Style)**
- Position: Centered on primary display
- Pros: High visibility, familiar pattern, easy to notice
- Cons: May obstruct content, not ideal for dual-screen

**Option B: Top-Right Corner (Notification Style)**
- Position: Top-right corner of primary display
- Pros: Non-intrusive, follows macOS notification pattern
- Cons: May be missed if user is focused elsewhere

**Option C: Bottom-Center (Dock Style)**
- Position: Bottom center of screen, above the dock
- Pros: Out of the way, consistent position
- Cons: May conflict with dock interactions

**Option D: Follow Mouse Cursor**
- Position: Appears near the mouse cursor location
- Pros: Always near user's focus, contextual
- Cons: May be distracting, harder to track

**Option E: Top of Screen (Status Bar Style)**
- Position: Centered at top of screen, below menu bar
- Pros: Visible but non-intrusive, consistent
- Cons: May overlap with menu bar items

### Decision 2: Animation Design

**Option A: Pulsing Circle with Microphone Icon**
- Design: Animated circle with microphone icon that pulses during recording
- Transcribing: Circle changes color and shows processing animation
- Pros: Clear visual metaphor, easy to understand
- Cons: May be too simple for some users

**Option B: Waveform Animation**
- Design: Audio waveform that responds to voice input
- Transcribing: Waveform transforms into processing dots
- Pros: Dynamic, visually interesting, shows audio activity
- Cons: More complex to implement, may be distracting

**Option C: Radial Progress Indicator**
- Design: Circular progress ring that fills during recording
- Transcribing: Ring animates with spinning effect
- Pros: Shows progress, modern design
- Cons: May imply determinate progress when recording is indeterminate

**Option D: Gradient Background Animation**
- Design: Animated gradient background with status text
- Transcribing: Gradient color shift with different animation
- Pros: Subtle, modern, less intrusive
- Cons: May be too subtle, less clear status indication

### Decision 3: Dual-Screen Behavior

**Option A: Primary Display Only**
- Show overlay only on the main display
- Pros: Simple implementation, consistent behavior
- Cons: Users with apps on secondary display may miss it

**Option B: Both Displays Simultaneously**
- Show identical overlay on both displays
- Pros: Always visible regardless of which display user is focused on
- Cons: May be redundant, slightly more resource usage

**Option C: Active Application Display**
- Show overlay on the display where the frontmost application is located
- Pros: Contextually relevant, non-intrusive
- Cons: More complex to determine, may jump between displays

## Risks / Trade-offs

- **Risk**: Overlay may be too intrusive and annoy users → **Mitigation**: Provide settings to adjust opacity, size, and position; add option to disable overlay
- **Risk**: Dual-screen overlay may impact performance → **Mitigation**: Use efficient rendering, limit to two displays maximum
- **Risk**: Overlay may not appear on top of certain full-screen apps → **Mitigation**: Use NSWindow level `.statusBar` or higher, test with common full-screen apps
- **Risk**: Different animation states may confuse users → **Mitigation**: Use distinct colors and clear iconography (microphone for recording, processing icon for transcribing)

## Migration Plan

1. Implement overlay window with configurable position
2. Add animation system with recording and transcribing states
3. Integrate with existing hotkey system to trigger overlay
4. Add dual-screen support using NSScreen enumeration
5. Add settings for overlay preferences (position, opacity, dual-screen behavior)
6. Test with various applications and screen configurations

## Open Questions

1. Which overlay position option should be the default? (Recommend Option A or E)
2. Should overlay position be configurable in settings or fixed?
3. Should dual-screen behavior be configurable or always show on both?
4. What should the transition animation be between recording and transcribing states?