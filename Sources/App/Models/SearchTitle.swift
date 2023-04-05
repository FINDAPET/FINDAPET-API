//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 12.03.2023.
//

import Foundation
import Vapor
import Fluent

final class SearchTitle: Model, Content {
    
    static let schema = "search_titles"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, title: String, userID: User.IDValue, createdAt: Date? = nil) {
        self.id = id
        self.title = title
        self.$user.id = userID
        self.$createdAt.timestamp = createdAt
    }
    
}

extension SearchTitle {
    struct Input: Content {
        var id: UUID?
        var title: String
        var userID: User.IDValue
    }
}

extension SearchTitle {
    struct Output: Content {
        var id: UUID?
        var title: String
        var user: User
    }
}

extension SearchTitle: Equatable {
    static func == (lhs: SearchTitle, rhs: SearchTitle) -> Bool {
        lhs.id == rhs.id
    }
}
