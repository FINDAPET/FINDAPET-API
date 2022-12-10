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
}
