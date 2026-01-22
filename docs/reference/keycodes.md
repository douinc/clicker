# Key Codes Reference

macOS virtual key codes for use with `CGEvent`.

## Navigation Keys

| Key | Code | Common Use |
|-----|------|------------|
| Left Arrow | `123` | Previous slide |
| Right Arrow | `124` | Next slide |
| Up Arrow | `126` | Previous slide (alternative) |
| Down Arrow | `125` | Next slide (alternative) |
| Page Up | `116` | Previous slide |
| Page Down | `121` | Next slide |
| Home | `115` | First slide |
| End | `119` | Last slide |

## Function Keys

| Key | Code | Common Use |
|-----|------|------------|
| Escape | `53` | End presentation, exit fullscreen |
| Return | `36` | Start presentation, confirm |
| Space | `49` | Next slide, play/pause |
| Tab | `48` | Next field |
| Delete | `51` | Delete, back |
| F5 | `96` | Start presentation (PowerPoint) |

## Letter Keys

| Key | Code | Common Use |
|-----|------|------------|
| B | `11` | Black screen (PowerPoint/Keynote) |
| W | `13` | White screen (PowerPoint/Keynote) |
| P | `35` | Pointer/Pen tool |
| E | `14` | Eraser tool |
| S | `1` | Stop/Start |
| Q | `12` | Quit |

## Number Keys

| Key | Code |
|-----|------|
| 1 | `18` |
| 2 | `19` |
| 3 | `20` |
| 4 | `21` |
| 5 | `23` |
| 6 | `22` |
| 7 | `26` |
| 8 | `28` |
| 9 | `25` |
| 0 | `29` |

## Modifier Keys

These are used with `CGEventFlags`, not as standalone key codes:

| Modifier | Flag | Code (if needed) |
|----------|------|------------------|
| Shift | `.maskShift` | `56` (left), `60` (right) |
| Control | `.maskControl` | `59` (left), `62` (right) |
| Option | `.maskAlternate` | `58` (left), `61` (right) |
| Command | `.maskCommand` | `55` (left), `54` (right) |
| Caps Lock | `.maskAlphaShift` | `57` |
| Function | `.maskSecondaryFn` | `63` |

---

## Application-Specific Shortcuts

### Apple Keynote

| Action | Key | Code |
|--------|-----|------|
| Start presentation | Return | `36` |
| End presentation | Escape | `53` |
| Next slide | Right Arrow / Space | `124` / `49` |
| Previous slide | Left Arrow | `123` |
| Black screen | B | `11` |
| White screen | W | `13` |
| Show presenter notes | — | Use display settings |

### Microsoft PowerPoint

| Action | Key | Code |
|--------|-----|------|
| Start presentation | F5 | `96` |
| Start from current | Shift+F5 | `96` + `.maskShift` |
| End presentation | Escape | `53` |
| Next slide | Right Arrow / Space / N | `124` / `49` / `45` |
| Previous slide | Left Arrow / P | `123` / `35` |
| Black screen | B / Period | `11` / `47` |
| White screen | W / Comma | `13` / `43` |
| Go to slide N | N + Return | Number + `36` |

### Google Slides

| Action | Key | Code |
|--------|-----|------|
| Start presentation | Cmd+Return | `36` + `.maskCommand` |
| End presentation | Escape | `53` |
| Next slide | Right Arrow / Space | `124` / `49` |
| Previous slide | Left Arrow | `123` |

---

## Using Key Codes in Clicker

### Basic Keystroke

```swift
// In RemoteCommand.swift
case myCommand = "my_command"

var keyCode: UInt16 {
    switch self {
    case .myCommand: return 11  // B key
    // ...
    }
}
```

### With Modifiers

Modify `KeystrokeSender.swift`:

```swift
func sendKeystroke(_ keyCode: UInt16, modifiers: CGEventFlags = []) {
    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = modifiers
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    keyUp?.post(tap: .cghidEventTap)
}

// Usage:
sendKeystroke(96, modifiers: .maskShift)  // Shift+F5
```

---

## Finding Key Codes

To find the key code for any key:

1. Use Apple's **Key Codes** app (free on App Store)
2. Or use this Swift snippet:

```swift
import Cocoa

NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    print("Key: \(event.characters ?? "") Code: \(event.keyCode)")
}
```

Run in a macOS app to see key codes as you type.
