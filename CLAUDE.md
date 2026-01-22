# Claude Code Instructions for Clicker

## Project Overview

This is a SwiftUI-based presentation remote system with two apps:
- **Mac App**: Menu bar app that receives commands and sends keystrokes to presentation software
- **iPhone App**: Remote control with vertical slide navigation and presentation timer

## Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Networking**: MultipeerConnectivity framework
- **Build System**: XcodeGen + xcodebuild (CLI-based, no Xcode GUI required)
- **Platforms**: macOS 14.0+, iOS 18.0+
- **Design**: Apple liquid glass aesthetic (dark mode, translucent materials)

## Project Structure

```
clicker/
├── project.yml          # XcodeGen config - defines both targets
├── Shared/              # Code shared between both apps
│   └── RemoteCommand.swift
├── MacApp/              # macOS menu bar app
│   ├── PresentationRemoteMacApp.swift   # Main app + SwiftUI views
│   ├── MacConnectionManager.swift       # Multipeer session handling
│   ├── KeystrokeSender.swift           # CGEvent keystroke injection
│   ├── Info.plist                       # Base plist (merged by XcodeGen)
│   └── ClickerMac.entitlements
├── iPhoneApp/           # iOS remote control app
│   ├── PresentationRemoteiPhoneApp.swift  # Main app + all views
│   ├── iPhoneConnectionManager.swift      # Multipeer session handling
│   ├── PresentationTimer.swift           # Timer with haptic feedback
│   └── Info.plist                        # Base plist (merged by XcodeGen)
└── Clicker.xcodeproj/                    # Generated - do not edit directly
```

## Build Commands

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build Mac app
xcodebuild -scheme ClickerMac build

# Build iOS app (simulator)
xcodebuild -scheme ClickeriOS -destination 'generic/platform=iOS Simulator' build

# Build iOS app (physical device)
xcodebuild -scheme ClickeriOS -destination 'id=XCODE_DEVICE_ID' build

# Install on iPhone
xcrun devicectl device install app --device XCODE_DEVICE_ID ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Debug-iphoneos/ClickerRemote.app

# Launch on iPhone
xcrun devicectl device process launch --device DEVICECTL_ID com.dou.clicker-ios

# Run Mac app
open ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Debug/ClickerRemoteReceiver.app
```

## Distribution

### iOS App (App Store)
The iOS app is distributed via the App Store. Use the following commands:
```bash
make release-ios    # Archive and upload to App Store Connect
```
Then go to App Store Connect to select the build for TestFlight/review.

### Mac App (GitHub DMG - Signed & Notarized)
The Mac app is distributed as a signed and notarized DMG via GitHub Releases.

**One-time setup:**
1. Create a Developer ID Application certificate at [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Create an app-specific password at [appleid.apple.com](https://appleid.apple.com)
3. Run `make setup-notary` to store credentials in keychain

**Release workflow:**
```bash
make check-signing      # Verify Developer ID certificate is installed
make release-mac        # Build, sign, notarize, and create DMG
```

This runs through the full pipeline:
1. Build Release configuration with Hardened Runtime
2. Create DMG with custom icon
3. Sign DMG with Developer ID
4. Submit to Apple for notarization
5. Staple notarization ticket to DMG

The notarized DMG is created at `./build/ClickerRemoteReceiver-{version}.dmg`.

**Individual commands:**
```bash
make dmg                  # Create unsigned DMG
make sign-dmg             # Sign DMG with Developer ID
make notarize             # Submit for notarization and staple
make verify-signing       # Verify app signature
make verify-notarization  # Verify DMG is notarized
make notary-log           # Show recent notarization submissions
```

**Create GitHub release:**
```bash
gh release create v1.0 ./build/ClickerRemoteReceiver-1.0.dmg --title 'Clicker v1.0' --notes 'Release notes'
```

## Key Architecture Decisions

### XcodeGen Configuration
- `project.yml` defines both targets in a single unified project
- Info.plist keys are specified in `info.properties` section (not just `info.path`)
- This is critical for Multipeer Connectivity which requires `NSBonjourServices` and `NSLocalNetworkUsageDescription`

### Multipeer Connectivity
- Service type: `_clicker._tcp` and `_clicker._udp`
- Mac acts as advertiser, iPhone acts as browser
- Commands are sent as JSON-encoded `RemoteCommand` enum values

### Mac App Specifics
- App name: `ClickerRemoteReceiver` (distributed via GitHub DMG)
- `LSUIElement: true` makes it a menu bar app (no Dock icon)
- Requires Accessibility permission for CGEvent keystroke injection
- Uses `CGEvent` API to send keyboard events to frontmost app

### iPhone App Specifics
- App name: `ClickerRemote` (distributed via App Store)
- Vertical button layout: Previous (chevron up) at top, Next (chevron down) at bottom
- Liquid glass aesthetic using `.ultraThinMaterial` for frosted glass effect
- Dark mode only (`.preferredColorScheme(.dark)`) for stage visibility
- Timer uses `UIImpactFeedbackGenerator` for haptic feedback
- Uses modern SwiftUI with `presentationDetents` for sheet sizing

## Common Issues & Solutions

### Notarization fails with "Invalid" status
Check the notarization log with `xcrun notarytool log <submission-id> --keychain-profile notarytool-profile`. Common causes:

1. **Wrong certificate**: Using "Apple Distribution" instead of "Developer ID Application"
2. **Missing timestamp**: Signature needs `--timestamp` flag
3. **Debug entitlement**: `com.apple.security.get-task-allow` is forbidden

The fix requires these Release-only settings in `project.yml`:
```yaml
configs:
  Release:
    CODE_SIGN_STYLE: Manual
    CODE_SIGN_IDENTITY: "Developer ID Application"
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS: NO
    OTHER_CODE_SIGN_FLAGS: "--timestamp"
