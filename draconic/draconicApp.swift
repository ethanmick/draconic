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
    var previousApp: NSRunningApplication?
    
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
        // Capture the currently active app before showing our window
        previousApp = NSWorkspace.shared.frontmostApplication
        
        if floatingWindowController == nil {
            floatingWindowController = FloatingWindowController()
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: floatingWindowController?.window,
                queue: .main
            ) { _ in
                self.restorePreviousAppFocus()
                self.floatingWindowController = nil
            }
        }
        
        floatingWindowController?.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func restorePreviousAppFocus() {
        // Return focus to the previously active app
        if let previousApp = previousApp {
            previousApp.activate()
        }
        self.previousApp = nil
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
