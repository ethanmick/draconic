//
//  GlobalHotkeyManager.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import Cocoa
import Carbon
import ApplicationServices

class GlobalHotkeyManager: ObservableObject {
    private var hotkeyMonitor: GlobalDoubleModifier?
    
    var onHotkeyPressed: (() -> Void)?
    
    func registerHotkey() {
        NSLog("[GlobalHotkeyManager] Registering double Control tap hotkey")
        hotkeyMonitor = GlobalDoubleModifier(
            targetModifier: .control,
            maxInterval: 0.40
        ) { [weak self] in
            NSLog("[GlobalHotkeyManager] Double Control tap detected! Calling onHotkeyPressed")
            self?.onHotkeyPressed?()
        }
        hotkeyMonitor?.start()
        NSLog("[GlobalHotkeyManager] Hotkey registration complete")
    }
    
    func unregisterHotkey() {
        NSLog("[GlobalHotkeyManager] Unregistering hotkey")
        hotkeyMonitor?.stop()
        hotkeyMonitor = nil
    }
    
    deinit {
        unregisterHotkey()
    }
}

/// Monitors global modifier flag changes and fires when the chosen modifier is pressed twice quickly.
final class GlobalDoubleModifier {
    enum Modifier {
        case control, command, option, shift, capsLock, rightCommand

        var flag: CGEventFlags {
            switch self {
            case .control:    return .maskControl
            case .command:    return .maskCommand
            case .option:     return .maskAlternate
            case .shift:      return .maskShift
            case .capsLock:   return .maskAlphaShift
            case .rightCommand: return CGEventFlags(rawValue: 1 << 28)
            }
        }
    }

    private let targetModifier: Modifier
    private let maxInterval: CFTimeInterval
    private let handler: () -> Void

    private var eventTap: CFMachPort?
    private var lastPressTime: CFTimeInterval = 0
    private var wasDown = false

    init(targetModifier: Modifier, maxInterval: CFTimeInterval, handler: @escaping () -> Void) {
        self.targetModifier = targetModifier
        self.maxInterval = maxInterval
        self.handler = handler
    }

    func start() {
        NSLog("[GlobalDoubleModifier] Starting double-tap monitor for \(targetModifier)")
        
        let hasPermission = ensureAccessibilityPermission()
        NSLog("[GlobalDoubleModifier] Accessibility permission check: \(hasPermission)")

        let mask = (1 << CGEventType.flagsChanged.rawValue)
        NSLog("[GlobalDoubleModifier] Event mask: \(mask)")
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            NSLog("[GlobalDoubleModifier] Event callback triggered - type: \(type)")
            guard type == .flagsChanged,
                  let ref = refcon
            else { 
                NSLog("[GlobalDoubleModifier] Event ignored - not flagsChanged or no refcon")
                return Unmanaged.passUnretained(event) 
            }

            let monitor = Unmanaged<GlobalDoubleModifier>.fromOpaque(ref).takeUnretainedValue()
            monitor.handleFlagsChanged(event: event)
            return Unmanaged.passUnretained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap = eventTap else {
            NSLog("[GlobalDoubleModifier] FAILED to create event tap - check accessibility permissions!")
            return
        }

        NSLog("[GlobalDoubleModifier] Event tap created successfully")
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        NSLog("[GlobalDoubleModifier] Event tap enabled and added to run loop")
    }
    
    func stop() {
        NSLog("[GlobalDoubleModifier] Stopping event tap")
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            NSLog("[GlobalDoubleModifier] Event tap stopped and invalidated")
        }
    }

    private func handleFlagsChanged(event: CGEvent) {
        let flags = event.flags
        NSLog("[GlobalDoubleModifier] Flags changed event - raw flags: \(flags.rawValue)")

        // Is target modifier currently down?
        let isDown = flags.contains(targetModifier.flag)
        NSLog("[GlobalDoubleModifier] Target modifier (\(targetModifier)) is down: \(isDown), was down: \(wasDown)")

        // We trigger on transitions from up -> down only
        if isDown && !wasDown {
            let now = CACurrentMediaTime()
            let dt  = now - lastPressTime
            NSLog("[GlobalDoubleModifier] Control key pressed! Time since last: \(dt)s (max: \(maxInterval)s)")
            lastPressTime = now

            if dt <= maxInterval && dt > 0 {
                NSLog("[GlobalDoubleModifier] DOUBLE-TAP DETECTED! Firing handler...")
                handler()
            } else {
                NSLog("[GlobalDoubleModifier] Single tap (dt=\(dt)s) - waiting for potential double tap")
            }
        } else if !isDown && wasDown {
            NSLog("[GlobalDoubleModifier] Control key released")
        }

        wasDown = isDown
    }

    private func ensureAccessibilityPermission() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(opts)
        NSLog("[GlobalDoubleModifier] Accessibility permission status: \(isTrusted)")
        return isTrusted
    }
}
