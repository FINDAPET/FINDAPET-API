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
    
    @Field(key: "is_cattery_wait_verify")
    var isCatteryWaitVerify: Bool
    
    @Field(key: "is_admin")
    var isAdmin: Bool
    
    @Field(key: "chat_rooms_id")
    var chatRoomsID: [ChatRoom.IDValue]
    
    @OptionalChild(for: \.$user)
    var subscrtiption: Subscription?
    
    @Field(key: "basic_currency_name")
    var basicCurrencyName: String
    
    @Field(key: "score")
    var score: Int
    
    @OptionalField(key: "country_code")
    var countryCode: String?
    
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
    
    @Children(for: \.$user)
    var searchTitles: [SearchTitle]
    
    @Children(for: \.$user)
    var deviceTokens: [DeviceToken]
    
    init() { }
    
    init(id: UUID? = nil, email: String, passwordHash: String, name: String = "", isActiveCattery: Bool = false, avatarPath: String? = nil, documentPath: String? = nil, description: String? = nil, isCatteryWaitVerify: Bool = false, isAdmin: Bool = false, score: Int = .zero, chatRoomsID: [ChatRoom.IDValue] = [ChatRoom.IDValue](), countryCode: String? = nil, basicCurrencyName: String = "USD") {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
        self.isActiveCattery = isActiveCattery
        self.avatarPath = avatarPath
        self.documentPath = documentPath
        self.description = description
        self.isCatteryWaitVerify = isCatteryWaitVerify
        self.isAdmin = isAdmin
        self.score = score
        self.chatRoomsID = chatRoomsID
        self.countryCode = countryCode
        self.basicCurrencyName = basicCurrencyName
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
    func generateToken(deviceID: String? = nil) throws -> UserToken {
        return try .init(deviceID: deviceID, value: [UInt8].random(count: 16).base64, userID: self.requireID())
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
        var chatRoomsID: [ChatRoom.IDValue]
        var countryCode: String?
        var basicCurrencyName: Currency
        
        init(id: UUID? = nil, name: String = "", avatarData: Data? = nil, documentData: Data? = nil, description: String? = nil, isCatteryWaitVerify: Bool = false, chatRoomsID: [ChatRoom.IDValue] = [ChatRoom.IDValue](), countryCode: String? = nil, basicCurrencyName: Currency = .USD) {
            self.id = id
            self.name = name
            self.avatarData = avatarData
            self.documentData = documentData
            self.description = description
            self.isCatteryWaitVerify = isCatteryWaitVerify
            self.chatRoomsID = chatRoomsID
            self.countryCode = countryCode
            self.basicCurrencyName = basicCurrencyName
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
        var chatRooms: [ChatRoom.Output]
        var score: Int
        var subscription: Subscription.Output?
        var isCatteryWaitVerify: Bool?
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
