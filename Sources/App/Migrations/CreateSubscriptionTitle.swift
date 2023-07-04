//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.04.2023.
//

import Foundation
import Fluent

struct CreateTitleSubscription: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(TitleSubscription.schema)
            .id()
            .field("localized_title", .dictionary(of: .string), .required)
            .field("price", .double, .required)
            .field("months_count", .int8, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(TitleSubscription.schema).delete()
    }
    
}
