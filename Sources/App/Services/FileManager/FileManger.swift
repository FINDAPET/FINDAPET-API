//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.10.2022.
//

import Foundation
import Vapor
import NIOFoundationCompat

final class FileManager {
    
    static func get(req: Request, with path: String) async throws -> Data? {
        guard !path.isEmpty else {
            throw FileManagerError.badPath
        }
        
        if path.first == "/" {
            return try (Data(buffer: try await req.fileio.collectFile(at: path)) as NSData).decompressed(using: .lzfse) as Data
        }
        
        return try await (URLSession.shared.data(from: URL(string: path) ?? URL(fileURLWithPath: "")).0 as NSData)
            .decompressed(using: .lzfse) as Data
    }
    
    static func set(req: Request, with path: String, data: Data) async throws {
        guard !path.isEmpty else {
            throw FileManagerError.badPath
        }
        
        if path.first == "/" {
            try await req.fileio.writeFile(ByteBuffer(data: try (data as NSData).compressed(using: .lzfse) as Data), at: path)
        }
        
        var req = URLRequest(url: .init(string: path) ?? .init(fileURLWithPath: .init()))
        
        req.httpBody = try (data as NSData).compressed(using: .lzfse) as Data
        req.httpMethod = "POST"
        
        _ = try await URLSession.shared.data(for: req)
    }
    
}
