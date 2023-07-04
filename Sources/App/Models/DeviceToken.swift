//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.05.2023.
//

import Foundation
import Vapor
import Fluent

final class DeviceToken: Model, Content {
    
//    MARK: - Properties
    static let schema = "device_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Field(key: "platform")
    var platform: String
    
    @Parent(key: "user_id")
    var user: User
    
//    MARK: - Init
    init() { }
    
    init(id: UUID? = nil, value: String, platform: String, userID: UUID) {
        self.id = id
        self.value = value
        self.platform = platform
        self.$user.id = userID
    }
    
}

//MARK: - Input
extension DeviceToken {
    struct Input: Content {
        var id: UUID?
        var value: String
        var platform: Platform
        var userID: UUID
    }
}

//MARK: - Output
extension DeviceToken {
    struct Output: Content {
        var id: UUID?
        var value: String
        var platform: Platform
        var user: User
    }
}

//MARK: - Extensions
extension DeviceToken: Equatable {
    static func == (lhs: DeviceToken, rhs: DeviceToken) -> Bool { lhs.id == rhs.id }
}
