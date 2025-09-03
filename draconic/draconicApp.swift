//
//  draconicApp.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var hotkeyManager = GlobalHotkeyManager()
    var floatingWindowController: FloatingWindowController?
    var frontContext: FrontContext?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupHotkey()
    }
    
    private func setupHotkey() {
        hotkeyManager.onHotkeyPressed = {
            self.showFloatingWindow()
        }
        hotkeyManager.registerHotkey()
    }
    
    private func showFloatingWindow() {
        // Check accessibility permission first
        guard AccessibilityGate.ensurePermission() else {
            showAccessibilityAlert()
            return
        }
        
        // Capture the front context BEFORE we activate our UI
        frontContext = FrontContext.capture()
        
        if floatingWindowController == nil {
            floatingWindowController = FloatingWindowController(appDelegate: self)
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: floatingWindowController?.window,
                queue: .main
            ) { _ in
                self.floatingWindowController = nil
            }
        }
        
        floatingWindowController?.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func injectText(_ text: String) {
        guard let context = frontContext else { return }
        TextInjector.inject(text: text, into: context)
        frontContext = nil
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Draconic needs accessibility permission to inject text into other applications.\n\nTo grant permission:\n1. Click 'Open Settings'\n2. Click the '+' button to add Draconic\n3. Navigate to your app and select it\n4. Enable the checkbox next to Draconic"
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Preferences to Privacy & Security > Accessibility
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}



@main
struct draconicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
