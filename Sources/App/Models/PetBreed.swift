//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 30.12.2022.
//

import Foundation
import Vapor
import Fluent

final class PetBreed: Model, Content {
    
    static let schema = "pet_breeds"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Parent(key: "pet_type_id")
    var petType: PetType
    
    init() { }
    
    init(id: UUID? = nil, name: String, petTypeID: PetType.IDValue) {
        self.id = id
        self.name = name
        self.$petType.id = petTypeID
    }
    
}

//MARK: Extensions
extension PetBreed {
    struct Input: Content {
        var id: PetBreed.IDValue?
        var name: String
        var petTypeID: PetType.IDValue
        
        init(id: PetBreed.IDValue? = nil, name: String, petTypeID: PetType.IDValue) {
            self.id = id
            self.name = name
            self.petTypeID = petTypeID
        }
    }
}

extension PetBreed {
    struct Output: Content {
        var id: PetBreed.IDValue?
        var name: String
        var petType: PetType
    }
}

extension PetBreed: Equatable {
    static func == (lhs: PetBreed, rhs: PetBreed) -> Bool {
        lhs.id == rhs.id
    }
}
