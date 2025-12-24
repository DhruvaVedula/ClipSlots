//
//  ScreenshotSelectionView.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import AppKit

class ScreenshotSelectionView: NSView {
    var selectionRect: NSRect = .zero
    var startPoint: NSPoint = .zero
    var isSelecting = false
    var onSelectionComplete: ((NSRect) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Make view transparent but still receives mouse events
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        isSelecting = true
        selectionRect = NSRect(origin: point, size: .zero)
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isSelecting else { return }
        
        let currentPoint = convert(event.locationInWindow, from: nil)
        
        // Calculate selection rectangle
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)
        
        selectionRect = NSRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
        
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isSelecting else { return }
        isSelecting = false
        
        // Only complete if selection has meaningful size
        if selectionRect.width > 10 && selectionRect.height > 10 {
            // Store the rect before resetting
            let rectToUse = selectionRect
            
            // Reset UI first
            selectionRect = .zero
            needsDisplay = true
            
            // Call completion handler immediately (we're already on main thread)
            onSelectionComplete?(rectToUse)
        } else {
            // Reset
            selectionRect = .zero
            needsDisplay = true
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // ESC key cancels selection
        if event.keyCode == 53 { // ESC key
            isSelecting = false
            selectionRect = .zero
            needsDisplay = true
            // Close the window
            window?.close()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard isSelecting && selectionRect.width > 0 && selectionRect.height > 0 else {
            return
        }
        
        let context = NSGraphicsContext.current?.cgContext
        
        // Draw semi-transparent overlay (everything except selection)
        context?.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        context?.fill(bounds)
        
        // Clear the selection area (make it fully transparent)
        context?.setBlendMode(.clear)
        context?.fill(selectionRect)
        context?.setBlendMode(.normal)
        
        // Draw selection border
        context?.setStrokeColor(NSColor.systemBlue.cgColor)
        context?.setLineWidth(2.0)
        context?.stroke(selectionRect)
        
        // Draw corner handles
        let handleSize: CGFloat = 8
        let handles = [
            NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.maxY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.maxY - handleSize/2, width: handleSize, height: handleSize)
        ]
        
        context?.setFillColor(NSColor.systemBlue.cgColor)
        for handle in handles {
            context?.fill(handle)
        }
    }
}

class ScreenshotSelectionWindow: NSWindow {
    var selectionView: ScreenshotSelectionView!
    var onSelectionComplete: ((NSRect) -> Void)?
    
    init() {
        // Get all screens combined bounds
        var combinedRect = NSRect.zero
        for screen in NSScreen.screens {
            combinedRect = combinedRect.union(screen.frame)
        }
        
        super.init(
            contentRect: combinedRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Make window transparent and click-through
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Create selection view
        selectionView = ScreenshotSelectionView(frame: contentView!.bounds)
        selectionView.autoresizingMask = [.width, .height]
        
        selectionView.onSelectionComplete = { [weak self] rect in
            self?.handleSelection(rect: rect)
        }
        
        contentView = selectionView
        
        // Make window key to receive keyboard events (for ESC)
        makeKeyAndOrderFront(nil)
        makeFirstResponder(selectionView)
    }
    
    private func handleSelection(rect: NSRect) {
        // Convert to screen coordinates
        // The view coordinates are already in screen space, but we need to account for
        // the fact that macOS uses bottom-left origin while our view uses top-left
        guard let mainScreen = NSScreen.main else {
            onSelectionComplete?(rect)
            return
        }
        
        // Get the screen that contains the selection
        var targetScreen: NSScreen?
        let selectionCenter = NSPoint(x: rect.midX, y: rect.midY)
        
        for screen in NSScreen.screens {
            if screen.frame.contains(selectionCenter) {
                targetScreen = screen
                break
            }
        }
        
        let screen = targetScreen ?? mainScreen
        let screenHeight = screen.frame.height
        
        // Convert Y coordinate: view uses top-left origin, screencapture uses bottom-left
        let screenRect = NSRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        
        print("Selection rect: \(rect), Screen rect: \(screenRect), Screen height: \(screenHeight)")
        
        // Call completion - don't close window here, let ScreenshotManager handle it
        onSelectionComplete?(screenRect)
    }
}


