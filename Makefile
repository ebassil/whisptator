APP_NAME := Whisptator
BUNDLE_ID := com.whisptator.Whisptator
VERSION := 1.1
CODESIGN_IDENTITY := "206D3167587E5F7183B62DE441069F83AB48E776"

# SwiftPM build products: read-only here. Writing into this directory (mkdir/cp/
# codesign) mutates nodes Swift Build owns, which makes it warn
# "missing creator for mutated node" and re-validate the tree on every build.
DEBUG_DIR := .build/debug
RELEASE_DIR := .build/release

# Staged .app bundles live outside .build, so the products dir is never written to.
APP_DIR := App
DEBUG_APP := $(APP_DIR)/Debug/$(APP_NAME).app
RELEASE_APP := $(APP_DIR)/Release/$(APP_NAME).app

LAME_FRAMEWORK := .build/artifacts/lame-xcframework/LAME/LAME.xcframework/macos-arm64_x86_64/LAME.framework

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
    <string>$(VERSION)</string>\n\
    <key>CFBundleShortVersionString</key>\n\
    <string>$(VERSION)</string>\n\
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

# Assemble $(2) (.app path) from the products in $(1) (products dir).
# SwiftPM resource bundles are copied into Contents/Resources so the app finds
# them via Bundle.main / Bundle.module no matter where the .app lives.
define assemble_app
	rm -rf $(2)
	mkdir -p $(2)/Contents/MacOS $(2)/Contents/Resources $(2)/Contents/Frameworks
	cp $(1)/$(APP_NAME) $(2)/Contents/MacOS/$(APP_NAME)
	for bundle in $(1)/*.bundle; do \
		[ -d "$$bundle" ] || continue; \
		cp -R "$$bundle" $(2)/Contents/Resources/; \
	done
	cp -R $(LAME_FRAMEWORK) $(2)/Contents/Frameworks/
	install_name_tool -add_rpath @executable_path/../Frameworks $(2)/Contents/MacOS/$(APP_NAME)
	@printf '$(PLIST)' > $(2)/Contents/Info.plist
	codesign --force --sign $(CODESIGN_IDENTITY) --identifier $(BUNDLE_ID) $(2)
	@echo "Created $(2)"
endef

build-debug:
	swift build
	$(call assemble_app,$(DEBUG_DIR),$(DEBUG_APP))

build-release:
	swift build -c release
	$(call assemble_app,$(RELEASE_DIR),$(RELEASE_APP))

run-debug: build-debug
	open $(DEBUG_APP)

run-release: build-release
	open $(RELEASE_APP)

clean:
	rm -rf $(APP_DIR)
	rm -rf $(DEBUG_DIR)/$(APP_NAME).app $(RELEASE_DIR)/$(APP_NAME).app
	swift package clean
