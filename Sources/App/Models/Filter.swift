//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 17.03.2023.
//

import Foundation
import Vapor

struct Filter: Content {
    var title: String?
    var petTypeID: PetType.IDValue?
    var petBreedID: PetBreed.IDValue?
    var petClass: PetClass?
    var isMale: Bool?
    var country: String?
    var city: String?
    var checkedIDs: [Deal.IDValue]
    
    init(
        title: String? = nil,
        petTypeID: PetType.IDValue? = nil,
        petBreedID: PetBreed.IDValue? = nil,
        petClass: PetClass? = nil,
        isMale: Bool? = nil,
        country: String? = nil,
        city: String? = nil,
        checkedIDs: [UUID] = .init()
    ) {
        self.title = title
        self.petTypeID = petTypeID
        self.petBreedID = petBreedID
        self.petClass = petClass
        self.isMale = isMale
        self.country = country
        self.city = city
        self.checkedIDs = checkedIDs
    }
}

//MARK: Extensions
extension Filter: Hashable { }
