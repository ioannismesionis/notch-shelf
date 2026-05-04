APP_NAME := NotchShelf
BUILD_DIR := .build/debug
BINARY := $(BUILD_DIR)/$(APP_NAME)
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
APP_CONTENTS := $(APP_BUNDLE)/Contents
APP_MACOS := $(APP_CONTENTS)/MacOS
APP_RESOURCES := $(APP_CONTENTS)/Resources
INFO_PLIST := Packaging/Info.plist
MACOS_TARGET ?= arm64-apple-macosx14.0
SOURCES := $(shell find Sources/NotchShelf -name '*.swift' | sort)

.PHONY: build build-app verify-app run run-app clean

build:
	mkdir -p $(BUILD_DIR)
	swiftc -swift-version 5 -target $(MACOS_TARGET) -parse-as-library $(SOURCES) -o $(BINARY)

build-app: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_MACOS) $(APP_RESOURCES)
	cp $(BINARY) $(APP_MACOS)/$(APP_NAME)
	cp $(INFO_PLIST) $(APP_CONTENTS)/Info.plist
	chmod +x $(APP_MACOS)/$(APP_NAME)
	/usr/bin/xattr -cr $(APP_BUNDLE)
	codesign --force --deep --sign - $(APP_BUNDLE)

verify-app: build-app
	plutil -lint $(APP_CONTENTS)/Info.plist
	codesign --verify --deep $(APP_BUNDLE)

run: build
	$(BINARY)

run-app: build-app
	open $(APP_BUNDLE)

clean:
	rm -rf .build
