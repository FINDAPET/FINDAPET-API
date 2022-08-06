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
            .field("tags", .array(of: .string))
            .field("is_premium_deal", .bool)
            .field("is_active", .bool)
            .field("views_count", .int16)
            .field("mode", .string, .required)
            .field("pet_type", .string, .required)
            .field("pet_breed", .string, .required)
            .field("show_class", .string, .required)
            .field("is_male", .bool, .required)
            .field("age", .string, .required)
            .field("color", .string, .required)
            .field("price", .string, .required)
            .field("cattery_id", .uuid, .required)
            .field("country", .string)
            .field("city", .string)
            .field("description", .string)
            .field("whatsapp_number", .string)
            .field("telegram_username", .string)
            .field("instagram_username", .string)
            .field("facebook_username", .string)
            .field("vk_username", .string)
            .field("mail", .string)
            .field("buyer_id", .uuid)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Deal.schema).delete()
    }
    
}