```

### "Signing requires development team"
Add `DEVELOPMENT_TEAM: YOUR_TEAM_ID` to `project.yml` under the target's settings, then run `xcodegen generate`.

### "Unable to find destination"
Specify OS version: `-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'`

### Multipeer not connecting
Ensure `NSBonjourServices` and `NSLocalNetworkUsageDescription` are in `project.yml` under `info.properties`, not just in the source Info.plist files.

### SwiftUI Section syntax error
When using `Section` with both header and footer, use:
```swift
Section {
    // content
} header: {
    Text("Header")
} footer: {
    Text("Footer")
}
```
NOT: `Section("Header") { ... } footer: { ... }`

## Bundle Identifiers

- Mac (ClickerRemoteReceiver): `com.dou.clicker-mac`
- iOS (ClickerRemote): `com.dou.clicker-ios`

## Development Team

Team ID: `HD35YQ72U4` (DOU Inc.)

## When Modifying This Project

1. Edit Swift source files directly
2. If changing build settings, targets, or Info.plist keys, edit `project.yml`
3. After editing `project.yml`, always run `xcodegen generate`
4. Do NOT edit `Clicker.xcodeproj` directly - it's generated

## Makefile Commands

```bash
make help               # Show all available commands
make generate           # Generate Xcode project from project.yml
make build-mac          # Build Mac app (debug)
make build-ios          # Build iOS app for device
make build-sim          # Build iOS app for simulator
make run-mac            # Build and run Mac app
make run-ios            # Build, install, and launch on device

# Mac Distribution (Signed + Notarized)
make check-signing      # Verify Developer ID certificate exists
make setup-notary       # Store notarization credentials (one-time)
make release-mac        # Full pipeline: build, sign, notarize, DMG
make verify-signing     # Verify app code signature
make verify-notarization # Verify DMG is notarized
make notary-log         # Show recent notarization submissions

# iOS Distribution (App Store)
make release-ios        # Archive and upload iOS to App Store Connect
```

## Useful Debugging Commands

```bash
# Check built Info.plist contents
find ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products -name "Info.plist" -exec plutil -p {} \;

# List available schemes
xcodebuild -project Clicker.xcodeproj -list

# Show build destinations
xcodebuild -scheme ClickeriOS -showdestinations

# Find Team ID
security find-identity -v -p codesigning

# List connected iOS devices
xcrun devicectl list devices

# List available simulators
xcrun simctl list devices available
```
