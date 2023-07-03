//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.10.2022.
//

import Foundation
import Fluent

struct CreateMessage: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Message.schema)
            .id()
            .field("text", .string)
            .field("is_viewed", .bool)
            .field("body_path", .string)
            .field("created_at", .string)
            .field("user_id", .uuid, .required, .references(User.schema, .id))
            .field("chat_room_id", .string, .required, .references(ChatRoom.schema, .id))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Message.schema).delete()
    }
    
}
