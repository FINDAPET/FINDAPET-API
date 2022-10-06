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
            .field("text", .string, .required)
            .field("created_at", .date)
            .field("updated_at", .date)
            .field("user_id", .uuid, .required)
            .field("chat_room_id", .uuid, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Message.schema).delete()
    }
    
}
