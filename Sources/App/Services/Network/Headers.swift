//
//  Deaders.swift
//  FINDAPET-App
//
//  Created by Artemiy Zuzin on 13.08.2022.
//

import Foundation

enum Headers: String {
    case applicationJson = "application/json"
    case contentType = "Content-Type"
    case authorization = "Authorization"
    
    static func authString(email: String, password: String) -> String? {
        guard let authString = "\(email):\(password)".data(using: .utf8)?.base64EncodedString() else {
            return nil
        }
        
        return "Basic \(authString)"
    }
    
    static func bearerAuthString(token: String) -> String {
        return "Bearer \(token)"
    }
}
