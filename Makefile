APP_NAME := NotchShelf
BUILD_DIR := .build/debug
BINARY := $(BUILD_DIR)/$(APP_NAME)
MACOS_TARGET ?= arm64-apple-macosx14.0
SOURCES := $(shell find Sources/NotchShelf -name '*.swift' | sort)

.PHONY: build run clean

build:
	mkdir -p $(BUILD_DIR)
	swiftc -swift-version 5 -target $(MACOS_TARGET) -parse-as-library $(SOURCES) -o $(BINARY)

run: build
	$(BINARY)

clean:
	rm -rf .build
