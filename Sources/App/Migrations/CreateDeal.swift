//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Fluent

struct CreateDeal: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Deal.schema)
            .id()
            .field("title", .string, .required)
            .field("photo_paths", .array(of: .string), .required)
            .field("tags", .string)
            .field("is_premium_deal", .bool)
            .field("is_active", .bool)
            .field("views_count", .int16)
            .field("mode", .string, .required)
            .field("pet_type_id", .uuid, .required, .references(PetType.schema, "id"))
            .field("pet_breed_id", .uuid, .required, .references(PetBreed.schema, "id"))
            .field("pet_class", .string, .required)
            .field("is_male", .bool, .required)
            .field("birth_date", .date, .required)
            .field("color", .string, .required)
            .field("price", .double, .required)
            .field("currency_name", .string, .required)
            .field("score", .int16)
            .field("cattery_id", .uuid, .references(User.schema, "id"), .required)
            .field("country", .string)
            .field("city", .string)
            .field("description", .string)
            .field("buyer_id", .uuid, .references(User.schema, "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Deal.schema).delete()
    }
    
}
