APP_NAME := Whisptator
BUNDLE_ID := com.whisptator.Whisptator
CODESIGN_IDENTITY := "206D3167587E5F7183B62DE441069F83AB48E776"

DEBUG_DIR := .build/debug
RELEASE_DIR := .build/release

DEBUG_APP := $(DEBUG_DIR)/$(APP_NAME).app
RELEASE_APP := $(RELEASE_DIR)/$(APP_NAME).app

PLIST = <?xml version="1.0" encoding="UTF-8"?>\n\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
<plist version="1.0">\n\
<dict>\n\
    <key>CFBundleName</key>\n\
    <string>$(APP_NAME)</string>\n\
    <key>CFBundleDisplayName</key>\n\
    <string>$(APP_NAME)</string>\n\
    <key>CFBundleIdentifier</key>\n\
    <string>$(BUNDLE_ID)</string>\n\
    <key>CFBundleVersion</key>\n\
    <string>1.0</string>\n\
    <key>CFBundleShortVersionString</key>\n\
    <string>1.0</string>\n\
    <key>CFBundlePackageType</key>\n\
    <string>APPL</string>\n\
    <key>CFBundleExecutable</key>\n\
    <string>$(APP_NAME)</string>\n\
    <key>LSMinimumSystemVersion</key>\n\
    <string>15.0</string>\n\
    <key>LSUIElement</key>\n\
    <true/>\n\
    <key>NSMicrophoneUsageDescription</key>\n\
    <string>$(APP_NAME) needs microphone access for dictation and meeting recording.</string>\n\
    <key>NSScreenCaptureUsageDescription</key>\n\
    <string>$(APP_NAME) needs screen recording access to capture system audio in meetings.</string>\n\
</dict>\n\
</plist>

.PHONY: build-debug build-release run-debug run-release clean

build-debug:
	swift build
	mkdir -p $(DEBUG_APP)/Contents/MacOS $(DEBUG_APP)/Contents/Resources
	cp $(DEBUG_DIR)/$(APP_NAME) $(DEBUG_APP)/Contents/MacOS/$(APP_NAME)
	@printf '$(PLIST)' > $(DEBUG_APP)/Contents/Info.plist
	codesign --force --sign $(CODESIGN_IDENTITY) --identifier $(BUNDLE_ID) $(DEBUG_APP)
	@echo "Created $(DEBUG_APP)"

build-release:
	swift build -c release
	mkdir -p $(RELEASE_APP)/Contents/MacOS $(RELEASE_APP)/Contents/Resources
	cp $(RELEASE_DIR)/$(APP_NAME) $(RELEASE_APP)/Contents/MacOS/$(APP_NAME)
	@printf '$(PLIST)' > $(RELEASE_APP)/Contents/Info.plist
	codesign --force --sign $(CODESIGN_IDENTITY) --identifier $(BUNDLE_ID) $(RELEASE_APP)
	@echo "Created $(RELEASE_APP)"

run-debug: build-debug
	open $(DEBUG_APP)

run-release: build-release
	open $(RELEASE_APP)

clean:
	rm -rf $(DEBUG_APP) $(RELEASE_APP)
	swift package clean
