# Building & Distribution

This guide covers building for development and creating distribution builds.

## Development Builds

### Generate Xcode Project

Always regenerate after modifying `project.yml`:

```bash
xcodegen generate
```

### Mac App (Debug)

```bash
# Build
make build-mac

# Build and run
make run-mac
```

### iOS App (Debug)

```bash
# Simulator
make build-sim

# Physical device
make build-ios
make run-ios DEVICE_ID=<device-id>
```

## Distribution Builds

### iOS App Store

The iOS app is distributed via App Store Connect:

```bash
# Archive and upload to App Store Connect
make release-ios
```

This creates an archive and uploads to App Store Connect. Then:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select the build for TestFlight or App Review

### Mac DMG (GitHub Releases)

The Mac app is distributed as a signed and notarized DMG.

#### One-time Setup

1. **Create Developer ID Certificate**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
   - Create "Developer ID Application" certificate
   - Download and install in Keychain

2. **Create App-Specific Password**
   - Go to [appleid.apple.com](https://appleid.apple.com)
   - Security → App-Specific Passwords → Generate

3. **Store Notarization Credentials**
   ```bash
   make setup-notary
   # Enter your Apple ID and app-specific password
   ```

#### Release Workflow

```bash
# Verify signing setup
make check-signing

# Full release: build, sign, notarize, create DMG
make release-mac
```

The pipeline:
1. Build Release configuration with Hardened Runtime
2. Create DMG with app
3. Sign DMG with Developer ID
4. Submit to Apple for notarization
5. Staple notarization ticket to DMG

Output: `./build/ClickerRemoteReceiver-{version}.dmg`

#### Individual Commands

```bash
make dmg                    # Create unsigned DMG
make sign-dmg               # Sign DMG
make notarize               # Submit for notarization
make verify-signing         # Verify app signature
make verify-notarization    # Verify DMG is notarized
make notary-log             # Show notarization history
```

#### Create GitHub Release

```bash
gh release create v1.0 \
  ./build/ClickerRemoteReceiver-1.0.dmg \
  --title 'Clicker v1.0' \
  --notes 'Release notes here'
```

## Homebrew Distribution

The Homebrew cask formula is in `Casks/clicker-remote-receiver.rb`.

### Update Cask for New Release

1. Update `version` in the cask formula
2. Calculate SHA256 of the new DMG:
   ```bash
   shasum -a 256 ./build/ClickerRemoteReceiver-{version}.dmg
   ```
3. Update `sha256` in the formula
4. Commit and push

### Install from Tap

```bash
brew tap douinc/clicker https://github.com/douinc/clicker
brew install --cask clicker-remote-receiver
```

## Build Configuration

### project.yml Key Settings

```yaml
targets:
  ClickerMac:
    settings:
      base:
        ENABLE_HARDENED_RUNTIME: YES
      configs:
        Release:
          CODE_SIGN_STYLE: Manual
          CODE_SIGN_IDENTITY: "Developer ID Application"
          CODE_SIGN_INJECT_BASE_ENTITLEMENTS: NO
          OTHER_CODE_SIGN_FLAGS: "--timestamp"
```

### Why These Settings?

| Setting | Purpose |
|---------|---------|
| `ENABLE_HARDENED_RUNTIME` | Required for notarization |
| `CODE_SIGN_IDENTITY` | Use Developer ID (not Apple Distribution) |
| `CODE_SIGN_INJECT_BASE_ENTITLEMENTS` | Prevent debug entitlements |
| `--timestamp` | Required for notarization verification |

## Makefile Reference

```bash
make help                   # Show all commands

# Development
make generate               # Generate Xcode project
make build-mac              # Build Mac (debug)
make build-ios              # Build iOS for device
make build-sim              # Build iOS for simulator
make run-mac                # Build and run Mac
make run-ios                # Build, install, launch iOS

# Mac Distribution
make check-signing          # Verify Developer ID cert
make setup-notary           # Store notarization creds
make release-mac            # Full release pipeline
make dmg                    # Create DMG only
make sign-dmg               # Sign DMG
make notarize               # Notarize DMG
make verify-signing         # Verify signature
make verify-notarization    # Verify notarization

# iOS Distribution
make release-ios            # Archive and upload to ASC
```
