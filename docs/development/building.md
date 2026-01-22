# Building from Source

This guide covers building Clicker from source code using command-line tools.

## Prerequisites

| Requirement | Version | Installation |
|-------------|---------|--------------|
| macOS | 14.0+ (Sonoma) | — |
| Xcode | 16.0+ | App Store or [developer.apple.com](https://developer.apple.com/xcode/) |
| XcodeGen | Latest | `brew install xcodegen` |
| Apple Developer Account | — | Required for code signing |

### Install XcodeGen

```bash
brew install xcodegen
```

XcodeGen generates the Xcode project from `project.yml`, keeping build configuration in version control.

---

## Quick Build

```bash
# Clone the repository
git clone https://github.com/douinc/clicker.git
cd clicker

# Generate Xcode project
xcodegen generate

# Build Mac app
xcodebuild -scheme ClickerMac -configuration Release build

# Run Mac app
open ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Release/Clicker.app
```

---

## Detailed Build Instructions

### Generate Xcode Project

```bash
xcodegen generate
```

This reads `project.yml` and generates `Clicker.xcodeproj`. Always run this after:

- Cloning the repository
- Pulling changes that modify `project.yml`
- Changing build settings

!!! warning "Don't Edit .xcodeproj"
    The Xcode project is generated. Any manual changes will be lost when you run `xcodegen generate`.

### Build Mac App

=== "Debug Build"

    ```bash
    xcodebuild -scheme ClickerMac build
    ```

=== "Release Build"

    ```bash
    xcodebuild -scheme ClickerMac -configuration Release build
    ```

=== "Clean Build"

    ```bash
    xcodebuild -scheme ClickerMac clean build
    ```

**Output location:**
```
~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Debug/Clicker.app
~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Release/Clicker.app
```

### Build iOS App

=== "Simulator"

    ```bash
    xcodebuild -scheme ClickeriOS \
      -destination 'generic/platform=iOS Simulator' \
      build
    ```

=== "Specific Simulator"

    ```bash
    xcodebuild -scheme ClickeriOS \
      -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
      build
    ```

=== "Physical Device"

    ```bash
    # Find your device ID
    xcrun devicectl list devices

    # Build for device
    xcodebuild -scheme ClickeriOS \
      -destination 'id=YOUR_DEVICE_ID' \
      build
    ```

### Install on iPhone

```bash
# Find device ID
xcrun devicectl list devices

# Install the app
xcrun devicectl device install app \
  --device YOUR_DEVICE_ID \
  ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Debug-iphoneos/Clicker.app

# Launch the app
xcrun devicectl device process launch \
  --device YOUR_DEVICE_ID \
  com.dou.clicker-ios
```

---

## Code Signing

### Find Your Team ID

```bash
security find-identity -v -p codesigning | grep "Apple Development"
```

The Team ID is the 10-character code in parentheses, e.g., `HD35YQ72U4`.

### Configure Signing

Edit `project.yml` and update the `DEVELOPMENT_TEAM`:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: YOUR_TEAM_ID  # (1)!
```

1. Replace with your actual Team ID

Then regenerate the project:

```bash
xcodegen generate
```

---

## Build Both Apps in Parallel

```bash
xcodegen generate

# Build both simultaneously
xcodebuild -scheme ClickerMac build &
xcodebuild -scheme ClickeriOS -destination 'generic/platform=iOS Simulator' build &
wait

echo "Both builds complete"
```

---

## Useful Commands

### List Available Schemes

```bash
xcodebuild -project Clicker.xcodeproj -list
```

### List Build Destinations

```bash
xcodebuild -scheme ClickeriOS -showdestinations
```

### List Connected Devices

```bash
xcrun devicectl list devices
```

### List Available Simulators

```bash
xcrun simctl list devices available
```

### Check Built Info.plist

```bash
find ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products \
  -name "Info.plist" \
  -exec plutil -p {} \;
```

---

## Common Build Errors

### "Signing requires a development team"

Add your Team ID to `project.yml`:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: YOUR_TEAM_ID
```

Then run `xcodegen generate`.

### "Unable to find destination"

List available destinations and use an exact match:

```bash
xcodebuild -scheme ClickeriOS -showdestinations
```

### "No such module" errors

Clean and rebuild:

```bash
xcodebuild -scheme ClickeriOS clean
xcodebuild -scheme ClickeriOS build
```

### MultipeerConnectivity not working

Ensure `project.yml` has the required Info.plist entries under `info.properties`:

```yaml
info:
  properties:
    NSBonjourServices:
      - _clicker._tcp
      - _clicker._udp
    NSLocalNetworkUsageDescription: "..."
```
