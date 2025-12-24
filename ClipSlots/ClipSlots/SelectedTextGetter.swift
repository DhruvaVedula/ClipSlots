//
//  SelectedTextGetter.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import Foundation
import AppKit
import ApplicationServices

class SelectedTextGetter {
    static let shared = SelectedTextGetter()
    
    private init() {}
    
    /// Gets the currently selected text using Accessibility API
    func getSelectedText() -> String? {
        // Get the currently focused application
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let appName = frontApp.localizedName else {
            print("ERROR: Could not get frontmost application")
            return nil
        }
        
        let pid = frontApp.processIdentifier
        print("Trying to get selected text from: \(appName) (PID: \(pid))")
        
        // Create accessibility element for the application
        let appElement = AXUIElementCreateApplication(pid)
        
        // Strategy 1: Try focused element first (works for most native apps)
        if let text = getSelectedTextFromElement(appElement, searchFocused: true) {
            return text
        }
        
        // Strategy 2: Search through the accessibility hierarchy (needed for web apps)
        print("Focused element didn't have selection, searching accessibility tree...")
        if let text = searchForSelectedTextInHierarchy(appElement, maxDepth: 5) {
            return text
        }
        
        print("❌ Could not get selected text - tried all methods")
        return nil
    }
    
    /// Try to get selected text from a specific element (focused or provided)
    private func getSelectedTextFromElement(_ appElement: AXUIElement, searchFocused: Bool) -> String? {
        var elementToCheck: AXUIElement = appElement
        
        if searchFocused {
            // Get the focused UI element
            var focusedElement: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
            
            guard result == .success, let element = focusedElement else {
                return nil
            }
            
            elementToCheck = element as! AXUIElement
        }
        
        // Method 1: Try to get selected text directly (works for most text fields)
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(elementToCheck, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            print("✅ Got selected text via kAXSelectedTextAttribute: \(text.prefix(50))...")
            return text
        }
        
        // Method 2: Get selected text range and extract from value
        var selectedRange: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(elementToCheck, kAXSelectedTextRangeAttribute as CFString, &selectedRange)
        
        if rangeResult == .success, let rangeValue = selectedRange {
            // Get the full text value
            var textValue: CFTypeRef?
            let valueResult = AXUIElementCopyAttributeValue(elementToCheck, kAXValueAttribute as CFString, &textValue)
            
            if valueResult == .success, let fullText = textValue as? String, !fullText.isEmpty {
                // Try to extract selected range - range is typically an AXValue with CFRange
                var cfRange = CFRange(location: 0, length: 0)
                if CFGetTypeID(rangeValue) == AXValueGetTypeID() {
                    let range = rangeValue as! AXValue
                    if AXValueGetValue(range, .cfRange, &cfRange) {
                        if cfRange.location >= 0 && cfRange.location < fullText.count {
                            let startIndex = fullText.index(fullText.startIndex, offsetBy: cfRange.location)
                            let maxLength = fullText.count - cfRange.location
                            let actualLength = min(cfRange.length, maxLength)
                            let endIndex = fullText.index(startIndex, offsetBy: actualLength)
                            let selectedPortion = String(fullText[startIndex..<endIndex])
                            if !selectedPortion.isEmpty {
                                print("✅ Got selected text via range extraction: \(selectedPortion.prefix(50))...")
                                return selectedPortion
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Recursively search the accessibility hierarchy for selected text
    private func searchForSelectedTextInHierarchy(_ element: AXUIElement, maxDepth: Int, currentDepth: Int = 0) -> String? {
        guard currentDepth < maxDepth else { return nil }
        
        // Check if this element has selected text
        if let text = getSelectedTextFromElement(element, searchFocused: false) {
            return text
        }
        
        // Get children and search them
        var children: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)
        
        guard result == .success, let childrenArray = children as? [AXUIElement] else {
            return nil
        }
        
        // Search children (prioritize focused/selected children first)
        for child in childrenArray {
            // Check if child is focused or selected
            var isFocused = false
            var focusedValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(child, kAXFocusedAttribute as CFString, &focusedValue) == .success {
                if let focused = focusedValue as? Bool {
                    isFocused = focused
                }
            }
            
            // If focused, check it first
            if isFocused {
                if let text = getSelectedTextFromElement(child, searchFocused: false) {
                    return text
                }
            }
        }
        
        // Search all children recursively
        for child in childrenArray {
            if let text = searchForSelectedTextInHierarchy(child, maxDepth: maxDepth, currentDepth: currentDepth + 1) {
                return text
            }
        }
        
        return nil
    }
}

