//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.10.2022.
//

import Foundation
import Vapor
import NIOFoundationCompat
import AppKit

final class FileManager {
    
    static func get(req: Request, with path: String) async throws -> Data? {
        guard !path.isEmpty else {
            throw FileManagerError.badPath
        }
        
        if path.first == "/" {
            return Data(buffer: try await req.fileio.collectFile(at: path))
        }
        
        return try await URLSession.shared.data(from: URL(string: path) ?? URL(fileURLWithPath: "")).0
    }
    
    static func set(req: Request, with path: String, data: Data) async throws {
        var data = data
        
        guard !path.isEmpty else {
            throw FileManagerError.badPath
        }
                
        if let image = NSImage(data: data), data.count > 1024^2 {
            let number = image.size.width / 600 >= image.size.height / 450 ? image.size.width / 600 : image.size.height / 450
                        
            data = image.pngData(size:
                    .init(width: Int(image.size.width / number), height: Int(image.size.height / number))
            ) ?? data
        }
        
        if path.first == "/" {
            try await req.fileio.writeFile(.init(data: data), at: path)
            
            return
        }
        
        var req = URLRequest(url: .init(string: path) ?? .init(fileURLWithPath: .init()))
        
        req.httpBody = data
        req.httpMethod = "POST"
        
        let statusCode = (try await URLSession.shared.data(for: req).1 as? HTTPURLResponse)?.statusCode
        
        guard statusCode == 200 else {
            throw Abort(.init(statusCode: statusCode ?? 500))
        }
    }
    
}
