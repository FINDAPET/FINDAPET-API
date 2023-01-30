//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 22.01.2023.
//

import Foundation
import Vapor
import Fluent

final class Subscription: Model, Content {
    
    typealias CountryCode = String
    
    static let schema = "subscriptions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "localized_names")
    var localizedNames: [CountryCode : String]
    
    @Field(key: "expiration_date")
    var expirationDate: Date
    
    @Parent(key: "user_id")
    var user: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        localizedNames: [CountryCode : String],
        expirationDate: Date,
        userID: User.IDValue,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.localizedNames = localizedNames
        self.expirationDate = expirationDate
        self.$user.id = userID
        self.createdAt = createdAt
    }
    
}

extension Subscription {
    struct Input: Content {
        var id: UUID?
        var localizedNames: [CountryCode : String]
        var expirationDate: Date
        var userID: User.IDValue
    }
}

extension Subscription {
    struct Output: Content {
        var id: UUID?
        var localizedNames: [CountryCode : String]
        var expirationDate: Date
        var user: User
        var createdAt: Date?
    }
}

extension Subscription: Equatable {
    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        lhs.id == rhs.id
    }
}
