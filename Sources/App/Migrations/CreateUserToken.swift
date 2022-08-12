//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Fluent

struct CreateUserToken: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(UserToken.schema)
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required)
            .unique(on: "value")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(UserToken.schema).delete()
    }
    
}
