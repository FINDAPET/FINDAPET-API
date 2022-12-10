//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.12.2022.
//

import Foundation
import Vapor

struct DealModeController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let dealModel = routes.grouped("deal", "modes")
        let userTokenProtected = dealModel.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
    }
    
    func index(req: Request) throws -> [DealMode] {
        _ = try req.auth.require(User.self)
        
        return DealMode.allCases
    }
    
}
