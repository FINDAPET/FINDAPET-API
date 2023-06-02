//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.05.2023.
//

import Foundation
import Vapor

struct DeviceTokenController: RouteCollection {
    
//    MARK: - Boot
    func boot(routes: RoutesBuilder) throws {
        let deviceTokens = routes.grouped("device", "tokens")
        let userTokenProtected = deviceTokens.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":deviceTokenID", use: self.deviceToken(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":deviceTokenID", "delete", use: self.delete(req:))
    }
    
//    MARK: - Index
    private func index(req: Request) async throws -> [DeviceToken.Output] {
        guard try req.auth.require(User.self).isAdmin else { throw Abort(.badRequest) }
        
        var tokens = [DeviceToken.Output]()
        
        for token in try await DeviceToken.query(on: req.db).all() {
            tokens.append(.init(
                id: token.id,
                value: token.value,
                platform: .get(token.platform),
                user: try await token.$user.get(on: req.db)
            ))
        }
        
        return tokens
    }
    
//    MARK: - Device Token
    private func deviceToken(req: Request) async throws -> DeviceToken.Output {
        guard try req.auth.require(User.self).isAdmin else { throw Abort(.badRequest) }
        guard let token = try await DeviceToken.find(req.parameters.get("deviceTokenID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return .init(
            id: token.id,
            value: token.value,
            platform: .get(token.platform),
            user: try await token.$user.get(on: req.db)
        )
    }
    
//    MARK: - Create
    private func create(req: Request) async throws -> HTTPStatus {
        let input = try req.content.decode(DeviceToken.Input.self)
        
        guard input.userID == (try req.auth.require(User.self)).id else { throw Abort(.badRequest) }
        
        try await DeviceToken(value: input.value, platform: input.platform.value, userID: input.userID).save(on: req.db)
        
        return .ok
    }
    
//    MARK: - Change
    private func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else { throw Abort(.badRequest) }
        
        let input = try req.content.decode(DeviceToken.Input.self)
        
        guard let deviceToken = try await DeviceToken.find(input.id, on: req.db) else { throw Abort(.notFound) }
        
        deviceToken.value = input.value
        deviceToken.platform = input.platform.value
        deviceToken.$user.id = input.userID
        
        try await deviceToken.save(on: req.db)
        
        return .ok
    }
    
//    MARK: - Delete
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else { throw Abort(.badRequest) }
        guard let token = try await DeviceToken.find(req.parameters.get("deviceTokenID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await token.delete(on: req.db)
        
        return .ok
    }
    
}
