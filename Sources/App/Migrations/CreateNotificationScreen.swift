//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.12.2022.
//

import Foundation
import Fluent

struct CreateNotificationScreen: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(NotificationScreen.schema)
            .id()
            .field("background_image_path", .string)
            .field("title", .string)
            .field("text", .string)
            .field("button_title", .string)
            .field("text_color_hex", .string)
            .field("button_title_color_hex", .string)
            .field("button_color_hex", .string)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(NotificationScreen.schema).delete()
    }
    
}
