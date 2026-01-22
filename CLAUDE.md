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

### Mac App (GitHub DMG)
The Mac app is distributed as a DMG via GitHub Releases (not the Mac App Store).
```bash
make dmg            # Create DMG with custom icon
make release-mac    # Create DMG and show GitHub release instructions
```
The DMG is created at `./build/ClickerRemoteReceiver-{version}.dmg` with the app logo as the volume icon.

To create a GitHub release:
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
make help           # Show all available commands
make generate       # Generate Xcode project from project.yml
make build-mac      # Build Mac app (debug)
make build-ios      # Build iOS app for device
make build-sim      # Build iOS app for simulator
make run-mac        # Build and run Mac app
make run-ios        # Build, install, and launch on device
make dmg            # Create DMG for Mac distribution
make release-mac    # Create DMG with GitHub release instructions
make release-ios    # Archive and upload iOS to App Store Connect
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
