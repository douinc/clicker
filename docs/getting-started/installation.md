# Installation

## Mac App

### Option 1: Download Release

1. Download the latest `.dmg` from [GitHub Releases](https://github.com/douinc/clicker/releases)
2. Open the `.dmg` file
3. Drag `Clicker.app` to your Applications folder
4. Launch Clicker from Applications

!!! warning "macOS Gatekeeper"
    If macOS says the app "can't be opened because it is from an unidentified developer", right-click the app and select **Open**, then click **Open** in the dialog.

### Option 2: Build from Source

See [Building from Source](../development/building.md) for detailed instructions.

```bash
brew install xcodegen
git clone https://github.com/douinc/clicker.git
cd clicker
xcodegen generate
xcodebuild -scheme ClickerMac -configuration Release build
open ~/Library/Developer/Xcode/DerivedData/Clicker-*/Build/Products/Release/Clicker.app
```

## iPhone App

Download Clicker from the [App Store](https://apps.apple.com/app/clicker).

!!! info "Subscription Details"
    - **Free Trial**: 7 days with full access
    - **Subscription**: $4.99/year after trial
    - **Restore**: If you've subscribed before, tap "Restore Purchases"

## System Requirements

| Platform | Minimum Version |
|----------|-----------------|
| macOS | 14.0 (Sonoma) |
| iOS | 18.0 |

## Network Requirements

Both devices must be able to communicate directly:

- **Same WiFi network** — Most common setup
- **Bluetooth** — Works as fallback when WiFi is unavailable
- **Personal Hotspot** — iPhone hotspot with Mac connected works

!!! tip "No Internet Required"
    Clicker uses Apple's MultipeerConnectivity framework for peer-to-peer communication. No internet connection is needed — the devices communicate directly.
