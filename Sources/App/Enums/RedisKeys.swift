//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 01.04.2023.
//

import Foundation

enum RedisKeys: String {
    
//    MARK: - Cases
    case feed, breeds, types
    
    
//    MARK: - Funcs
    static func feed(withFilterHash hash: Int) -> String { "feed:\(hash)" }
    static func user(with id: UUID) -> String { "user:\(id.uuidString)" }
    static func deal(with id: UUID) -> String { "deal:\(id.uuidString)" }
    
}
