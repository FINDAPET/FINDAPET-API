//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 30.12.2022.
//

import Foundation
import Fluent

struct CreatePetBreed: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(PetBreed.schema)
            .id()
            .field("name", .string, .required)
            .field("pet_type_id", .uuid, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(PetBreed.schema).delete()
    }
    
}
