# ChromeSwitch — build, bundle, and install without Xcode (Command Line Tools are enough).

APP_NAME    := ChromeSwitch
BUNDLE_ID   := com.bareuther.chromeswitch
VERSION     := 0.1.0
BUILD_DIR   := .build
APP_DIR     := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR ?= /Applications
LSREGISTER  := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: all build test app icon install uninstall clean

all: app

build:
	swift build -c release

test:
	swift run -c release ChromeSwitchChecks

icon: $(BUILD_DIR)/AppIcon.icns

$(BUILD_DIR)/AppIcon.icns: scripts/make-icon.swift
	mkdir -p $(BUILD_DIR)
	swiftc -O scripts/make-icon.swift -o $(BUILD_DIR)/make-icon
	rm -rf $(BUILD_DIR)/AppIcon.iconset
	$(BUILD_DIR)/make-icon $(BUILD_DIR)/AppIcon.iconset
	iconutil -c icns $(BUILD_DIR)/AppIcon.iconset -o $@

app: build icon
	rm -rf $(APP_DIR)
	mkdir -p $(APP_DIR)/Contents/MacOS $(APP_DIR)/Contents/Resources
	cp $(BUILD_DIR)/release/$(APP_NAME) $(APP_DIR)/Contents/MacOS/$(APP_NAME)
	sed -e 's/@VERSION@/$(VERSION)/g' -e 's/@BUNDLE_ID@/$(BUNDLE_ID)/g' Resources/Info.plist > $(APP_DIR)/Contents/Info.plist
	cp $(BUILD_DIR)/AppIcon.icns $(APP_DIR)/Contents/Resources/AppIcon.icns
	printf 'APPL????' > $(APP_DIR)/Contents/PkgInfo
	codesign --force --sign - --identifier $(BUNDLE_ID) $(APP_DIR)
	@echo "Built $(APP_DIR)"

install: app
	-pkill -x $(APP_NAME)
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	ditto $(APP_DIR) "$(INSTALL_DIR)/$(APP_NAME).app"
	$(LSREGISTER) -f "$(INSTALL_DIR)/$(APP_NAME).app"
	open "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app — now pick 'Use ChromeSwitch as Default Browser…' from its menu bar icon."

uninstall:
	-pkill -x $(APP_NAME)
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	defaults delete $(BUNDLE_ID) 2>/dev/null || true
	@echo "Removed. macOS will fall back to another browser; set your default in System Settings → Desktop & Dock."

clean:
	rm -rf $(BUILD_DIR)
