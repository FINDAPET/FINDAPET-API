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
        guard !path.isEmpty else { throw FileManagerError.badPath }
        
        if path.first == "/" {
            return Data(buffer: try await req.fileio.collectFile(at: path))
        }
        
        guard let buffer = try await req.client.get(.init(string: path), headers: req.headers).body else {
            return nil
        }
        
        return .init(buffer: buffer)
    }
    
    static func set(req: Request, with path: String, data: Data) async throws {        
        guard !path.isEmpty else { throw FileManagerError.badPath }
        
        if path.first == "/" {
            try await req.fileio.writeFile(.init(data: data), at: path)
            
            return
        }
        
        let statusCode = try await req.client.post(
            .init(string: path),
            headers: .init([(Headers.applicationJson.rawValue, Headers.contentType.rawValue)]), beforeSend: {
                try $0.content.encode(data, as: .formData)
            }).status.code
        
        guard statusCode == 200 else {
            throw Abort(.init(statusCode: .init(statusCode)))
        }
    }
    
}
