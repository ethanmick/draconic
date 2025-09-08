//
//  TextInjector.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox

enum TextInjector {
    static func inject(text: String, into context: FrontContext) -> Bool {
        // Check if we have accessibility permissions
        guard AccessibilityGate.checkPermission() else {
            // Fallback: just copy to clipboard
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(text, forType: .string)
            return false
        }
        
        // Bring original app forward again
        context.app.activate(options: [.activateIgnoringOtherApps])
        
        // Small delay to let app win key-window arbitration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if tryAXSetValue(text, context: context) { return }
            if pasteViaCommandV(text, targetApp: context.app) { return }
            typeCharacters(text)
        }
        
        return true
    }
    
    // 1) Try setting value via AX (replaces entire field if allowed)
    private static func tryAXSetValue(_ text: String, context: FrontContext) -> Bool {
        guard let el = context.focusedElement else { return false }
        let status = AXUIElementSetAttributeValue(el, kAXValueAttribute as CFString, text as CFTypeRef)
        return status == .success
    }
    
    // 2) Pasteboard + synthetic ⌘V (keeps dictated text on clipboard)
    private static func pasteViaCommandV(_ text: String, targetApp: NSRunningApplication) -> Bool {
        let pb = NSPasteboard.general
        
        // Set our text to clipboard and leave it there
        pb.clearContents()
        pb.setString(text, forType: .string)
        
        // Send ⌘V
        let src = CGEventSource(stateID: .combinedSessionState)
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        vUp?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        return true
    }
    
    // 3) Last resort: synthesize keystrokes (ASCII-safe)
    private static func typeCharacters(_ text: String) {
        let src = CGEventSource(stateID: .combinedSessionState)
        for ch in text.utf8 {
            guard let (down, up) = keyEventsForASCII(UInt8(ch), source: src) else { continue }
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
    
    // Minimal ASCII map (extend as needed)
    private static func keyEventsForASCII(_ byte: UInt8, source: CGEventSource?) -> (CGEvent, CGEvent)? {
        let shiftNeeded: Bool
        let key: CGKeyCode
        
        switch byte {
        case 0x20: key = CGKeyCode(kVK_Space); shiftNeeded = false
        case 0x30...0x39: key = CGKeyCode(Int(byte - 0x30) + kVK_ANSI_0); shiftNeeded = false     // 0..9
        case 0x41...0x5A: key = CGKeyCode(Int(byte - 0x41) + kVK_ANSI_A); shiftNeeded = true      // A..Z
        case 0x61...0x7A: key = CGKeyCode(Int(byte - 0x61) + kVK_ANSI_A); shiftNeeded = false     // a..z
        case 0x2E: key = CGKeyCode(kVK_ANSI_Period); shiftNeeded = false                       // .
        case 0x2C: key = CGKeyCode(kVK_ANSI_Comma); shiftNeeded = false                        // ,
        case 0x21: key = CGKeyCode(kVK_ANSI_1); shiftNeeded = true                             // !
        case 0x3F: key = CGKeyCode(kVK_ANSI_Slash); shiftNeeded = true                         // ?
        case 0x2D: key = CGKeyCode(kVK_ANSI_Minus); shiftNeeded = false                        // -
        case 0x27: key = CGKeyCode(kVK_ANSI_Quote); shiftNeeded = false                        // '
        case 0x22: key = CGKeyCode(kVK_ANSI_Quote); shiftNeeded = true                         // "
        case 0x0A, 0x0D: key = CGKeyCode(kVK_Return); shiftNeeded = false                      // \n, \r
        default: return nil
        }
        
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) else {
            return nil
        }
        
        if shiftNeeded { 
            down.flags = .maskShift
            up.flags = .maskShift
        }
        return (down, up)
    }
}