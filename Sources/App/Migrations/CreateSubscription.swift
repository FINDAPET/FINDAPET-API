//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.04.2023.
//

import Foundation
import Fluent

struct CreateSubscription: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Subscription.schema)
            .id()
            .field("title_subscription_id", .uuid, .required, .references(TitleSubscription.schema, .id))
            .field("expiration_date", .date, .required)
            .field("user_id", .uuid, .required, .references(User.schema, .id))
            .field("created_at", .date)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Subscription.schema).delete()
    }
    
}
