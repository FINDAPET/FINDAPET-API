//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.12.2022.
//

import Foundation
import Fluent

struct CreateComplaint: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Complaint.schema)
            .id()
            .field("text", .string, .required)
            .field("sender_id", .uuid, .required)
            .field("created_at", .date)
            .field("deal_id", .uuid)
            .field("user_id", .uuid)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Complaint.schema).delete()
    }
    
}
