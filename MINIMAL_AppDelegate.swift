//
//  AppDelegate.swift
//  ClipSlots
//
//  Minimal version to test status bar functionality
//

import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("=== ClipSlots: App launched! ===")
        NSLog("ClipSlots: App launched!")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "CS"
            button.toolTip = "ClipSlots"
            
            // Create a simple menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "About ClipSlots", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
            
            print("Status bar item created - title: '\(button.title)'")
            NSLog("Status bar item created - title: CS")
        } else {
            print("ERROR: Could not create status bar button")
            NSLog("ERROR: Could not create status bar button")
        }
    }
}

