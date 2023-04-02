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
                    for deviceToken in user.deviceTokens {
                        _ = req.apns.send(.init(title: notification.title), to: deviceToken)
                    }
                }
            }
        } else {
            for user in try await User.query(on: req.db).all() {
                for deviceToken in user.deviceTokens {
                    _ = req.apns.send(.init(title: notification.title), to: deviceToken)
                }
            }
        }
        
        return .ok
    }
    
    private func sendToUser(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let notification = try req.content.decode(Notification.self)
        
        for userID in notification.usersID {
            for deviceToken in (try? await User.find(userID, on: req.db)?.deviceTokens) ?? .init() {
                _ = req.apns.send(.init(title: notification.title), to: deviceToken)
            }
        }
        
        return .ok
    }
    
}
