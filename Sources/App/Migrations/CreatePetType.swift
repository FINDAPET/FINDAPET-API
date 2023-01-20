//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 30.12.2022.
//

import Foundation
import Fluent

final class CreatePetType: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(PetType.schema)
            .id()
            .field("localized_names", .dictionary(of: .string), .required)
            .field("image_path", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(PetType.schema).delete()
    }
    
}
