//
//  ScreenshotManager.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import Foundation
import AppKit
import ApplicationServices

class ScreenshotManager {
    static let shared = ScreenshotManager()
    
    private init() {}
    
    /// Captures a screenshot with area selection using screencapture -i (interactive mode)
    /// This uses macOS's built-in selection tool (like Cmd+Shift+4)
    /// Much more reliable than custom window implementation
    func captureScreenshotWithSelection(completion: @escaping (Data?) -> Void) {
        // Use screencapture's interactive mode (-i flag)
        // This shows macOS's built-in selection tool
        let tempFile = NSTemporaryDirectory() + "clipslots_screenshot_\(UUID().uuidString).png"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            // -i: interactive mode (user selects area)
            // -x: don't play sound
            // -t png: PNG format
            process.arguments = ["-i", "-x", "-t", "png", tempFile]
            
            var imageData: Data?
            
            do {
                try process.run()
                process.waitUntilExit()
                
                // Exit code 0 = success, 1 = user cancelled
                if process.terminationStatus == 0 {
                    // Read the captured image data
                    imageData = try? Data(contentsOf: URL(fileURLWithPath: tempFile))
                    
                    // Clean up temp file
                    try? FileManager.default.removeItem(atPath: tempFile)
                    
                    if let data = imageData {
                        print("✅ Captured area screenshot: \(data.count) bytes")
                    } else {
                        print("ERROR: Could not read captured image file")
                    }
                } else if process.terminationStatus == 1 {
                    print("⚠️ Screenshot cancelled by user")
                } else {
                    print("ERROR: screencapture failed with status \(process.terminationStatus)")
                }
            } catch {
                print("ERROR: Failed to run screencapture: \(error)")
            }
            
            // Call completion on main thread
            DispatchQueue.main.async {
                completion(imageData)
            }
        }
    }
    
    /// Captures a screenshot of the entire screen using screencapture command
    /// Returns PNG image data, or nil if capture failed
    func captureScreenshot() -> Data? {
        // Use screencapture command line tool (built into macOS)
        // -x: don't play sound
        // -t png: PNG format
        
        // First, capture to a temporary file
        let tempFile = NSTemporaryDirectory() + "clipslots_screenshot_\(UUID().uuidString).png"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", "-t", "png", tempFile]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                print("ERROR: screencapture command failed with status \(process.terminationStatus)")
                return nil
            }
            
            // Read the captured image data
            guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: tempFile)) else {
                print("ERROR: Could not read screenshot file")
                return nil
            }
            
            // Clean up temp file
            try? FileManager.default.removeItem(atPath: tempFile)
            
            print("✅ Captured screenshot: \(imageData.count) bytes")
            return imageData
        } catch {
            print("ERROR: Failed to run screencapture: \(error)")
            return nil
        }
    }
    
}
