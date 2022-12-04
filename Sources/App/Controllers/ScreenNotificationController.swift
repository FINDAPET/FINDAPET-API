//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.12.2022.
//

import Foundation
import Vapor

struct NotificationScreenController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let notificationScreens = routes.grouped("notification", "screens")
        let userTokenProtected = notificationScreens.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":notificationScreenID", use: self.notificationScreen(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":notificationScreenID", "delete", use: self.delete(req:))
    }
    
    func index(req: Request) async throws -> [NotificationScreen.Output] {
        _ = try req.auth.require(User.self)
        var outputs = [NotificationScreen.Output]()
        
        for notificationScreen in try await NotificationScreen.query(on: req.db).all() {
            var backgroundData: Data?
            
            if let path = notificationScreen.backgroundImagePath, let data = try? await FileManager.get(req: req, with: path) {
                backgroundData = data
            }
            
            outputs.append(.init(
                id: notificationScreen.id,
                backgroundImageData: backgroundData,
                title: notificationScreen.title,
                text: notificationScreen.text,
                buttonTitle: notificationScreen.buttonTitle,
                textColorHEX: notificationScreen.textColorHEX,
                buttonTitleColorHEX: notificationScreen.buttonTitleColorHEX,
                buttonColorHEX: notificationScreen.buttonTitleColorHEX
            ))
        }
        
        return outputs
    }
    
    func notificationScreen(req: Request) async throws -> NotificationScreen.Output {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        var backgroundData: Data?
        
        guard let notificationScreen = try await NotificationScreen.find(req.parameters.get("notificationScreenID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if let path = notificationScreen.backgroundImagePath, let data = try? await FileManager.get(req: req, with: path) {
            backgroundData = data
        }
        
        return .init(
            id: notificationScreen.id,
            backgroundImageData: backgroundData,
            title: notificationScreen.title,
            text: notificationScreen.text,
            buttonTitle: notificationScreen.buttonTitle,
            textColorHEX: notificationScreen.textColorHEX,
            buttonTitleColorHEX: notificationScreen.buttonTitleColorHEX,
            buttonColorHEX: notificationScreen.buttonTitleColorHEX
        )
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(NotificationScreen.Input.self)
        let path = req.application.directory.publicDirectory + UUID().uuidString
        
        if let data = input.backgroundImageData {
            try await FileManager.set(req: req, with: path, data: data)
        }
        
        try await NotificationScreen(
            id: input.id,
            backgroundImagePath: path,
            title: input.title,
            text: input.text,
            buttonTitle: input.buttonTitle,
            textColorHEX: input.textColorHEX,
            buttonTitleColorHEX: input.buttonTitleColorHEX,
            buttonColorHEX: input.buttonColorHEX
        ).save(on: req.db)
        
        return .ok
    }
    
    func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(NotificationScreen.Input.self)
        
        guard let notificationScreen = try await NotificationScreen.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let path = notificationScreen.backgroundImagePath ?? (req.application.directory.publicDirectory + UUID().uuidString)
        
        if let data = input.backgroundImageData {
            try await FileManager.set(req: req, with: path, data: data)
        }
        
        notificationScreen.title = input.title
        notificationScreen.text = input.text
        notificationScreen.textColorHEX = input.textColorHEX
        notificationScreen.backgroundImagePath = path
        notificationScreen.buttonColorHEX = input.buttonColorHEX
        notificationScreen.buttonTitle = input.buttonTitle
        notificationScreen.buttonTitleColorHEX = input.buttonTitleColorHEX
        
        try await notificationScreen.save(on: req.db)
        
        return .ok
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let notificationScreen = try await NotificationScreen.find(req.parameters.get("notificationScreenID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await notificationScreen.delete(on: req.db)
        
        return .ok
    }
    
}
