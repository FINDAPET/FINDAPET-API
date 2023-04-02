//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.08.2022.
//

import Foundation
import Fluent

struct CreateOffer: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Offer.schema)
            .id()
            .field("price", .int64, .required)
            .field("currency_name", .string, .required)
            .field("buyer_id", .uuid, .required, .references(User.schema, "id"))
            .field("deal_id", .uuid, .required, .references(Deal.schema, "id"))
            .field("cattery_id", .uuid, .required, .references(User.schema, "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Offer.schema).delete()
    }
    
}
