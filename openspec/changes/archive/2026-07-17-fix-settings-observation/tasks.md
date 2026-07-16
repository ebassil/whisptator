## 1. Core Fix

- [x] 1.1 Add stored property initialization from UserDefaults in `AppSettings.init()` for all properties that have persisted defaults
- [x] 1.2 Convert `pushToTalkShortcut`, `handsFreeShortcut`, `meetingShortcut` to stored properties with `didSet` using JSON encode/decode
- [x] 1.3 Convert `pasteMode`, `selectedAudioDeviceID`, `language`, `cleanupMode` to stored properties with `didSet`
- [x] 1.4 Convert `fillerWords`, `wordReplacements`, `snippets` to stored properties with `didSet` using JSON encode/decode
- [x] 1.5 Convert `meetingAudioSource`, `meetingRetention`, `meetingRetentionDays`, `meetingSaveLocation` to stored properties with `didSet`
- [x] 1.6 Convert `launchAtLogin`, `showInDock`, `hasCompletedOnboarding`, `saveAudioFiles`, `isLoggingPaused` to stored properties with `didSet`
- [x] 1.7 Convert `overlayEnabled`, `overlayPosition`, `overlayOpacity`, `overlaySize`, `dualScreenMode` to stored properties with `didSet`
- [x] 1.8 Convert `audioSaveLocation`, `selectedModelId` to stored properties with `didSet`
- [x] 1.9 Convert `logEnabledCategories` to stored property with `didSet` using JSON encode/decode
- [x] 1.10 Remove all old computed getter/setter blocks

## 2. Verify

- [x] 2.1 Run existing `testSettingsPersistence` integration test
- [x] 2.2 Build the project and verify all settings controls visually reflect user changes
