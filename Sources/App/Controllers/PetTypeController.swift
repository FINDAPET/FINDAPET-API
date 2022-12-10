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
    }
    
    private func index(req: Request) throws -> [String] {
        _ = try req.auth.require(User.self)
        
        return PetType.allCases.map { $0.rawValue }
    }
    
}
