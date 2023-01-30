//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 22.01.2023.
//

import Foundation
import Vapor

struct SubscriptionController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let subscriptions = routes.grouped("subscriptions")
        let userTokenProtected = subscriptions.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":subscriptionID", use: self.subscription(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":subscriptionID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [Subscription.Output] {
        var outputs = [Subscription.Output]()
        
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badGateway)
        }
                
        let subscriptions = try await Subscription.query(on: req.db).all()
        
        for subscription in subscriptions {
            outputs.append(.init(
                id: subscription.id,
                localizedNames: subscription.localizedNames,
                expirationDate: subscription.expirationDate,
                user: try await subscription.$user.get(on: req.db),
                createdAt: subscription.createdAt
            ))
        }
        
        return outputs
    }
    
    private func subscription(req: Request) async throws -> Subscription.Output {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let subscription = try await Subscription.find(req.parameters.get("subscriptionID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return .init(
            id: subscription.id,
            localizedNames: subscription.localizedNames,
            expirationDate: subscription.expirationDate,
            user: try await subscription.$user.get(on: req.db),
            createdAt: subscription.createdAt
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).subscrtiption == nil else {
            throw Abort(.badRequest)
        }
        
        let subscription = try req.content.decode(Subscription.Input.self)
        
        try await Subscription(
                    localizedNames: subscription.localizedNames,
            expirationDate: subscription.expirationDate,
            userID: subscription.userID
        ).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(Subscription.Input.self)
        
        guard let subscription = try await Subscription.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        subscription.localizedNames = input.localizedNames
        subscription.expirationDate = input.expirationDate
        subscription.$user.id = input.userID
        
        try await subscription.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let subscription = try await Subscription.find(req.parameters.get("subsriptionID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await subscription.delete(on: req.db)
        
        return .ok
    }
        
}
