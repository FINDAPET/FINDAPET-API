//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Fluent

struct CreateAd: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Ad.schema)
            .id()
            .field("content_path", .string, .required)
            .field("is_active", .bool)
            .field("customer_name", .string)
            .field("link", .string)
            .field("cattery_id", .uuid)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Ad.schema).delete()
    }
    
}
