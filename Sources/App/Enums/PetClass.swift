//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 13.11.2022.
//

import Foundation
import Vapor

enum PetClass: String, Content, CaseIterable {
    case showClass = "Show Class"
    case breedClass = "Breed Class"
    case allClass = "Show/Breed Class"
    
    static func get(_ str: String) -> PetClass? {
        for petClass in PetClass.allCases {
            if petClass.rawValue == str {
                return petClass
            }
        }
        
        return nil
    }
}
