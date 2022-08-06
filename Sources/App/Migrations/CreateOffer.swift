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
            .field("buyer_id", .uuid, .required)
            .field("deal_id", .uuid, .required)
            .field("cattery_id", .uuid, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Offer.schema).delete()
    }
    
}
