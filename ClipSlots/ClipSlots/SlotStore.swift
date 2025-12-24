//
//  SlotStore.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import Foundation
import AppKit

class SlotStore {
    static let shared = SlotStore()
    
    private let slotsCount = 9
    private(set) var slots: [ClipboardSlot]
    
    private let storageURL: URL
    
    private init() {
        // Create slots array with 9 empty slots
        slots = Array(repeating: ClipboardSlot(), count: slotsCount)
        
        // Set up storage URL in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appFolder = appSupport.appendingPathComponent("ClipSlots", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        storageURL = appFolder.appendingPathComponent("slots.json")
        
        // Load existing slots from disk
        loadSlots()
    }
    
    // MARK: - Public Methods
    
    func storeText(_ text: String, in slotIndex: Int) {
        guard slotIndex >= 0 && slotIndex < slotsCount else {
            print("ERROR: Invalid slot index \(slotIndex)")
            return
        }
        
        slots[slotIndex] = ClipboardSlot(text: text)
        saveSlots()
        let slotLetter = slotLetter(for: slotIndex)
        print("Stored text in slot \(slotLetter): \(text.prefix(50))...")
    }
    
    func storeImage(_ imageData: Data, in slotIndex: Int) {
        guard slotIndex >= 0 && slotIndex < slotsCount else {
            print("ERROR: Invalid slot index \(slotIndex)")
            return
        }
        
        slots[slotIndex] = ClipboardSlot(imageData: imageData)
        saveSlots()
        let slotLetter = slotLetter(for: slotIndex)
        print("Stored image in slot \(slotLetter): \(imageData.count) bytes")
    }
    
    /// Get the letter key for a slot index (0-8 -> Q,W,E,R,A,S,D,F,Z)
    private func slotLetter(for index: Int) -> String {
        let letters = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z"]
        guard index >= 0 && index < letters.count else { return "?" }
        return letters[index]
    }
    
    func getText(from slotIndex: Int) -> String? {
        guard slotIndex >= 0 && slotIndex < slotsCount else {
            return nil
        }
        
        return slots[slotIndex].text
    }
    
    func getImage(from slotIndex: Int) -> NSImage? {
        guard slotIndex >= 0 && slotIndex < slotsCount else {
            return nil
        }
        
        return slots[slotIndex].getImage()
    }
    
    func getImageData(from slotIndex: Int) -> Data? {
        guard slotIndex >= 0 && slotIndex < slotsCount else {
            return nil
        }
        
        return slots[slotIndex].imageData
    }
    
    func clearSlot(_ slotIndex: Int) {
        guard slotIndex >= 0 && slotIndex < slotsCount else {
            return
        }
        
        slots[slotIndex] = ClipboardSlot()
        saveSlots()
        let slotLetter = slotLetter(for: slotIndex)
        print("Cleared slot \(slotLetter)")
    }
    
    func clearAllSlots() {
        slots = Array(repeating: ClipboardSlot(), count: slotsCount)
        saveSlots()
        print("Cleared all slots")
    }
    
    // MARK: - Persistence
    
    private func saveSlots() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(slots)
            try data.write(to: storageURL)
            print("Saved slots to: \(storageURL.path)")
        } catch {
            print("ERROR: Failed to save slots: \(error)")
        }
    }
    
    private func loadSlots() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            print("No existing slots file found, starting with empty slots")
            return
        }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            let loadedSlots = try decoder.decode([ClipboardSlot].self, from: data)
            
            // Ensure we have exactly 9 slots
            if loadedSlots.count == slotsCount {
                slots = loadedSlots
                print("Loaded \(slotsCount) slots from: \(storageURL.path)")
            } else {
                print("WARNING: Loaded \(loadedSlots.count) slots, expected \(slotsCount). Starting fresh.")
            }
        } catch {
            print("ERROR: Failed to load slots: \(error)")
        }
    }
}

