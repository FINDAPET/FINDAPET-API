//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.10.2022.
//

import Foundation
import Fluent
import Vapor

final class Message: Model, Content {
    
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "text")
    var text: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "chat_room_id")
    var chatRoom: ChatRoom
    
    init() { }
    
    init(id: UUID? = nil, text: String, createdAt: Date? = nil, userID: User.IDValue, chatRoomID: User.IDValue) {
        self.id = id
        self.text = text
        self.$createdAt.timestamp = createdAt
        self.$user.id = userID
        self.$chatRoom.id = chatRoomID
    }
    
}

extension Message {
    struct Input: Content {
        var id: UUID?
        var text: String
        var userID: User.IDValue
        var chatRoomID: ChatRoom.IDValue
        
        init(id: UUID? = nil, text: String, userID: User.IDValue, chatRoomID: ChatRoom.IDValue) {
            self.id = id
            self.text = text
            self.userID = userID
            self.chatRoomID = chatRoomID
        }
    }
}

extension Message {
    struct Output: Content {
        var id: UUID?
        var text: String
        var user: User.Output
        var createdAt: Date?
        var chatRoom: ChatRoom.Output
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
