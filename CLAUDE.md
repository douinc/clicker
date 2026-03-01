# Claude Code Instructions for Clicker

## Project Overview

This is a SwiftUI-based presentation remote system with three apps:
- **Mac App** (`ClickerRemoteReceiver` v1.2): Menu bar app that receives commands and sends keystrokes to presentation software
- **iPhone App** (`ClickerRemote` v1.6): Remote control with vertical slide navigation and presentation timer
- **Apple Watch App** (`ClickerWatch` v1.6): Companion watch app with gesture-based slide control using wrist flicks

## Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Networking**: MultipeerConnectivity (Mac↔iPhone), WatchConnectivity (iPhone↔Watch)
- **Build System**: XcodeGen + xcodebuild (CLI-based, no Xcode GUI required)
- **Platforms**: macOS 14.0+, iOS 18.0+, watchOS 10.0+
- **Design**: Apple liquid glass aesthetic (dark mode, translucent materials)

## Documentation

Use GitHub wiki as the main source of developer documentation. The documentation is in `./wiki/`.

## Project Structure

```
clicker/
├── MacApp/              # macOS menu bar receiver app
├── iPhoneApp/           # iOS remote control app
├── WatchApp/            # Apple Watch companion app
├── Shared/              # Shared code (RemoteCommand.swift)
├── wiki/                # GitHub wiki documentation
├── public/              # Logos and screenshots
├── build/               # Build artifacts
├── .github/             # GitHub Actions workflows
├── project.yml          # XcodeGen project configuration
└── justfile             # Build and deployment commands
```

## Build Commands

Reference @justfile

## Distribution

### iOS and Apple Watch App (App Store)

The iOS and companion Apple Watch app is distributed via the App Store.

Then go to App Store Connect to select the build for TestFlight/review.

### Mac App (GitHub DMG - Signed & Notarized)

The Mac app is distributed as a signed and notarized DMG via GitHub Releases.

The full pipeline:
1. Build Release configuration with Hardened Runtime
2. Create DMG with custom icon
3. Sign DMG with Developer ID
4. Submit to Apple for notarization
5. Staple notarization ticket to DMG

The notarized DMG is created at `./build/ClickerRemoteReceiver-{version}.dmg`.

**Create GitHub release and update Homebrew tap:**
```bash
# Create the release
gh release create v1.2 ./build/ClickerRemoteReceiver-1.2.dmg --title 'Clicker v1.2' --notes 'Release notes'

# Trigger homebrew-tap update (auto-calculates SHA256)
just update-tap
```

The `update-tap` command triggers a GitHub Action in `douinc/homebrew-tap` that:
1. Downloads the DMG from the release
2. Calculates the SHA256 hash
3. Updates the Cask formula
4. Commits and pushes automatically

## Key Architecture Decisions

### XcodeGen Configuration
- `project.yml` defines all three targets (Mac, iOS, Watch) in a single unified project
- Info.plist keys are specified in `info.properties` section (not just `info.path`)
- This is critical for Multipeer Connectivity which requires `NSBonjourServices` and `NSLocalNetworkUsageDescription`
- The Watch app is embedded in the iOS target via `dependencies`

### Multipeer Connectivity (Mac↔iPhone)
- Service type: `_clickerremote._tcp` and `_clickerremote._udp`
- Mac acts as advertiser, iPhone acts as browser
- Commands are sent as JSON-encoded `RemoteCommand` enum values
- Shared config in `Shared/RemoteCommand.swift`

### WatchConnectivity (iPhone↔Watch)
- iPhone relays Watch commands to Mac via MultipeerConnectivity
- Watch sends commands using `WCSession.default.sendMessage`

### Mac App Specifics
- App name: `ClickerRemoteReceiver` (distributed via GitHub DMG)
- Bundle ID: `com.dou.clicker-mac`
- `LSUIElement: true` makes it a menu bar app (no Dock icon)
- Requires Accessibility permission for CGEvent keystroke injection
- Uses `CGEvent` API to send keyboard events to frontmost app

### iPhone App Specifics
- App name: `ClickerRemote` (distributed via App Store)
- Bundle ID: `com.dou.clicker-ios`
- Vertical button layout: Previous (chevron up) at top, Next (chevron down) at bottom
- Liquid glass aesthetic using `.ultraThinMaterial` for frosted glass effect
- Dark mode only (`.preferredColorScheme(.dark)`) for stage visibility
- Timer uses `UIImpactFeedbackGenerator` for haptic feedback
- In-App Purchase capability for subscription/trial

### Apple Watch App Specifics
- App name: `ClickerWatch` (embedded in iOS app, distributed via App Store)
- Bundle ID: `com.dou.clicker-ios.watchkitapp`
- Gesture detection via CoreMotion (wrist flick rotation rate on x-axis)
- Gesture lock: 3-second lockout after gesture to prevent accidental triggers
- Gesture inversion: option to swap flick direction mapping
- Auto-toggle: gesture activation follows wrist raise/lower
- HealthKit workout session keeps app active during presentations
- Extended WatchKit session for background operation

## Development Team

Team ID: `HD35YQ72U4` (DOU Inc.)

## When Modifying This Project

1. Edit Swift source files directly
2. If changing build settings, targets, or Info.plist keys, edit `project.yml`
3. Run `just generate` after modifying `project.yml` to regenerate the Xcode project

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
