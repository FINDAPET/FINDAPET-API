//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Vapor
import Fluent

final class ChatRoom: Model, Content {
    
    static let schema = "chat_rooms"
    
    @ID(custom: .id, generatedBy: .user)
    var id: String?
    
    @Field(key: "users_id")
    var usersID: [User.IDValue]
    
    @Children(for: \.$chatRoom)
    var messages: [Message]
    
    init() { }
    
    init(id: String? = nil, usersID: [User.IDValue] = .init()) {
        self.id = id
        self.usersID = usersID
    }
    
}

extension ChatRoom {
    struct Input: Content {
        var id: String?
        var usersID: [User.IDValue]
        
        init(id: String? = nil, usersID: [User.IDValue] = .init()) {
            self.id = id
            self.usersID = usersID
        }
    }
}

extension ChatRoom {
    struct Output: Content {
        var id: String?
        var users: [User.Output]
        var messages: [Message.Output]
    }
}

extension ChatRoom: Equatable {
    static func == (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        lhs.id == rhs.id
    }
}
