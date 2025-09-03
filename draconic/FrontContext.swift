//
//  FrontContext.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import AppKit
import ApplicationServices

struct FrontContext {
    let pid: pid_t
    let app: NSRunningApplication
    let focusedElement: AXUIElement?
    
    static func capture() -> FrontContext? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        
        // Try to grab focused UI element via Accessibility
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            system,
            kAXFocusedUIElementAttribute as CFString,
            &focused
        )
        let axEl = (err == .success) ? (focused as! AXUIElement) : nil
        return FrontContext(pid: pid, app: app, focusedElement: axEl)
    }
}