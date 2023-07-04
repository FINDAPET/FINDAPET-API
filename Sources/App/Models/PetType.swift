//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 30.12.2022.
//

import Foundation
import Vapor
import Fluent

final class PetType: Model, Content {
    
    static let schema = "pet_types"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "localized_names")
    var localizedNames: [String : String]
    
    @Field(key: "image_path")
    var imagePath: String
    
    @Children(for: \.$petType)
    var petBreeds: [PetBreed]
    
    init() { }
    
    init(id: UUID? = nil, localizedNames: [String : String], imagePath: String) {
        self.id = id
        self.localizedNames = localizedNames
        self.imagePath = imagePath
    }
    
}

//MARK: Extensions
extension PetType {
    struct Input: Content {
        var id: PetType.IDValue?
        var localizedNames: [String : String]
        var imageData: Data
        
        init(id: PetType.IDValue? = nil, localizedNames: [String : String], imageData: Data) {
            self.id = id
            self.localizedNames = localizedNames
            self.imageData = imageData
        }
    }
}

extension PetType {
    struct Output: Content {
        var id: PetType.IDValue?
        var localizedNames: [String : String]
        var imageData: Data
        var petBreeds: [PetBreed]
    }
}

extension PetType: Equatable {
    static func == (lhs: PetType, rhs: PetType) -> Bool {
        lhs.id == rhs.id
    }
}
