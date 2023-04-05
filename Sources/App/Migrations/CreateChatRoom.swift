//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Fluent

struct CreateChatRoom: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(ChatRoom.schema)
            .field(.id, .string)
            .field("users_id", .array(of: .uuid))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(ChatRoom.schema).delete()
    }
    
}
