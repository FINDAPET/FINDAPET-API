//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Vapor
import Fluent

final class UserToken: Model, Content {
    
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    @OptionalField(key: "device_id")
    var deviceID: UUID?
    
    init() { }
    
    init(id: UUID? = nil, deviceID: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.deviceID = deviceID
        self.value = value
        self.$user.id = userID
    }
    
}

extension UserToken: ModelTokenAuthenticatable {
    
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user
    
    var isValid: Bool { true }
    
}

extension UserToken {
    struct Output: Content {
        var id: UUID?
        var value: String
        var user: User
    }
}

extension UserToken: Equatable {
    static func == (lhs: UserToken, rhs: UserToken) -> Bool {
        lhs.id == rhs.id
    }
}
