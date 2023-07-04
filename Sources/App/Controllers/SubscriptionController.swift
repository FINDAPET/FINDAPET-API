//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.04.2023.
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
        userTokenProtected.put(":subscriptionID", "admin", use: self.changeAdmin(req:))
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
                titleSubscription: try await subscription.$titleSubscription.get(on: req.db),
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
            titleSubscription: try await subscription.$titleSubscription.get(on: req.db),
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
        
        guard let user = try await User.find(subscription.userID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await user.$subscrtiption.create(
            .init(
                titleSubscriptionID: subscription.titleSubscriptionID,
                expirationDate: subscription.expirationDate,
                userID: subscription.userID
            ),
            on: req.db
        )
        
        for deal in (try? await user.$deals.get(on: req.db)) ?? .init() {
            deal.score *= 2
            try? await deal.save(on: req.db)
        }
        
        return .ok
    }
    
    private func changeAdmin(req: Request) async throws -> HTTPStatus {
        let newSub = try req.content.decode(Subscription.Input.self)
        
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let user = try await User.find(req.parameters.get("subscriptionID"), on: req.db),
              let oldSub = try await user.$subscrtiption.get(on: req.db) else {
            throw Abort(.notFound)
        }
        
        oldSub.$titleSubscription.id = newSub.titleSubscriptionID
        oldSub.expirationDate = newSub.expirationDate
        
        try await user.$subscrtiption.create(oldSub, on: req.db)
        
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
