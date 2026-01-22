# Extending Clicker

This guide covers how to add new features and commands to Clicker.

## Adding New Commands

### 1. Define the Command

Add a new case to `RemoteCommand` in `Shared/RemoteCommand.swift`:

```swift
enum RemoteCommand: String, Codable {
    case next = "next"
    case previous = "previous"
    case blackScreen = "black"      // New!
    case whiteScreen = "white"      // New!
    case startPresentation = "start"  // New!

    var keyCode: UInt16 {
        switch self {
        case .next: return 124          // Right Arrow
        case .previous: return 123      // Left Arrow
        case .blackScreen: return 11    // B key
        case .whiteScreen: return 13    // W key
        case .startPresentation: return 36  // Return key
        }
    }
}
```

### 2. Add UI in iPhone App

Add a button to trigger the command in `iPhoneApp/PresentationRemoteiPhoneApp.swift`:

```swift
// In RemoteControlView or a new toolbar
Button {
    connectionManager.sendCommand(.blackScreen)
} label: {
    Label("Black", systemImage: "rectangle.fill")
}
```

### 3. Test

1. Build both apps
2. Connect iPhone to Mac
3. Tap the new button
4. Verify the keystroke is received

!!! tip "No Mac Changes Needed"
    The Mac app automatically handles any `RemoteCommand` — it just reads the `keyCode` and sends it.

---

## Adding Modifier Keys

To send keystrokes with modifiers (Shift, Command, etc.), modify `KeystrokeSender`:

```swift
func sendKeystroke(_ keyCode: UInt16, modifiers: CGEventFlags = []) {
    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = modifiers  // Add modifiers
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    keyUp?.flags = modifiers
    keyUp?.post(tap: .cghidEventTap)
}
```

Usage:

```swift
// Command+Shift+F for fullscreen
sendKeystroke(3, modifiers: [.maskCommand, .maskShift])
```

### Common Modifier Flags

| Modifier | Flag |
|----------|------|
| Shift | `.maskShift` |
| Control | `.maskControl` |
| Option/Alt | `.maskAlternate` |
| Command | `.maskCommand` |

---

## Adding Timer Features

### Custom Haptic Patterns

Modify `PresentationTimer` to add new haptic patterns:

```swift
func customHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()

    // Pattern: tap-tap-pause-tap
    generator.impactOccurred()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        generator.impactOccurred()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        generator.impactOccurred()
    }
}
```

### New Timer Presets

Add presets in `TimerConfig`:

```swift
static let durationPresets: [(name: String, duration: TimeInterval?)] = [
    ("No Limit", nil),
    ("3 minutes", 180),   // New!
    ("5 minutes", 300),
    ("10 minutes", 600),
    // ...
]
```

---

## Adding New Screens

### SwiftUI Pattern

Follow the existing pattern for new views:

```swift
struct NewFeatureView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager

    var body: some View {
        VStack {
            // Your UI here
        }
        .background(.ultraThinMaterial)  // Liquid glass style
        .preferredColorScheme(.dark)     // Dark mode
    }
}
```

### Navigation

Add to the view hierarchy in `ContentView`:

```swift
var body: some View {
    if connectionManager.isConnected {
        RemoteControlView(...)
    } else if showNewFeature {
        NewFeatureView(...)
    } else {
        ConnectionView(...)
    }
}
```

---

## Subscription Features

### Gating Features

Use `SubscriptionManager` to gate premium features:

```swift
struct PremiumFeatureView: View {
    @Environment(SubscriptionManager.self) var subscriptionManager

    var body: some View {
        if subscriptionManager.hasAccess {
            // Premium content
        } else {
            // Upgrade prompt
            PaywallView()
        }
    }
}
```

### Adding Products

1. Add product ID to `Products.storekit` for testing
2. Create the product in App Store Connect
3. Update `SubscriptionManager.productIDs`

---

## Testing Changes

### StoreKit Testing

Use the StoreKit configuration file for local testing:

1. In Xcode, select scheme → Edit Scheme
2. Under Options, set StoreKit Configuration to `Products.storekit`
3. Build and run — purchases use sandbox

### MultipeerConnectivity Testing

Test on physical devices when possible. Simulator limitations:

- ✅ Mac app works in simulator
- ⚠️ iOS simulator has limited MultipeerConnectivity support
- ✅ Best to test iPhone app on physical device

---

## Code Style

### SwiftUI Conventions

```swift
// Use @StateObject for owned objects
@StateObject private var viewModel = ViewModel()

// Use @ObservedObject for injected objects
@ObservedObject var connectionManager: ConnectionManager

// Use @Environment for app-wide state
@Environment(SubscriptionManager.self) var subscriptionManager
```

### File Organization

```swift
// MARK: - View Name
struct MyView: View {
    // MARK: Properties
    @State private var value = false

    // MARK: Body
    var body: some View { ... }

    // MARK: Subviews
    private var header: some View { ... }

    // MARK: Methods
    private func handleTap() { ... }
}

// MARK: - Preview
#Preview {
    MyView()
}
```
