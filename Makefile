# Load .env file if it exists
-include .env
export

# Derived paths
DERIVED_DATA = ~/Library/Developer/Xcode/DerivedData/Clicker-*
MAC_APP = $(DERIVED_DATA)/Build/Products/Debug/Clicker.app
IOS_APP = $(DERIVED_DATA)/Build/Products/Debug-iphoneos/Clicker.app

.PHONY: help generate build-mac build-ios build-all run-mac install-ios run-ios clean list-devices

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

generate: ## Generate Xcode project from project.yml
	xcodegen generate

build-mac: ## Build Mac menu bar app
	xcodebuild -scheme ClickerMac build

build-ios: ## Build iOS app for physical device
	@if [ -z "$(MY_DEVICE_ID)" ]; then \
		echo "Error: MY_DEVICE_ID not set. Create .env file with MY_DEVICE_ID=your-device-id"; \
		exit 1; \
	fi
	xcodebuild -scheme ClickeriOS -destination 'id=$(MY_DEVICE_ID)' build

build-sim: ## Build iOS app for simulator
	xcodebuild -scheme ClickeriOS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' build

build-all: build-mac build-ios ## Build both Mac and iOS apps

run-mac: build-mac ## Build and run Mac app
	open $(MAC_APP)

install-ios: build-ios ## Build and install iOS app on device
	xcrun devicectl device install app --device $(MY_DEVICE_ID) $(IOS_APP)

run-ios: install-ios ## Build, install, and launch iOS app on device
	xcrun devicectl device process launch --device $(MY_DEVICE_ID) com.dou.clicker-ios

clean: ## Clean build artifacts
	xcodebuild -scheme ClickerMac clean
	xcodebuild -scheme ClickeriOS clean

list-devices: ## List connected iOS devices
	xcrun xctrace list devices
