//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.12.2022.
//

import Foundation
import Vapor

struct PetBreedController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let dealModel = routes.grouped("pet", "breeds")
        let userTokenProtected = dealModel.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
    }
    
    func index(req: Request) throws -> [PetBreed] {
        _ = try req.auth.require(User.self)
        
        return PetBreed.allCases
    }
    
}
