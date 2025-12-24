//
//  AppDelegate.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import AppKit
import Foundation
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, HotkeyManagerDelegate {
    
    var statusItem: NSStatusItem?
    let slotStore = SlotStore.shared
    let hotkeyManager = HotkeyManager.shared
    
    override init() {
        super.init()
        print("ClipSlots: AppDelegate initialized")
    }
    
    // MARK: - Helper Methods
    
    /// Get the letter key for a slot index (0-8 -> Q,W,E,R,A,S,D,F,Z)
    private func slotLetter(for index: Int) -> String {
        let letters = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z"]
        guard index >= 0 && index < letters.count else { return "?" }
        return letters[index]
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("ClipSlots: Application did finish launching")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            print("ERROR: Could not create status bar button")
            return
        }
        
        button.title = "CS"
        button.toolTip = "ClipSlots"
        
        // Create menu (will be built when opened)
        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
        
        // Build initial menu
        buildMenu()
        
        // Setup hotkeys
        hotkeyManager.delegate = self
        hotkeyManager.registerHotkeys()
        
        // Check permissions - try both APIs
        let optionsNoPrompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasAccessNoPrompt = AXIsProcessTrustedWithOptions(optionsNoPrompt as CFDictionary)
        
        // Also try the old API
        let oldAPI = AXIsProcessTrusted()
        
        print("Permission check - AXIsProcessTrustedWithOptions: \(hasAccessNoPrompt), AXIsProcessTrusted: \(oldAPI)")
        
        if hasAccessNoPrompt || oldAPI {
            print("Accessibility permissions granted ✓")
        } else {
            print("⚠️ WARNING: Accessibility permissions NOT granted")
            print("   Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
            print("   App Path: \(Bundle.main.bundlePath)")
            
            // Force a prompt
            let optionsWithPrompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(optionsWithPrompt as CFDictionary)
            
            // Show alert after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "ClipSlots needs Accessibility permissions to copy selected text.\n\n⚠️ IMPORTANT: When running from Xcode, macOS may not recognize permissions.\n\nTry this:\n1. Build the app in Xcode\n2. Open Finder → Go to DerivedData folder\n3. Double-click ClipSlots.app to run it directly\n4. Grant permissions when prompted\n\nOr enable manually in System Settings > Privacy & Security > Accessibility"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "OK")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        print("ClipSlots: Status bar item created successfully")
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        // Rebuild menu right before it opens to show latest slot contents
        buildMenu()
    }
    
    func buildMenu() {
        guard let menu = statusItem?.menu else { 
            print("⚠️ Cannot build menu: statusItem?.menu is nil")
            return 
        }
        
        // Clear existing items safely
        menu.removeAllItems()
        
        // Add slot items - clicking pastes to clipboard
        for i in 0..<9 {
            let slotLetter = slotLetter(for: i)
            let slot = slotStore.slots[i]
            
            let item: NSMenuItem
            if slot.hasImage {
                // Slot has an image - show image preview (without thumbnail to avoid crashes)
                item = NSMenuItem(title: "\(slotLetter). [Image]", action: #selector(pasteFromSlot(_:)), keyEquivalent: "")
                // Don't set image thumbnail for now to avoid crashes
                // The menu will still show "[Image]" label
            } else if let text = slot.text, !text.isEmpty {
                // Slot has text - show preview
                let preview = String(text.prefix(40))
                item = NSMenuItem(title: "\(slotLetter). \(preview)\(text.count > 40 ? "..." : "")", action: #selector(pasteFromSlot(_:)), keyEquivalent: "")
            } else {
                // Empty slot
                item = NSMenuItem(title: "\(slotLetter). (empty)", action: #selector(pasteFromSlot(_:)), keyEquivalent: "")
            }
            
            item.tag = i
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Store clipboard section
        let storeHeader = NSMenuItem(title: "Store Clipboard To:", action: nil, keyEquivalent: "")
        storeHeader.isEnabled = false
        menu.addItem(storeHeader)
        
        for i in 0..<9 {
            let slotLetter = slotLetter(for: i)
            let item = NSMenuItem(title: "Slot \(slotLetter)", action: #selector(storeClipboardToSlot(_:)), keyEquivalent: "")
            item.tag = i
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Clear actions section
        let clearHeader = NSMenuItem(title: "Clear Slot:", action: nil, keyEquivalent: "")
        clearHeader.isEnabled = false
        menu.addItem(clearHeader)
        
        for i in 0..<9 {
            let slotLetter = slotLetter(for: i)
            let slot = slotStore.slots[i]
            
            // Only show clear option if slot has content
            if slot.text != nil && !slot.text!.isEmpty {
                let item = NSMenuItem(title: "Clear Slot \(slotLetter)", action: #selector(clearSlot(_:)), keyEquivalent: "")
                item.tag = i
                item.target = self
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear All Slots", action: #selector(clearAllSlots(_:)), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About ClipSlots", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    // MARK: - Clipboard Operations
    
    @objc func pasteFromSlot(_ sender: NSMenuItem) {
        let slotIndex = sender.tag
        let slotLetter = slotLetter(for: slotIndex)
        let slot = slotStore.slots[slotIndex]
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Handle image or text
        if let imageData = slot.imageData, let image = NSImage(data: imageData) {
            // Paste image
            pasteboard.setData(imageData, forType: .png)
            print("Pasted image from slot \(slotLetter) to clipboard")
        } else if let text = slot.text, !text.isEmpty {
            // Paste text
            pasteboard.setString(text, forType: .string)
            print("Pasted slot \(slotLetter) to clipboard: \(text.prefix(50))...")
        } else {
            print("Slot \(slotLetter) is empty")
            return
        }
    }
    
    @objc func storeClipboardToSlot(_ sender: NSMenuItem) {
        let slotIndex = sender.tag
        let slotLetter = slotLetter(for: slotIndex)
        
        // Get text from clipboard
        let pasteboard = NSPasteboard.general
        guard let clipboardText = pasteboard.string(forType: .string), !clipboardText.isEmpty else {
            print("Clipboard is empty or doesn't contain text")
            return
        }
        
        slotStore.storeText(clipboardText, in: slotIndex)
        print("Stored clipboard to slot \(slotLetter)")
    }
    
    @objc func clearSlot(_ sender: NSMenuItem) {
        let slotIndex = sender.tag
        let slotLetter = slotLetter(for: slotIndex)
        slotStore.clearSlot(slotIndex)
        let slot = slotStore.slots[slotIndex]
        if slot.hasImage {
            print("Cleared image from slot \(slotLetter)")
        } else {
            print("Cleared slot \(slotLetter)")
        }
        
        // Rebuild menu to reflect the change
        buildMenu()
    }
    
    @objc func clearAllSlots(_ sender: Any?) {
        slotStore.clearAllSlots()
        print("Cleared all slots")
        
        // Rebuild menu to reflect the change
        buildMenu()
    }
    
    // MARK: - HotkeyManagerDelegate
    
    func hotkeyManager(_ manager: HotkeyManager, didPressStoreHotkeyForSlot slotIndex: Int) {
        // Copy current selection and store to slot
        DispatchQueue.main.async {
            self.copyAndStoreToSlot(slotIndex: slotIndex)
        }
    }
    
    func hotkeyManager(_ manager: HotkeyManager, didPressPasteHotkeyForSlot slotIndex: Int) {
        // Paste slot to clipboard
        DispatchQueue.main.async {
            self.pasteFromSlot(slotIndex: slotIndex)
        }
    }
    
    func hotkeyManager(_ manager: HotkeyManager, didPressScreenshotHotkeyForSlot slotIndex: Int) {
        // Capture screenshot and store to slot
        DispatchQueue.main.async {
            self.captureAndStoreScreenshot(slotIndex: slotIndex)
        }
    }
    
    // MARK: - Clipboard Operations (Hotkey Handlers)
    
    private func copyAndStoreToSlot(slotIndex: Int) {
        // Strategy 1: Try Accessibility API first (works for native apps like Terminal, TextEdit, etc.)
        let slotLetter = slotLetter(for: slotIndex)
        print("🔍 Attempting to get selected text via Accessibility API...")
        if let selectedText = SelectedTextGetter.shared.getSelectedText(), !selectedText.isEmpty {
            slotStore.storeText(selectedText, in: slotIndex)
            print("✅ SUCCESS: Got selected text via Accessibility API and stored to slot \(slotLetter)")
            return
        }
        
        print("⚠️ Accessibility API didn't find selected text (common for web apps)")
        print("   Trying keyboard simulation (Cmd+C) as fallback...")
        
        // Strategy 2: Simulate Cmd+C to copy selected text (works for web apps like Google Docs)
        let pasteboard = NSPasteboard.general
        let clipboardBefore = pasteboard.string(forType: .string) ?? ""
        let changeCountBefore = pasteboard.changeCount
        
        // Simulate copy
        if KeystrokeSimulator.shared.simulateCopy() {
            // Wait a bit for clipboard to update
            Thread.sleep(forTimeInterval: 0.15)
            
            let clipboardAfter = pasteboard.string(forType: .string) ?? ""
            let changeCountAfter = pasteboard.changeCount
            
            // Check if clipboard actually changed (indicates copy worked)
            if changeCountAfter > changeCountBefore && clipboardAfter != clipboardBefore && !clipboardAfter.isEmpty {
                slotStore.storeText(clipboardAfter, in: slotIndex)
                print("✅ SUCCESS: Copied selected text via Cmd+C simulation and stored to slot \(slotLetter)")
                return
            } else {
                print("⚠️ Clipboard didn't change - either nothing was selected or simulation failed")
            }
        }
        
        // Strategy 3: Fallback to existing clipboard content
        if let clipboardText = pasteboard.string(forType: .string), !clipboardText.isEmpty {
            slotStore.storeText(clipboardText, in: slotIndex)
            print("⚠️ Stored current clipboard content to slot \(slotLetter)")
            print("   Note: If you had text selected, try manually copying (⌘C) first, then use this hotkey")
        } else {
            print("❌ ERROR: Clipboard is empty and selected text unavailable")
        }
    }
    
    private func pasteFromSlot(slotIndex: Int) {
        let slotLetter = slotLetter(for: slotIndex)
        let slot = slotStore.slots[slotIndex]
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Handle image or text
        if let imageData = slot.imageData {
            // Paste image
            pasteboard.setData(imageData, forType: .png)
            
            // Small delay to ensure clipboard is updated
            Thread.sleep(forTimeInterval: 0.05)
            
            // Try to simulate Cmd+V to paste
            _ = KeystrokeSimulator.shared.simulatePaste()
            
            print("Pasted image from slot \(slotLetter) via hotkey")
        } else if let text = slot.text, !text.isEmpty {
            // Paste text
            pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)
            
            // Small delay to ensure clipboard is updated
            Thread.sleep(forTimeInterval: 0.05)
            
            // Try to simulate Cmd+V to paste
            _ = KeystrokeSimulator.shared.simulatePaste()
            
            print("Pasted slot \(slotLetter) via hotkey: \(text.prefix(50))...")
        } else {
            print("Slot \(slotLetter) is empty")
        }
    }
    
    private func captureAndStoreScreenshot(slotIndex: Int) {
        let slotLetter = slotLetter(for: slotIndex)
        print("📸 Capturing screenshot for slot \(slotLetter)...")
        
        guard let imageData = ScreenshotManager.shared.captureScreenshot() else {
            print("❌ ERROR: Failed to capture screenshot")
            return
        }
        
        slotStore.storeImage(imageData, in: slotIndex)
        print("✅ Screenshot captured and stored to slot \(slotLetter)")
        
        // Menu will auto-rebuild when opened next time (via menuWillOpen delegate)
    }
}
