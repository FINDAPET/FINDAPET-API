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
        userTokenProtected.get("all", "dogs", use: self.dogs(req:))
        userTokenProtected.get("all", "cats", use: self.cats(req:))
    }
    
    private func index(req: Request) throws -> [String] {
        _ = try req.auth.require(User.self)
        
        return PetBreed.allCases.map { $0.rawValue }
    }
    
    private func cats(req: Request) throws -> [String] {
        _ = try req.auth.require(User.self)
        
        return PetBreed.allCatBreeds.map { $0.rawValue }
    }
    
    private func dogs(req: Request) throws -> [String] {
        _ = try req.auth.require(User.self)
        
        return PetBreed.allDogBreeds.map { $0.rawValue }
    }
    
}
