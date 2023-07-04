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
        userTokenProtected.get(":petBreedID", use: self.petBreed(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":petBreedID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [PetBreed.Output] {
        try req.auth.require(User.self)
        
        var petBreeds = [PetBreed.Output]()
        
        for petBreed in try await PetBreed.query(on: req.db).all() {
            let petType = try await petBreed.$petType.get(on: req.db)
            
            petBreeds.append(.init(id: petBreed.id, name: petBreed.name, petType: petType))
        }
        
        return petBreeds
    }
    
    private func petBreed(req: Request) async throws -> PetBreed.Output {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let petBreed = try await PetBreed.find(req.parameters.get("petBreedID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return .init(id: petBreed.id, name: petBreed.name, petType: try await petBreed.$petType.get(on: req.db))
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let petBreed = try req.content.decode(PetBreed.Input.self)
        
        try await PetBreed(name: petBreed.name, petTypeID: petBreed.petTypeID).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(PetBreed.Input.self)
        
        guard let petBreed = try await PetBreed.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        petBreed.name = input.name
        petBreed.$petType.id = input.petTypeID
        
        try await petBreed.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let petBreed = try await PetBreed.find(req.parameters.get("petBreedID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await petBreed.delete(on: req.db)
        
        return .ok
    }
    
}
