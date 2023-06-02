//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.12.2022.
//

import Foundation
import Vapor
import Fluent

final class Complaint: Model, Content {
    
    static let schema = "complaints"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "text")
    var text: String
    
    @Parent(key: "sender_id")
    var sender: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @OptionalParent(key: "deal_id")
    var deal: Deal?
    
    @OptionalParent(key: "user_id")
    var user: User?
    
    init() { }
    
    init(
        id: UUID? = nil,
        text: String,
        senderID: User.IDValue,
        createdAt: Date? = nil,
        dealID: Deal.IDValue? = nil,
        userID: User.IDValue? = nil
    ) {
        self.id = id
        self.text = text
        self.$sender.id = senderID
        self.createdAt = createdAt
        self.$deal.id = dealID
        self.$user.id = userID
    }
    
}

extension Complaint {
    struct Input: Content {
        var id: UUID?
        var text: String
        var senderID: User.IDValue
        var dealID: Deal.IDValue?
        var userID: User.IDValue?
    }
}

extension Complaint {
    struct Output: Content {
        var id: UUID?
        var text: String
        var sender: User.Output
        var createdAt: Date?
        var deal: Deal.Output?
        var user: User.Output?
    }
}

extension Complaint: Equatable {
    static func == (lhs: Complaint, rhs: Complaint) -> Bool {
        lhs.id == rhs.id
    }
}
