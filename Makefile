# Load .env file if it exists
-include .env
export

# Find the most recently modified DerivedData folder
DERIVED_DATA = $(shell ls -td ~/Library/Developer/Xcode/DerivedData/Clicker-* 2>/dev/null | head -1)
MAC_APP = $(DERIVED_DATA)/Build/Products/Debug/ClickerRemoteReceiver.app
IOS_APP = $(DERIVED_DATA)/Build/Products/Debug-iphoneos/ClickerRemote.app
IOS_SIM_APP = $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/ClickerRemote.app

.PHONY: help generate build-mac build-ios build-all run-mac install-ios run-ios clean list-devices screenshot \
       archive-ios upload-ios release-ios archive-mac dmg release-mac \
       build-mac-release verify-signing sign-dmg notarize verify-notarization check-signing setup-notary notary-log \
       brew-sha256 brew-update-cask brew-publish

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

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

clean: ## Clean build artifacts and unmount/remove installed app
	xcodebuild -scheme ClickerMac clean
	xcodebuild -scheme ClickeriOS clean
	@echo "🧹 Cleaning up mounted volumes and installed app (requires sudo)..."
	-sudo umount -f /Volumes/ClickerRemoteReceiver 2>/dev/null || true
	-sudo rm -rf /Volumes/ClickerRemoteReceiver 2>/dev/null || true
	-sudo rm -rf /Applications/ClickerRemoteReceiver.app 2>/dev/null || true
	@echo "✅ Clean complete"

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

# ============================================================================
# iOS App Store Distribution
# ============================================================================

archive-ios: ## Archive iOS app for App Store
	xcodebuild archive \
		-scheme ClickeriOS \
		-archivePath ./build/Clicker.xcarchive \
		-destination 'generic/platform=iOS'

upload-ios: ## Export and upload iOS app to App Store Connect
	xcodebuild -exportArchive \
		-archivePath ./build/Clicker.xcarchive \
		-exportPath ./build/export \
		-exportOptionsPlist ExportOptions.plist

release-ios: archive-ios upload-ios ## Archive and upload iOS app to App Store Connect

# ============================================================================
# Mac App GitHub Distribution (Signed + Notarized DMG)
# ============================================================================

RELEASE_MAC_APP = $(DERIVED_DATA)/Build/Products/Release/ClickerRemoteReceiver.app
DMG_NAME = ClickerRemoteReceiver
MAC_LOGO = public/logo/mac-logo.png
VERSION = $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" MacApp/Info.plist 2>/dev/null || echo "1.0.0")
NOTARY_PROFILE = notarytool-profile
SIGNING_IDENTITY = "Developer ID Application: DOU Inc. (HD35YQ72U4)"

build-mac-release: ## Build Mac app in Release configuration (with Developer ID signing)
	xcodebuild -scheme ClickerMac -configuration Release build

archive-mac: ## Archive Mac app for distribution
	xcodebuild archive \
		-scheme ClickerMac \
		-archivePath ./build/ClickerMac.xcarchive

verify-signing: build-mac-release ## Verify app is signed correctly for distribution
	@echo "🔍 Verifying code signature..."
	codesign --verify --deep --strict --verbose=2 $(RELEASE_MAC_APP)
	@echo ""
	@echo "🔍 Checking signing identity..."
	codesign -dvv $(RELEASE_MAC_APP) 2>&1 | grep "Authority"
	@echo ""
	@echo "🔍 Checking Hardened Runtime..."
	codesign -dvv $(RELEASE_MAC_APP) 2>&1 | grep -E "(flags|runtime)"
	@echo ""
	@echo "✅ Signature verification complete"

