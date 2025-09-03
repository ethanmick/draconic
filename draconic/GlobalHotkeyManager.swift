//
//  GlobalHotkeyManager.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import AppKit
import Carbon

class GlobalHotkeyManager: ObservableObject {
    private var hotKeyRef: EventHotKeyRef?
    private let hotkeyID = EventHotKeyID(signature: fourCharCode("htk1"), id: 1)
    
    var onHotkeyPressed: (() -> Void)?
    
    func registerHotkey() {
        let keyCode = UInt32(kVK_ANSI_J)
        let modifiers = UInt32(cmdKey | shiftKey)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData!).takeUnretainedValue() as GlobalHotkeyManager? else {
                return OSStatus(eventNotHandledErr)
            }
            
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if hotKeyID.id == manager.hotkeyID.id {
                DispatchQueue.main.async {
                    manager.onHotkeyPressed?()
                }
                return OSStatus(noErr)
            }
            
            return OSStatus(eventNotHandledErr)
        }, 1, &eventType, Unmanaged.passRetained(self).toOpaque(), nil)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}

// Helper for FourCharCode
private func fourCharCode(_ string: String) -> FourCharCode {
    let utf8 = string.utf8
    let count = utf8.count
    var result: FourCharCode = 0
    for (i, byte) in utf8.enumerated() {
        if i >= 4 { break }
        result |= FourCharCode(byte) << (8 * (3 - i))
    }
    return result
}