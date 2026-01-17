import Foundation
import CoreGraphics
import AppKit

// MARK: - Keystroke Sender
class KeystrokeSender {
    
    static let shared = KeystrokeSender()
    
    private init() {}
    
    // MARK: - Check Accessibility Permissions
    var hasAccessibilityPermission: Bool {
        // Check if we have accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func requestAccessibilityPermission() {
        // This will prompt the user to grant permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Send Keystroke
    func sendCommand(_ command: RemoteCommand) {
        guard hasAccessibilityPermission else {
            print("⚠️ No accessibility permission! Requesting...")
            requestAccessibilityPermission()
            return
        }
        
        sendKeyPress(keyCode: command.keyCode)
        print("⌨️ Sent keystroke for: \(command.rawValue)")
    }
    
    private func sendKeyPress(keyCode: UInt16, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down event
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        
        // Small delay between key down and key up
        usleep(10000) // 10ms
        
        // Key up event
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Convenience Methods
    func nextSlide() {
        sendCommand(.nextSlide)
    }
    
    func previousSlide() {
        sendCommand(.previousSlide)
    }
    
    func startPresentation() {
        // Command + Shift + Return for PowerPoint slideshow from beginning
        // Or just Return for Keynote
        sendCommand(.startPresentation)
    }
    
    func endPresentation() {
        sendCommand(.endPresentation)
    }
}

// MARK: - Key Code Reference
/*
 Common Key Codes:
 - 123: Left Arrow
 - 124: Right Arrow
 - 125: Down Arrow
 - 126: Up Arrow
 - 36:  Return
 - 53:  Escape
 - 49:  Space
 - 11:  B (black screen in PPT)
 - 47:  W (white screen in PPT)
 
 For full list, see: Events.h in Carbon framework
 */