dmg: build-mac-release ## Create DMG for Mac app distribution (unsigned)
	@mkdir -p ./build
	@rm -f ./build/$(DMG_NAME)-$(VERSION).dmg
	@echo "Creating DMG with custom icon..."
	@# Create iconset from PNG
	@rm -rf ./build/dmg-icon.iconset
	@mkdir -p ./build/dmg-icon.iconset
	@sips -s format png -z 16 16     $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_16x16.png
	@sips -s format png -z 32 32     $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_16x16@2x.png
	@sips -s format png -z 32 32     $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_32x32.png
	@sips -s format png -z 64 64     $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_32x32@2x.png
	@sips -s format png -z 128 128   $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_128x128.png
	@sips -s format png -z 256 256   $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_128x128@2x.png
	@sips -s format png -z 256 256   $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_256x256.png
	@sips -s format png -z 512 512   $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_256x256@2x.png
	@sips -s format png -z 512 512   $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_512x512.png
	@sips -s format png -z 1024 1024 $(MAC_LOGO) --out ./build/dmg-icon.iconset/icon_512x512@2x.png
	@iconutil -c icns ./build/dmg-icon.iconset -o ./build/dmg-icon.icns
	@# Create a temporary folder for DMG contents
	@rm -rf ./build/dmg-temp
	@mkdir -p ./build/dmg-temp
	@cp -R $(RELEASE_MAC_APP) ./build/dmg-temp/
	@ln -s /Applications ./build/dmg-temp/Applications
	@# Create read-write DMG first (to set volume icon)
	hdiutil create -volname "$(DMG_NAME)" \
		-srcfolder ./build/dmg-temp \
		-ov -format UDRW \
		./build/$(DMG_NAME)-rw.dmg
	@# Mount, set volume icon, unmount
	@hdiutil attach ./build/$(DMG_NAME)-rw.dmg -mountpoint /Volumes/$(DMG_NAME)
	@cp ./build/dmg-icon.icns /Volumes/$(DMG_NAME)/.VolumeIcon.icns
	@SetFile -a C /Volumes/$(DMG_NAME)
	@hdiutil detach /Volumes/$(DMG_NAME)
	@sleep 2
	@# Convert to compressed read-only DMG
	hdiutil convert ./build/$(DMG_NAME)-rw.dmg \
		-format UDZO \
		-o ./build/$(DMG_NAME)-$(VERSION).dmg
	@# Cleanup
	@rm -rf ./build/dmg-temp ./build/dmg-icon.iconset ./build/dmg-icon.icns ./build/$(DMG_NAME)-rw.dmg
	@echo "✅ DMG created: ./build/$(DMG_NAME)-$(VERSION).dmg"

sign-dmg: dmg ## Sign the DMG with Developer ID
	@echo "🔏 Signing DMG..."
	codesign --force --sign $(SIGNING_IDENTITY) ./build/$(DMG_NAME)-$(VERSION).dmg
	@echo "✅ DMG signed"

notarize: sign-dmg ## Submit DMG for notarization and wait for result
	@echo "📤 Submitting for notarization..."
	xcrun notarytool submit ./build/$(DMG_NAME)-$(VERSION).dmg \
		--keychain-profile $(NOTARY_PROFILE) \
		--wait
	@echo ""
	@echo "📎 Stapling notarization ticket..."
	xcrun stapler staple ./build/$(DMG_NAME)-$(VERSION).dmg
	@echo ""
	@echo "✅ Notarization complete!"

verify-notarization: ## Verify the DMG is properly notarized
	@echo "🔍 Verifying notarization..."
	spctl --assess --type open --context context:primary-signature --verbose=2 ./build/$(DMG_NAME)-$(VERSION).dmg
	@echo ""
	xcrun stapler validate ./build/$(DMG_NAME)-$(VERSION).dmg
	@echo "✅ Notarization verified"

release-mac: notarize ## Build, sign, notarize DMG and show GitHub release instructions
	@echo ""
	@echo "📦 Mac DMG ready for GitHub release!"
	@echo "   File: ./build/$(DMG_NAME)-$(VERSION).dmg"
	@echo ""
	@echo "To create a GitHub release:"
	@echo "  gh release create v$(VERSION) ./build/$(DMG_NAME)-$(VERSION).dmg \\"
	@echo "    --title 'Clicker v$(VERSION)' \\"
	@echo "    --notes 'Release notes here'"
	@echo ""

