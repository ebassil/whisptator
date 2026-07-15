## 1. PermissionGate Updates

- [x] 1.1 Add `checkAccessibilityPermission()` and `checkScreenRecordingPermission()` public methods to `PermissionGate`
- [x] 1.2 Ensure `PermissionGate.checkPermissions()` is usable from SwiftUI via `@Observable` or a published wrapper

## 2. General Settings Reactive Permission Checking

- [x] 2.1 Add `@State private var permissions = PermissionStatus(...)` to `GeneralSettingsTab`
- [x] 2.2 Add `.onAppear` to initialize permissions from `PermissionGate.checkPermissions()`
- [x] 2.3 Add a 2-second polling timer via `Timer.publish` that re-checks permissions while the tab is visible
- [x] 2.4 Add `.onDisappear` to cancel the polling timer
- [x] 2.5 Replace inline `AXIsProcessTrusted()` and `checkMicrophonePermission()` calls with `PermissionGate.checkPermissions()`

## 3. Fix Accessibility Deep-link

- [x] 3.1 Change the Accessibility "Grant in Settings" button URL from `Privacy` to `Privacy_Accessibility`
- [x] 3.2 Verify the deep-link opens the Accessibility sub-pane in System Settings

## 4. Add Screen Recording Permission Row

- [x] 4.1 Add `PermissionRow(name: "Screen Recording", granted: ...)` to the General Settings permissions section
- [x] 4.2 Ensure the Screen Recording button opens the correct System Settings pane (`Privacy_ScreenCapture`)

## 5. Test & Verify

- [x] 5.1 Build the app with `make build-debug` and verify no compilation errors
- [ ] 5.2 Run the app and verify all three permission rows display correctly in General Settings
- [ ] 5.3 Verify the Accessibility deep-link opens the correct System Settings pane
- [ ] 5.4 Verify permission status updates reactively when granted while settings are open
