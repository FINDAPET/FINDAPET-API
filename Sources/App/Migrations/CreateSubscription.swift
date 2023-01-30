//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 22.01.2023.
//

import Foundation
import Fluent

struct CreateSubscription: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Subscription.schema)
            .id()
            .field("localized_names", .dictionary(of: .string), .required)
            .field("expiration_date", .date, .required)
            .field("user_id", .uuid, .required)
            .field("created_at", .date)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Subscription.schema).delete()
    }
    
}
