//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.10.2022.
//

import Foundation
import Vapor

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
    
}
