APP_NAME := NotchShelf
BUILD_DIR := .build/debug
BINARY := $(BUILD_DIR)/$(APP_NAME)
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
APP_CONTENTS := $(APP_BUNDLE)/Contents
APP_MACOS := $(APP_CONTENTS)/MacOS
APP_RESOURCES := $(APP_CONTENTS)/Resources
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

.PHONY: build build-app verify-app run run-app stop restart-app install-app open-installed-app clean

build:
	mkdir -p $(BUILD_DIR)
	swiftc -swift-version 5 -target $(MACOS_TARGET) -parse-as-library $(SOURCES) -o $(BINARY)

build-app: build
	rm -rf $(APP_BUNDLE) $(TMP_ROOT)
	mkdir -p $(TMP_APP_MACOS) $(TMP_APP_RESOURCES)
	cp $(BINARY) $(TMP_APP_MACOS)/$(APP_NAME)
	cp $(INFO_PLIST) $(TMP_APP_CONTENTS)/Info.plist
	chmod +x $(TMP_APP_MACOS)/$(APP_NAME)
	/usr/bin/xattr -cr $(TMP_APP_BUNDLE)
	codesign --force --deep --sign - $(TMP_APP_BUNDLE)
	mkdir -p $(BUILD_DIR)
	ditto --noextattr --norsrc $(TMP_APP_BUNDLE) $(APP_BUNDLE)

verify-app: build-app
	plutil -lint $(APP_CONTENTS)/Info.plist
	codesign --verify --deep $(APP_BUNDLE)

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
