//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 12.03.2023.
//

import Foundation
import Fluent

struct CreateSearchTitle: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(SearchTitle.schema)
            .id()
            .field("title", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, .id))
            .field("created_at", .date)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(SearchTitle.schema).delete()
    }
    
}
