//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Fluent

final class CreateUser: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("name", .string)
            .field("is_active_cattery", .bool)
            .field("chats_id", .array(of: .uuid))
            .field("avatar_path", .string)
            .field("document_path", .string)
            .field("description", .string)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
    
}
