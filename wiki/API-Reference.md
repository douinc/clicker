# API Reference

This reference documents the key classes and protocols in the codebase.

## Shared Code

### RemoteCommand

The command protocol between iPhone and Mac:

```swift
// Shared/RemoteCommand.swift
enum RemoteCommand: String, Codable {
    case next = "next"
    case previous = "previous"
}
```

**Wire Format**: JSON encoded as `{"rawValue": "next"}`

---

## Mac App

### MacConnectionManager

Handles MultipeerConnectivity on the Mac side.

```swift
@MainActor
class MacConnectionManager: NSObject, ObservableObject {
    @Published var isConnected: Bool
    @Published var connectedDeviceName: String?

    func startAdvertising()
    func stopAdvertising()
}
```

| Property | Type | Description |
|----------|------|-------------|
| `isConnected` | `Bool` | True when iPhone is connected |
| `connectedDeviceName` | `String?` | Name of connected iPhone |

**Protocols Implemented**:
- `MCNearbyServiceAdvertiserDelegate`
- `MCSessionDelegate`

### KeystrokeSender

Injects keyboard events into the system.

```swift
class KeystrokeSender {
    static let shared: KeystrokeSender

    func sendNext()      // Sends Down Arrow (key code 125)
    func sendPrevious()  // Sends Up Arrow (key code 126)
}
```

**Requirements**: Accessibility permission

### Key Codes Reference

| Action | Key Code | Key |
|--------|----------|-----|
| Next Slide | 125 | ↓ Down Arrow |
| Previous Slide | 126 | ↑ Up Arrow |

---

## iPhone App

### iPhoneConnectionManager

Handles MultipeerConnectivity on the iPhone side.

```swift
@MainActor
class iPhoneConnectionManager: NSObject, ObservableObject {
    @Published var isConnected: Bool
    @Published var availablePeers: [MCPeerID]
    @Published var connectedPeerName: String?

    func startBrowsing()
    func stopBrowsing()
    func connect(to peer: MCPeerID)
    func disconnect()
    func sendCommand(_ command: RemoteCommand)
}
```

| Property | Type | Description |
|----------|------|-------------|
| `isConnected` | `Bool` | True when connected to Mac |
| `availablePeers` | `[MCPeerID]` | Discovered Mac devices |
| `connectedPeerName` | `String?` | Name of connected Mac |

**Protocols Implemented**:
- `MCNearbyServiceBrowserDelegate`
- `MCSessionDelegate`

### PresentationTimer

Manages the presentation timer with haptic feedback.

```swift
@MainActor
class PresentationTimer: ObservableObject {
    @Published var isRunning: Bool
    @Published var elapsedTime: TimeInterval
    @Published var duration: TimeInterval
    @Published var hapticInterval: TimeInterval

    var progress: Double { elapsedTime / duration }

    func start()
    func pause()
    func reset()
}
```

| Property | Type | Description |
|----------|------|-------------|
| `isRunning` | `Bool` | Timer active state |
| `elapsedTime` | `TimeInterval` | Seconds elapsed |
| `duration` | `TimeInterval` | Total duration (0 = unlimited) |
| `hapticInterval` | `TimeInterval` | Seconds between haptic alerts |
| `progress` | `Double` | 0.0 to 1.0 progress value |

**Duration Presets**: 5, 10, 15, 20, 30 minutes, unlimited

**Haptic Intervals**: 30s, 1m, 2m, 5m

### SubscriptionManager

Handles StoreKit 2 subscription logic.

```swift
@Observable
class SubscriptionManager {
    var status: SubscriptionStatus

    func checkEntitlements() async
    func purchase(_ product: Product) async throws
    func restorePurchases() async
}
```

### SubscriptionStatus

```swift
enum SubscriptionStatus {
    case notDetermined
    case trial(daysRemaining: Int)
    case subscribed(expiresAt: Date?)
    case expired
}
```

### TrialTracker

Manages the 7-day trial period via Keychain.

```swift
class TrialTracker {
    var hasStartedTrial: Bool
    var trialStartDate: Date?
    var daysRemaining: Int
    var isTrialExpired: Bool

    func startTrial()
}
```

**Storage**: Keychain (survives app reinstall)

---

## SwiftUI Views

### Mac App Views

| View | Description |
|------|-------------|
| `ContentView` | Main menu bar content |
| `ConnectionStatusView` | Shows connection state |

### iPhone App Views

| View | Description |
|------|-------------|
| `SubscriptionGateView` | Entry point, checks subscription |
| `ContentView` | Main container |
| `ConnectionView` | Device discovery and connection |
| `RemoteControlView` | Slide navigation buttons |
| `TimerView` | Presentation timer |
| `TimerSettingsView` | Timer configuration sheet |
| `PaywallView` | Subscription purchase UI |

---

## Bundle Identifiers

| App | Bundle ID |
|-----|-----------|
| ClickerRemoteReceiver (Mac) | `com.dou.clicker-mac` |
| ClickerRemote (iOS) | `com.dou.clicker-ios` |

## StoreKit Product IDs

| Product | ID |
|---------|-----|
| Annual Subscription | `com.dou.clicker.annual` |
