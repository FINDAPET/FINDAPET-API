//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import NIOFoundationCompat
import Vapor

struct UserTokenController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userProtected = routes.grouped(User.authenticator())
        let userTokenProtected = routes.grouped(UserToken.authenticator())
        
        userProtected.get("auth", use: self.auth(req:))
        
        userTokenProtected.delete("logOut", use: self.logOut(req:))
    }
    
    private func auth(req: Request) async throws -> UserToken.Output {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
                
        try await token.save(on: req.db)
        
        return UserToken.Output(id: token.id, value: token.value, user: user)
    }
    
    private func logOut(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        for token in try await UserToken.query(on: req.db).all().filter({ $0.$user.id == user.id }) {
            try await token.delete(on: req.db)
        }
        
        return .ok
    }
    
}
