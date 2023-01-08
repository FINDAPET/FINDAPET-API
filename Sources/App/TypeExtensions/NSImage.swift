//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 01.01.2023.
//

import Foundation
import AppKit

extension NSImage {
    
    func pngData(size: CGSize, imageInterpolation: NSImageInterpolation = .high) -> Data? {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        
        bitmap.size = size
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = imageInterpolation
        
        self.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1.0)
        
        NSGraphicsContext.restoreGraphicsState()
            
        return bitmap.representation(using: .png, properties: .init())
    }
}
