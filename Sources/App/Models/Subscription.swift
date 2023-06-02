//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 11.11.2022.
//

import Foundation
import Vapor
import Fluent

final class Subscription: Model, Content {
    
    typealias CountryCode = String
    
    static let schema = "subscriptions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "expiration_date")
    var expirationDate: Date
    
    @Parent(key: "subscription_title_id")
    var titleSubscription: TitleSubscription
    
    @Parent(key: "user_id")
    var user: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        titleSubscriptionID: TitleSubscription.IDValue,
        expirationDate: Date,
        userID: User.IDValue,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.$titleSubscription.id = titleSubscriptionID
        self.expirationDate = expirationDate
        self.$user.id = userID
        self.createdAt = createdAt
    }
    
}

extension Subscription {
    struct Input: Content {
        var id: UUID?
        var titleSubscriptionID: TitleSubscription.IDValue
        var expirationDate: Date
        var userID: User.IDValue
    }
}

extension Subscription {
    struct Output: Content {
        var id: UUID?
        var titleSubscription: TitleSubscription
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
