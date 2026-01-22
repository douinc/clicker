# Load .env file if it exists
-include .env
export

# Find the most recently modified DerivedData folder
DERIVED_DATA = $(shell ls -td ~/Library/Developer/Xcode/DerivedData/Clicker-* 2>/dev/null | head -1)
MAC_APP = $(DERIVED_DATA)/Build/Products/Debug/Clicker.app
IOS_APP = $(DERIVED_DATA)/Build/Products/Debug-iphoneos/Clicker.app
IOS_SIM_APP = $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/Clicker.app

.PHONY: help generate build-mac build-ios build-all run-mac install-ios run-ios clean list-devices screenshot

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

generate: ## Generate Xcode project from project.yml
	xcodegen generate

build-mac: ## Build Mac menu bar app
	xcodebuild -scheme ClickerMac build

build-ios: ## Build iOS app for physical device
	@if [ -z "$(XCODE_DEVICE_ID)" ]; then \
		echo "Error: XCODE_DEVICE_ID not set. Create .env file with XCODE_DEVICE_ID=your-udid"; \
		exit 1; \
	fi
	xcodebuild -scheme ClickeriOS -destination 'id=$(XCODE_DEVICE_ID)' build

build-sim: ## Build iOS app for simulator
	xcodebuild -scheme ClickeriOS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' build

build-all: build-mac build-ios ## Build both Mac and iOS apps

run-mac: build-mac ## Build and run Mac app
	open $(MAC_APP)

install-ios: build-ios ## Build and install iOS app on device
	@if [ -z "$(DEVICECTL_ID)" ]; then \
		echo "Error: DEVICECTL_ID not set. Run 'xcrun devicectl list devices' to find your device UUID"; \
		exit 1; \
	fi
	xcrun devicectl device install app --device $(DEVICECTL_ID) $(IOS_APP)

run-ios: install-ios ## Build, install, and launch iOS app on device
	xcrun devicectl device process launch --device $(DEVICECTL_ID) com.dou.clicker-ios

clean: ## Clean build artifacts
	xcodebuild -scheme ClickerMac clean
	xcodebuild -scheme ClickeriOS clean

list-devices: ## List connected iOS devices
	xcrun xctrace list devices

screenshot: ## Build and run iOS app in screenshot mode (no trial banner)
	xcodebuild -scheme ClickeriOS \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG SCREENSHOT_MODE' \
		build
	xcrun simctl boot "iPhone 16" 2>/dev/null || true
	xcrun simctl install booted $(IOS_SIM_APP)
	xcrun simctl launch booted com.dou.clicker-ios
