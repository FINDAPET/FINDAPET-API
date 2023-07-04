//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.05.2023.
//

import Foundation
import Fluent

struct CreateDeviceToken: AsyncMigration {
    
//    MARK: - Prepare
    func prepare(on database: Database) async throws {
        try await database.schema(DeviceToken.schema)
            .id()
            .field("value", .string, .required)
            .field("platform", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, .id))
            .unique(on: "value")
            .create()
    }
    
//    MARK: - Revert
    func revert(on database: Database) async throws {
        try await database.schema(DeviceToken.schema).delete()
    }
    
}
