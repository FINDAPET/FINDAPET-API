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
            .field("avatar_path", .string)
            .field("document_path", .string)
            .field("description", .string)
            .field("is_cattery_wait_verify", .bool)
            .field("is_admin", .bool)
            .field("country_code", .string)
            .field("chat_rooms_id", .array(of: .string))
            .field("basic_currency_name", .string)
            .field("score", .int16)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
    
}
