//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import Vapor
import Fluent

struct UserTokenController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userProtected = routes.grouped(User.authenticator())
        let userTokenProtected = routes.grouped(UserToken.authenticator())
        
        userProtected.get("auth", ":deviceToken", use: self.auth(req:))
        
        userTokenProtected.delete("logOut", ":deviceToken", use: self.logOut(req:))
    }
    
    private func auth(req: Request) async throws -> UserToken.Output {
        let id = UUID(uuidString: req.parameters.get("deviceToken") ?? .init())
        let user = try req.auth.require(User.self)
        let token = try user.generateToken(deviceID: id)
        
        if let id = id {
            for token in (try? await UserToken.query(on: req.db).filter(\.$deviceID == id).all()) ?? .init() {
                try await token.delete(on: req.db)
            }
        }
        
        try await token.save(on: req.db)
        
        return .init(id: token.id, value: token.value, user: user)
    }
    
    private func logOut(req: Request) async throws -> HTTPStatus {
        guard let id = UUID(uuidString: req.parameters.get("deviceToken") ?? .init()),
              let userID = try req.auth.require(User.self).id else {
            throw Abort(.notFound)
        }
                
        for token in try await UserToken.query(on: req.db).filter(\.$deviceID == id).filter(\.$user.$id == userID).all() {
            try await token.delete(on: req.db)
        }
        
        return .ok
    }
    
}
