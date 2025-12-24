//
//  KeystrokeSimulator.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import Foundation
import AppKit
import ApplicationServices

class KeystrokeSimulator {
    static let shared = KeystrokeSimulator()
    
    private init() {}
    
    /// Check if accessibility permissions are granted
    func hasAccessibilityPermissions() -> Bool {
        // Force a fresh check by passing nil first (some macOS versions cache this)
        let _ = AXIsProcessTrusted()
        
        // Then check with options
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Also try the old API as a fallback check
        if !isTrusted {
            let oldCheck = AXIsProcessTrusted()
            if oldCheck {
                print("Note: AXIsProcessTrusted() returned true but AXIsProcessTrustedWithOptions returned false")
            }
        }
        
        return isTrusted
    }
    
    /// Simulates pressing Cmd+C to copy current selection
    func simulateCopy() -> Bool {
        print("Attempting to simulate Cmd+C...")
        
        // Create events with proper source
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("ERROR: Could not create event source")
            return false
        }
        
        // Create key down event with Cmd modifier
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) else {
            print("ERROR: Could not create key down event")
            return false
        }
        keyDownEvent.flags = .maskCommand
        
        // Create key up event with Cmd modifier  
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) else {
            print("ERROR: Could not create key up event")
            return false
        }
        keyUpEvent.flags = .maskCommand
        
        // Post events
        keyDownEvent.post(tap: .cghidEventTap)
        usleep(50000) // 50ms delay
        keyUpEvent.post(tap: .cghidEventTap)
        
        print("Cmd+C events posted")
        usleep(200000) // 200ms wait for clipboard to update
        return true
    }
    
    /// Simulates pressing Cmd+V to paste from clipboard
    func simulatePaste() -> Bool {
        print("Attempting to simulate Cmd+V...")
        
        // Create events with proper source
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("ERROR: Could not create event source")
            return false
        }
        
        // Create key down event with Cmd modifier
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            print("ERROR: Could not create key down event")
            return false
        }
        keyDownEvent.flags = .maskCommand
        
        // Create key up event with Cmd modifier
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("ERROR: Could not create key up event")
            return false
        }
        keyUpEvent.flags = .maskCommand
        
        // Post events
        keyDownEvent.post(tap: .cghidEventTap)
        usleep(50000) // 50ms delay
        keyUpEvent.post(tap: .cghidEventTap)
        
        print("Cmd+V events posted")
        return true
    }
}

