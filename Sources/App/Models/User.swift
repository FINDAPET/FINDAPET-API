//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Vapor
import Fluent

final class User: Model, Content {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "is_active_cattery")
    var isActiveCattery: Bool
    
    @Field(key: "chats_id")
    var chatsID: [ChatRoom.IDValue]
    
    @Field(key: "is_cattery_wait_verify")
    var isCatteryWaitVerify: Bool
    
    @Field(key: "is_admin")
    var isAdmin: Bool
    
    @OptionalField(key: "avatar_path")
    var avatarPath: String?
    
    @OptionalField(key: "document_path")
    var documentPath: String?
    
    @OptionalField(key: "description")
    var description: String?
    
    @Children(for: \.$cattery)
    var deals: [Deal]
    
    @Children(for: \.$buyer)
    var boughtDeals: [Deal]
    
    @Children(for: \.$cattery)
    var ads: [Ad]
    
    @Children(for: \.$buyer)
    var myOffers: [Offer]
    
    @Children(for: \.$cattery)
    var offers: [Offer]
    
    init() { }
    
    init(id: UUID? = nil, email: String, passwordHash: String, name: String = "", isActiveCattery: Bool = false, avatarPath: String? = nil, documentPath: String? = nil, description: String? = nil, chatsID: [ChatRoom.IDValue] = [ChatRoom.IDValue](), isCatteryWaitVerify: Bool = false, isAdmin: Bool = false) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
        self.isActiveCattery = isActiveCattery
        self.avatarPath = avatarPath
        self.documentPath = documentPath
        self.description = description
        self.chatsID = chatsID
        self.isCatteryWaitVerify = isCatteryWaitVerify
        self.isAdmin = isAdmin
    }
    
}

extension User {
    struct Create: Content {
        var email: String
        var password: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

extension User: ModelAuthenticatable {
    
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
    
}

extension User {
    func generateToken() throws -> UserToken {
        return try .init(value: [UInt8].random(count: 16).base64, userID: self.requireID())
    }
}

extension User {
    struct Input: Content {
        var id: UUID?
        var name: String
        var avatarData: Data?
        var documentData: Data?
        var description: String?
        var isCatteryWaitVerify: Bool
        
        init(id: UUID? = nil, name: String = "", avatarData: Data? = nil, documentData: Data? = nil, description: String? = nil, isCatteryWaitVerify: Bool = false) {
            self.id = id
            self.name = name
            self.avatarData = avatarData
            self.documentData = documentData
            self.description = description
            self.isCatteryWaitVerify = isCatteryWaitVerify
        }
    }
}

extension User {
    struct Output: Content {
        var id: UUID?
        var name: String
        var avatarData: Data?
        var documentData: Data?
        var description: String?
        var deals: [Deal.Output]
        var boughtDeals: [Deal.Output]
        var ads: [Ad.Output]
        var myOffers: [Offer.Output]
        var offers: [Offer.Output]
    }
}
