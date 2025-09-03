//
//  AccessibilityGate.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox

enum AccessibilityGate {
    static func ensurePermission() -> Bool {
        // First check if we already have permission
        if AXIsProcessTrusted() {
            return true
        }
        
        // Try to trigger the permission request by actually using accessibility
        triggerAccessibilityRequest()
        
        // Check with prompt option
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
    
    static func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private static func triggerAccessibilityRequest() {
        // Try to access the focused element to trigger permission request
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(
            system,
            kAXFocusedUIElementAttribute as CFString,
            &focused
        )
        
        // Also try to post a dummy event to trigger permission
        let src = CGEventSource(stateID: .combinedSessionState)
        if let dummyEvent = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(0x76), keyDown: true) {
            // Don't actually post it, just creating it can trigger the permission check
            _ = dummyEvent
        }
    }
}
