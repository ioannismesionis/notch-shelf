APP_NAME := NotchShelf
VERSION := 0.1.0
BUILD_DIR := .build/debug
RELEASE_DIR := .build/release
BINARY := $(BUILD_DIR)/$(APP_NAME)
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
APP_CONTENTS := $(APP_BUNDLE)/Contents
APP_MACOS := $(APP_CONTENTS)/MacOS
APP_RESOURCES := $(APP_CONTENTS)/Resources
APP_ICON := Packaging/AppIcon.icns
APP_ICONSET := Packaging/AppIcon.iconset
TMP_ROOT := /private/tmp/notch-shelf-build
TMP_APP_BUNDLE := $(TMP_ROOT)/$(APP_NAME).app
TMP_APP_CONTENTS := $(TMP_APP_BUNDLE)/Contents
TMP_APP_MACOS := $(TMP_APP_CONTENTS)/MacOS
TMP_APP_RESOURCES := $(TMP_APP_CONTENTS)/Resources
INFO_PLIST := Packaging/Info.plist
INSTALL_DIR ?= /Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app
MACOS_TARGET ?= arm64-apple-macosx14.0
SOURCES := $(shell find Sources/NotchShelf -name '*.swift' | sort)

.PHONY: app-icon build build-app verify-app release run run-app stop restart-app install-app open-installed-app clean

app-icon:
	mkdir -p $(BUILD_DIR)
	swiftc -swift-version 5 Tools/GenerateAppIcon.swift -o $(BUILD_DIR)/GenerateAppIcon
	$(BUILD_DIR)/GenerateAppIcon
	iconutil -c icns $(APP_ICONSET) -o $(APP_ICON)

build:
	mkdir -p $(BUILD_DIR)
	swiftc -swift-version 5 -target $(MACOS_TARGET) -parse-as-library $(SOURCES) -o $(BINARY)

build-app: app-icon build
	rm -rf $(APP_BUNDLE) $(TMP_ROOT)
	mkdir -p $(TMP_APP_MACOS) $(TMP_APP_RESOURCES)
	cp $(BINARY) $(TMP_APP_MACOS)/$(APP_NAME)
	cp $(INFO_PLIST) $(TMP_APP_CONTENTS)/Info.plist
	cp $(APP_ICON) $(TMP_APP_RESOURCES)/AppIcon.icns
	chmod +x $(TMP_APP_MACOS)/$(APP_NAME)
	/usr/bin/xattr -cr $(TMP_APP_BUNDLE)
	codesign --force --deep --sign - $(TMP_APP_BUNDLE)
	mkdir -p $(BUILD_DIR)
	ditto --noextattr --norsrc $(TMP_APP_BUNDLE) $(APP_BUNDLE)

verify-app: build-app
	plutil -lint $(APP_CONTENTS)/Info.plist
	codesign --verify --deep $(APP_BUNDLE)

release: verify-app
	rm -rf $(RELEASE_DIR)
	mkdir -p $(RELEASE_DIR)
	ditto -c -k --keepParent $(APP_BUNDLE) $(RELEASE_DIR)/$(APP_NAME)-$(VERSION)-macOS.zip
	@echo "Release package: $(RELEASE_DIR)/$(APP_NAME)-$(VERSION)-macOS.zip"

run: build
	$(BINARY)

run-app: build-app
	open $(APP_BUNDLE)

stop:
	@if pgrep -x $(APP_NAME) >/dev/null; then \
		pkill -x $(APP_NAME); \
		sleep 0.4; \
		echo "Stopped $(APP_NAME)."; \
	else \
		echo "$(APP_NAME) is not running."; \
	fi

restart-app: stop run-app

install-app: build-app stop
	rm -rf "$(INSTALLED_APP)"
	ditto --noextattr --norsrc "$(APP_BUNDLE)" "$(INSTALLED_APP)"
	/usr/bin/xattr -cr "$(INSTALLED_APP)"
	codesign --verify --deep "$(INSTALLED_APP)"
	@echo "Installed $(INSTALLED_APP)"

open-installed-app: install-app
	open "$(INSTALLED_APP)"

clean:
	rm -rf .build
