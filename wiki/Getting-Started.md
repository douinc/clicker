# Getting Started

This guide covers setting up your development environment to build ClickerRemote from source.

## Prerequisites

| Requirement | Version | Installation |
|-------------|---------|--------------|
| macOS | 14.0+ (Sonoma) | — |
| Xcode | 16.0+ | App Store or [developer.apple.com](https://developer.apple.com/xcode/) |
| XcodeGen | Latest | `brew install xcodegen` |
| Apple Developer Account | — | Required for device deployment |

## Clone & Setup

```bash
# Clone the repository
git clone https://github.com/douinc/clicker.git
cd clicker

# Generate Xcode project
xcodegen generate

# Open in Xcode (optional)
open Clicker.xcodeproj
```

## Build Mac App

```bash
# Debug build
make build-mac

# Or directly with xcodebuild
xcodebuild -scheme ClickerMac -configuration Debug build

# Run the app
make run-mac
```

The Mac app will appear in your menu bar.

## Build iOS App

### Simulator

```bash
make build-sim

# Or with specific simulator
xcodebuild -scheme ClickeriOS \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  build
```

### Physical Device

1. Connect your iPhone via USB
2. List available devices:
   ```bash
   xcrun devicectl list devices
   ```
3. Build and install:
   ```bash
   make run-ios DEVICE_ID=<your-device-id>
   ```

## Development Team Setup

If you see "Signing requires development team" errors:

1. Open `project.yml`
2. Replace `HD35YQ72U4` with your Team ID
3. Regenerate: `xcodegen generate`

Find your Team ID:
```bash
security find-identity -v -p codesigning | grep "Developer ID"
```

## Next Steps

- [[Architecture]] — Understand how the apps work together
- [[Building]] — Learn about distribution builds
- [[API-Reference]] — Explore the codebase
