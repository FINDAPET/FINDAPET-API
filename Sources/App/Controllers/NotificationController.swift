//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 06.10.2022.
//

import Foundation
import Vapor

struct NotificationController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let notificatons = routes.grouped("notification")
        let userTokenProtected = notificatons.grouped(UserToken.authenticator())
        
        userTokenProtected.post("new", use: self.create(req:))
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let notification = try req.content.decode(Notification.self)
        
        if !notification.coutryCodes.isEmpty {
            for countryCode in notification.coutryCodes {
                for user in try await User.query(on: req.db).all().filter({ $0.countryCode == countryCode }) {
                    if let deviceToken = user.deviceToken {
                        try req.apns.send(.init(title: notification.title), to: deviceToken).wait()
                    }
                }
            }
        } else {
            for user in try await User.query(on: req.db).all() {
                if let deviceToken = user.deviceToken {
                    try req.apns.send(.init(title: notification.title), to: deviceToken).wait()
                }
            }
        }
        
        return .ok
    }
    
}
