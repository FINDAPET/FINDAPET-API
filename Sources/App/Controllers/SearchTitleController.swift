//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 12.03.2023.
//

import Foundation
import Vapor

struct SearchTitleController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let searchTitles = routes.grouped("search", "titles")
        let userTokenProtected = searchTitles.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":searchTitleID", use: self.searchTitle(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":searchTitleID", "delete", use: self.delete(req:))
    }
    
//    MARK: - Index
    private func index(req: Request) async throws -> [SearchTitle.Output] {
        var outputs = [SearchTitle.Output]()
        
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
                
        for title in try await SearchTitle.query(on: req.db).all() {
            outputs.append(.init(id: title.id, title: title.title, user: try await title.$user.get(on: req.db)))
        }
        
        return outputs
    }
    
//    MARK: Search Title
    private func searchTitle(req: Request) async throws -> SearchTitle.Output {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let searchTitle = try await SearchTitle.find(req.parameters.get("searchTitleID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return .init(id: searchTitle.id, title: searchTitle.title, user: try await searchTitle.$user.get(on: req.db))
    }
    
//    MARK: Create
    private func create(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let searchTitle = try req.content.decode(SearchTitle.Input.self)
        
        guard searchTitle.userID == user.id || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        try await SearchTitle(title: searchTitle.title, userID: searchTitle.userID).save(on: req.db)
        
        return .ok
    }
    
//    MARK: Change
    private func change(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let searchTitle = try req.content.decode(SearchTitle.Input.self)
        
        guard user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let old = try await SearchTitle.find(searchTitle.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        old.title = searchTitle.title
        old.$user.id = searchTitle.userID
        
        try await old.save(on: req.db)
        
        return .ok
    }
    
//    MARK: Delete
    private func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let searchTitle = try await SearchTitle.find(req.parameters.get("searchTitleID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard try await searchTitle.$user.get(on: req.db).id == user.id || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        try await searchTitle.delete(on: req.db)
        
        return .ok
    }
    
}
