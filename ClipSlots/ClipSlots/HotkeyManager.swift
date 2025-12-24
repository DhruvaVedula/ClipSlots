//
//  HotkeyManager.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import Carbon
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()
    
    weak var delegate: HotkeyManagerDelegate?
    
    private var hotkeyRefs: [EventHotKeyRef?] = []
    private var eventHandlerRef: EventHandlerRef?
    private let hotkeyIDBase: UInt32 = 1000 // Base ID for hotkeys
    
    private init() {
        setupEventHandler()
    }
    
    deinit {
        unregisterAllHotkeys()
        removeEventHandler()
    }
    
    // Event handler callback (must be at module level for Carbon API)
    private static let eventHandlerCallback: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
        guard let userData = userData else { return OSStatus(eventNotHandledErr) }
        
        var hotkeyID = EventHotKeyID()
        let err = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        guard err == noErr else { return OSStatus(eventNotHandledErr) }
        
        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotkey(hotkeyID: hotkeyID.id)
        
        return OSStatus(noErr)
    }
    
    // MARK: - Public Methods
    
    func registerHotkeys() {
        unregisterAllHotkeys()
        
        // Register hotkeys for slots 1-9
        // Ctrl+Cmd+Q/W/E/R/A/S/D/F/Z = Store to slot 1-9
        // Ctrl+Cmd+Shift+Q/W/E/R/A/S/D/F/Z = Paste from slot 1-9
        // Keys: Q=1, W=2, E=3, R=4, A=5, S=6, D=7, F=8, Z=9
        
        let keyCodes: [UInt32] = [
            0x0C, // Q
            0x0D, // W
            0x0E, // E
            0x0F, // R
            0x00, // A
            0x01, // S
            0x02, // D
            0x03, // F
            0x06  // Z
        ]
        
        let keyNames = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z"]
        
        for slotIndex in 0..<9 {
            let keyCode = keyCodes[slotIndex]
            let keyName = keyNames[slotIndex]
            
            // Store hotkey: Ctrl+Cmd+Key
            let storeID = hotkeyIDBase + UInt32(slotIndex)
            var storeRef: EventHotKeyRef?
            let storeSpec = EventHotKeyID(signature: FourCharCode(fromString: "CLPS"), id: storeID)

            let storeModifiers = UInt32(controlKey | cmdKey)

            let storeStatus = RegisterEventHotKey(
                keyCode,
                storeModifiers,
                storeSpec,
                GetApplicationEventTarget(),
                0,
                &storeRef
            )

            if storeStatus == noErr, let ref = storeRef {
                hotkeyRefs.append(ref)
                print("Registered store hotkey for slot \(keyName): Ctrl+Cmd+\(keyName)")
            } else {
                print("ERROR: Failed to register store hotkey for slot \(keyName): \(storeStatus)")
                hotkeyRefs.append(nil)
            }

            // Paste hotkey: Ctrl+Cmd+Shift+Key
            let pasteID = hotkeyIDBase + 100 + UInt32(slotIndex)
            var pasteRef: EventHotKeyRef?
            let pasteSpec = EventHotKeyID(signature: FourCharCode(fromString: "CLPS"), id: pasteID)

            let pasteModifiers = UInt32(controlKey | cmdKey | shiftKey)

            let pasteStatus = RegisterEventHotKey(
                keyCode,
                pasteModifiers,
                pasteSpec,
                GetApplicationEventTarget(),
                0,
                &pasteRef
            )

            if pasteStatus == noErr, let ref = pasteRef {
                hotkeyRefs.append(ref)
                print("Registered paste hotkey for slot \(keyName): Ctrl+Cmd+Shift+\(keyName)")
            } else {
                print("ERROR: Failed to register paste hotkey for slot \(keyName): \(pasteStatus)")
                hotkeyRefs.append(nil)
            }
            
            // Screenshot hotkey: Ctrl+Cmd+Option+Key
            let screenshotID = hotkeyIDBase + 200 + UInt32(slotIndex)
            var screenshotRef: EventHotKeyRef?
            let screenshotSpec = EventHotKeyID(signature: FourCharCode(fromString: "CLPS"), id: screenshotID)
            
            let screenshotModifiers = UInt32(controlKey | cmdKey | optionKey)
            
            let screenshotStatus = RegisterEventHotKey(
                keyCode,
                screenshotModifiers,
                screenshotSpec,
                GetApplicationEventTarget(),
                0,
                &screenshotRef
            )
            
            if screenshotStatus == noErr, let ref = screenshotRef {
                hotkeyRefs.append(ref)
                print("Registered screenshot hotkey for slot \(keyName): Ctrl+Cmd+Option+\(keyName)")
            } else {
                print("ERROR: Failed to register screenshot hotkey for slot \(keyName): \(screenshotStatus)")
                hotkeyRefs.append(nil)
            }
        }
    }
    
    func unregisterAllHotkeys() {
        for ref in hotkeyRefs {
            if let hotkeyRef = ref {
                UnregisterEventHotKey(hotkeyRef)
            }
        }
        hotkeyRefs.removeAll()
    }
    
    // MARK: - Event Handler
    
    private func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            HotkeyManager.eventHandlerCallback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }
    
    private func removeEventHandler() {
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
    
    private func handleHotkey(hotkeyID: UInt32) {
        let baseID = hotkeyID - hotkeyIDBase
        
        if baseID < 100 {
            // Store hotkey (0-8 = slots Q-Z)
            let slotIndex = Int(baseID)
            delegate?.hotkeyManager(self, didPressStoreHotkeyForSlot: slotIndex)
        } else if baseID < 200 {
            // Paste hotkey (100-108 = slots Q-Z)
            let slotIndex = Int(baseID - 100)
            delegate?.hotkeyManager(self, didPressPasteHotkeyForSlot: slotIndex)
        } else {
            // Screenshot hotkey (200-208 = slots Q-Z)
            let slotIndex = Int(baseID - 200)
            delegate?.hotkeyManager(self, didPressScreenshotHotkeyForSlot: slotIndex)
        }
    }
}

// MARK: - Helper Extension

extension FourCharCode {
    init(fromString string: String) {
        var result: FourCharCode = 0
        for (index, char) in string.utf8.prefix(4).enumerated() {
            result |= FourCharCode(char) << (8 * (3 - index))
        }
        self = result
    }
}

// MARK: - Delegate Protocol

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyManager(_ manager: HotkeyManager, didPressStoreHotkeyForSlot slotIndex: Int)
    func hotkeyManager(_ manager: HotkeyManager, didPressPasteHotkeyForSlot slotIndex: Int)
    func hotkeyManager(_ manager: HotkeyManager, didPressScreenshotHotkeyForSlot slotIndex: Int)
}

