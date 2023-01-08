//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.12.2022.
//

import Foundation
import Vapor

struct PetTypeController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let dealModel = routes.grouped("pet", "types")
        let userTokenProtected = dealModel.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":petTypeID", use: self.petType(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":petTypeID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [PetType.Output] {
        _ = try req.auth.require(User.self)
        let petTypes = try await PetType.query(on: req.db).all()
        var output = [PetType.Output]()
        
        for petType in petTypes {
            guard let data = try? await FileManager.get(req: req, with: petType.imagePath) else {
                continue
            }
            
            output.append(.init(
                id: petType.id,
                localizedNames: petType.localizedNames,
                imageData: data,
                petBreeds: (try? await petType.$petBreeds.get(on: req.db)) ?? .init()
            ))
        }
        
        return output
    }
    
    private func petType(req: Request) async throws -> PetType.Output {
        _ = try req.auth.require(User.self)
        
        guard let petType = try await PetType.find(req.parameters.get("petTypeID"), on: req.db),
              let data = try await FileManager.get(req: req, with: petType.imagePath) else {
            throw Abort(.notFound)
        }
        
        return .init(
            id: petType.id,
            localizedNames: petType.localizedNames,
            imageData: data,
            petBreeds: try await petType.$petBreeds.get(on: req.db)
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(PetType.Input.self)
        let path = req.application.directory.publicDirectory.appending(UUID().uuidString)
        
        try await FileManager.set(req: req, with: path, data: input.imageData)
        try await PetType(localizedNames: input.localizedNames, imagePath: path).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(PetType.Input.self)
        
        guard let petType = try await PetType.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        petType.localizedNames = input.localizedNames
        
        try await FileManager.set(req: req, with: petType.imagePath, data: input.imageData)
        try await petType.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let petType = try await PetType.find(req.parameters.get("petTypeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await petType.delete(on: req.db)
        
        return .ok
    }
    
}
