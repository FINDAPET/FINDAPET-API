//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.05.2023.
//

import Foundation

enum Platform: Codable {
    case iOS, Android, custom(name: String)
    
    var value: String {
        switch self {
        case .iOS:
            return "iOS"
        case .Android:
            return "Android"
        case .custom(let name):
            return name
        }
    }
    
    static func get(_ value: String) -> Self {
        if value == "iOS" {
            return .iOS
        } else if value == "Android" {
            return .Android
        }
        
        return .custom(name: value)
    }
}
