//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Fluent

struct CreateChatRoom: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(ChatRoom.schema)
            .id()
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(ChatRoom.schema).delete()
    }
    
}
