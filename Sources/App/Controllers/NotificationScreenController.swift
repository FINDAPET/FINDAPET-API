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
        
        userTokenProtected.get("all", ":countryCode", use: self.index(req:))
        userTokenProtected.get(":notificationScreenID", use: self.notificationScreen(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":notificationScreenID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [NotificationScreen.Output] {
        _ = try req.auth.require(User.self)
        var outputs = [NotificationScreen.Output]()
        
        guard let countryCode = req.parameters.get("countryCode") else {
            throw Abort(.badRequest)
        }
        
        for notificationScreen in try await NotificationScreen.query(on: req.db).all().filter({ $0.countryCode == countryCode }) {
            outputs.append(.init(
                id: notificationScreen.id,
                backgroundImageData: (try? await FileManager.get(req: req, with: notificationScreen.backgroundImagePath)) ?? .init(),
                title: notificationScreen.title,
                text: notificationScreen.text,
                buttonTitle: notificationScreen.buttonTitle,
                textColorHEX: notificationScreen.textColorHEX,
                buttonTitleColorHEX: notificationScreen.buttonTitleColorHEX,
                buttonColorHEX: notificationScreen.buttonTitleColorHEX,
                isRequired: notificationScreen.isRequired
            ))
        }
        
        return outputs
    }
    
    private func notificationScreen(req: Request) async throws -> NotificationScreen.Output {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
                
        guard let notificationScreen = try await NotificationScreen.find(req.parameters.get("notificationScreenID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return .init(
            id: notificationScreen.id,
            backgroundImageData: try await FileManager.get(req: req, with: notificationScreen.backgroundImagePath) ?? .init(),
            title: notificationScreen.title,
            text: notificationScreen.text,
            buttonTitle: notificationScreen.buttonTitle,
            textColorHEX: notificationScreen.textColorHEX,
            buttonTitleColorHEX: notificationScreen.buttonTitleColorHEX,
            buttonColorHEX: notificationScreen.buttonTitleColorHEX,
            isRequired: notificationScreen.isRequired
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(NotificationScreen.Input.self)
        let path = req.application.directory.publicDirectory + UUID().uuidString
        
        try await FileManager.set(req: req, with: path, data: input.backgroundImageData)
        try await NotificationScreen(
            id: input.id,
            countryCode: input.countryCode,
            backgroundImagePath: path,
            title: input.title,
            text: input.text,
            buttonTitle: input.buttonTitle,
            textColorHEX: input.textColorHEX,
            buttonTitleColorHEX: input.buttonTitleColorHEX,
            buttonColorHEX: input.buttonColorHEX,
            isRequired: input.isRequired
        ).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(NotificationScreen.Input.self)
        
        guard let notificationScreen = try await NotificationScreen.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await FileManager.set(req: req, with: notificationScreen.backgroundImagePath, data: input.backgroundImageData)
        
        notificationScreen.countryCode = input.countryCode
        notificationScreen.title = input.title
        notificationScreen.text = input.text
        notificationScreen.textColorHEX = input.textColorHEX
        notificationScreen.buttonColorHEX = input.buttonColorHEX
        notificationScreen.buttonTitle = input.buttonTitle
        notificationScreen.buttonTitleColorHEX = input.buttonTitleColorHEX
        
        try await notificationScreen.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let notificationScreen = try await NotificationScreen.find(req.parameters.get("notificationScreenID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await notificationScreen.delete(on: req.db)
        try await FileManager.set(req: req, with: notificationScreen.backgroundImagePath, data: .init())
        
        return .ok
    }
    
}
