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
    var text: String?
    
    @Field(key: "is_viewed")
    var isViewed: Bool
    
    @OptionalField(key: "body_path")
    var bodyPath: String?
    
    @Timestamp(key: "created_at", on: .create, format: .iso8601(withMilliseconds: true))
    var createdAt: Date?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "chat_room_id")
    var chatRoom: ChatRoom
    
    init() { }
    
    init(id: UUID? = nil, text: String? = nil, isViewed: Bool = false, bodyPath: String? = nil, createdAt: Date? = nil, userID: User.IDValue, chatRoomID: ChatRoom.IDValue) {
        self.id = id
        self.text = text
        self.isViewed = isViewed
        self.bodyPath = bodyPath
        self.$user.id = userID
        self.$chatRoom.id = chatRoomID
        
        guard let createdAt else { return }
        
        self.$createdAt.timestamp = ISO8601DateFormatter().string(from: createdAt)
    }
    
}

extension Message {
    struct Input: Content {
        var id: UUID?
        var text: String?
        var isViewed: Bool
        var bodyData: Data?
        var userID: User.IDValue
        var chatRoomID: ChatRoom.IDValue?
        
        init(
            id: UUID? = nil,
            text: String? = nil,
            isViewed: Bool = false,
            bodyData: Data? = nil,
            userID: User.IDValue,
            chatRoomID: ChatRoom.IDValue? = nil
        ) {
            self.id = id
            self.text = text
            self.isViewed = isViewed
            self.bodyData = bodyData
            self.userID = userID
            self.chatRoomID = chatRoomID
        }
    }
}

extension Message {
    struct Output: Content {
        var id: UUID?
        var text: String?
        var isViewed: Bool
        var bodyData: Data?
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
