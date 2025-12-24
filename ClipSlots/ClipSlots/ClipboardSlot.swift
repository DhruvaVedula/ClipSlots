//
//  ClipboardSlot.swift
//  ClipSlots
//
//  Created by Dhruva Vedula on 12/23/25.
//

import Foundation
import AppKit

struct ClipboardSlot: Codable {
    var text: String?
    var imageData: Data? // PNG image data
    
    var isEmpty: Bool {
        return (text == nil || text?.isEmpty == true) && imageData == nil
    }
    
    var hasImage: Bool {
        return imageData != nil
    }
    
    init(text: String? = nil, imageData: Data? = nil) {
        self.text = text
        self.imageData = imageData
    }
    
    // Custom encoding to handle image data as base64
    enum CodingKeys: String, CodingKey {
        case text
        case imageData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        // Decode base64 image data
        if let base64String = try container.decodeIfPresent(String.self, forKey: .imageData) {
            imageData = Data(base64Encoded: base64String)
        } else {
            imageData = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(text, forKey: .text)
        // Encode image data as base64
        if let imageData = imageData {
            try container.encode(imageData.base64EncodedString(), forKey: .imageData)
        }
    }
    
    // Helper to get NSImage from imageData
    func getImage() -> NSImage? {
        guard let imageData = imageData else { return nil }
        return NSImage(data: imageData)
    }
}