# ============================================================================
# Notarization Setup Helpers
# ============================================================================

check-signing: ## Check if Developer ID certificate is installed
	@echo "🔍 Looking for Developer ID Application certificate..."
	@security find-identity -v -p codesigning | grep "Developer ID Application" || \
		(echo "❌ No Developer ID Application certificate found!" && \
		 echo "" && \
		 echo "To create one:" && \
		 echo "  1. Go to https://developer.apple.com/account/resources/certificates/list" && \
		 echo "  2. Click + and select 'Developer ID Application'" && \
		 echo "  3. Follow the prompts to create and download" && \
		 echo "  4. Double-click the .cer file to install" && \
		 exit 1)
	@echo "✅ Developer ID certificate found"

setup-notary: ## Store notarization credentials in keychain (interactive)
	@echo "📝 Setting up notarization credentials..."
	@echo "You'll need:"
	@echo "  - Your Apple ID email"
	@echo "  - Team ID: HD35YQ72U4"
	@echo "  - An app-specific password from https://appleid.apple.com"
	@echo ""
	xcrun notarytool store-credentials $(NOTARY_PROFILE) --team-id HD35YQ72U4

notary-log: ## Show the log from the last notarization submission
	@echo "📋 Recent notarization submissions:"
	xcrun notarytool history --keychain-profile $(NOTARY_PROFILE)

# ============================================================================
# Homebrew Distribution
# ============================================================================

HOMEBREW_TAP_REPO = git@github.com:douinc/homebrew-tap.git
CASK_FILE = Casks/clicker-remote-receiver.rb

brew-sha256: ## Calculate SHA256 of the DMG for Homebrew cask
	@if [ ! -f ./build/$(DMG_NAME)-$(VERSION).dmg ]; then \
		echo "❌ DMG not found. Run 'make release-mac' first."; \
		exit 1; \
	fi
	@echo "SHA256 for Homebrew cask:"
	@shasum -a 256 ./build/$(DMG_NAME)-$(VERSION).dmg | awk '{print $$1}'

brew-update-cask: ## Update cask file with current version and SHA256
	@if [ ! -f ./build/$(DMG_NAME)-$(VERSION).dmg ]; then \
		echo "❌ DMG not found. Run 'make release-mac' first."; \
		exit 1; \
	fi
	@SHA=$$(shasum -a 256 ./build/$(DMG_NAME)-$(VERSION).dmg | awk '{print $$1}'); \
	echo "📝 Updating cask with version $(VERSION) and SHA256: $$SHA"; \
	sed -i '' "s/version \".*\"/version \"$(VERSION)\"/" $(CASK_FILE); \
	sed -i '' "s/sha256 .*/sha256 \"$$SHA\"/" $(CASK_FILE); \
	echo "✅ Cask updated: $(CASK_FILE)"

brew-publish: brew-update-cask ## Publish cask to homebrew-tap repository
	@echo "📤 Publishing to homebrew-tap..."
	@if [ ! -d ../homebrew-tap ]; then \
		echo "Cloning homebrew-tap..."; \
		git clone $(HOMEBREW_TAP_REPO) ../homebrew-tap; \
	fi
	@mkdir -p ../homebrew-tap/Casks
	@cp $(CASK_FILE) ../homebrew-tap/Casks/
	@cd ../homebrew-tap && \
		git add Casks/clicker-remote-receiver.rb && \
		git commit -m "Update clicker-remote-receiver to $(VERSION)" && \
		git push
	@echo "✅ Published to homebrew-tap!"
	@echo ""
	@echo "Users can now install with:"
	@echo "  brew tap douinc/tap"
	@echo "  brew install --cask clicker-remote-receiver"
