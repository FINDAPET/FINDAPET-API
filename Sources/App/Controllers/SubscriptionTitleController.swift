//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.04.2023.
//

import Foundation
import Vapor

struct TitleSubscriptionController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let titleSubscriptions = routes.grouped("title", "subscriptions")
        let userTokenProtected = titleSubscriptions.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":titleSubscriptionID", use: self.titleSubscription(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":titleSubscriptionID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [TitleSubscription] {
        let basicCurrencyName = try req.auth.require(User.self).basicCurrencyName
        let titleSubscriptions = try await TitleSubscription.query(on: req.db).all()
        
        for i in .zero ..< titleSubscriptions.count {
            titleSubscriptions[i].price = .init(try await CurrencyConverter.convert(
                req,
                from: Currency.USD.rawValue,
                to: basicCurrencyName,
                amount: .init(titleSubscriptions[i].price)
            ).result)
        }
        
        return titleSubscriptions
    }
    
    private func titleSubscription(req: Request) async throws -> TitleSubscription {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let titleSubscription = try await TitleSubscription.find(
            req.parameters.get("titleSubscriptionID"),
            on: req.db
        ) else {
            throw Abort(.notFound)
        }
        
        return titleSubscription
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        try await req.content.decode(TitleSubscription.self).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        let input = try req.content.decode(TitleSubscription.self)
        
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
                
        guard let titleSubscription = try await TitleSubscription.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        titleSubscription.localizedTitle = input.localizedTitle
        titleSubscription.price = input.price
        titleSubscription.monthsCount = input.monthsCount
        
        try await titleSubscription.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let titleSubscription = try await TitleSubscription.find(
            req.parameters.get("titleSubscriptionID"),
            on: req.db
        ) else {
            throw Abort(.notFound)
        }
        
        try await titleSubscription.delete(on: req.db)
        
        return .ok
    }
    
}
