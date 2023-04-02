//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 06.10.2022.
//

import Foundation
import Vapor
import APNS

struct MessageController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let messages = routes.grouped("messages")
        let userTokenProtected = messages.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", "admin", use: self.index(req:))
        userTokenProtected.get("all", ":chatRoomID", use: self.chatRoomMessages(req:))
        userTokenProtected.get(":chatRoomID", ":messageID", use: self.chatRoomMessage(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete("delete", ":messageID", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [Message] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        return try await Message.query(on: req.db).all()
    }
    
    private func chatRoomMessages(req: Request) async throws -> [Message.Output] {
        let user = try req.auth.require(User.self)
        var messages = [Message.Output]()
        
        guard let chatRoom = try await ChatRoom.find(req.parameters.get("chatRoomID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard chatRoom.usersID.contains(where: { $0 == user.id }) || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        for message in (try? await chatRoom.$messages.get(on: req.db)) ?? [Message]() {
            if let messageUser = try? await message.$user.get(on: req.db) {
                messages.append(Message.Output(
                    id: message.id,
                    text: message.text,
                    isViewed: message.isViewed,
                    user: User.Output(
                        id: messageUser.id,
                        name: messageUser.name,
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output](),
                        score: .zero,
                        isPremiumUser: messageUser.isPremiumUser
                    ),
                    createdAt: message.$createdAt.timestamp,
                    chatRoom: ChatRoom.Output(users: [User.Output](), messages: [Message.Output]())
                ))
            }
        }
        
        return messages
    }
    
    private func chatRoomMessage(req: Request) async throws -> Message.Output {
        let user = try req.auth.require(User.self)
        
        guard let chatRoom = try await ChatRoom.find(req.parameters.get("chatRoomID"), on: req.db),
              let message = try await Message.find(req.parameters.get("messageID"), on: req.db)else {
            throw Abort(.notFound)
        }
        
        guard chatRoom.usersID.contains(where: { $0 == user.id }) || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        let messageUser = try await message.$user.get(on: req.db)
        
        return Message.Output(
            id: message.id,
            text: message.text,
            isViewed: message.isViewed,
            user: User.Output(
                id: messageUser.id,
                name: messageUser.name,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                score: .zero,
                isPremiumUser: messageUser.isPremiumUser
            ),
            createdAt: message.$createdAt.timestamp,
            chatRoom: ChatRoom.Output(users: [User.Output](), messages: [Message.Output]())
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let message = try req.content.decode(Message.Input.self)
        
        guard let chatRoom = try await ChatRoom.find(message.chatRoomID, on: req.db),
              chatRoom.usersID.contains(where: { $0 == user.id }) else {
            throw Abort(.badRequest)
        }
        
        if let secondUser = try? await User.find(chatRoom.usersID.first { $0 != user.id }, on: req.db) {
            for deviceToken in secondUser.deviceTokens {
                _ = req.apns.send(.init(title: user.name, subtitle: "Sent you a new message"), to: deviceToken)
            }
        }
        
        var bodyPath: String?
        
        if let bodyData = message.bodyData {
            bodyPath = req.application.directory.publicDirectory.appending(UUID().uuidString)
            
            try await FileManager.set(req: req, with: bodyPath ?? .init(), data: bodyData)
        }
        
        try await Message(
            text: message.text,
            bodyPath: bodyPath,
            userID: message.userID,
            chatRoomID: message.chatRoomID ?? .init()
        ).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let newMessage = try req.content.decode(Message.Input.self)
        
        guard let oldMessage = try await Message.find(newMessage.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard /*(try? await oldMessage.$user.get(on: req.db).id) == user.id || */user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        oldMessage.text = newMessage.text
        
        try await oldMessage.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let message = try await Message.find(req.parameters.get("messageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await message.delete(on: req.db)
        
        if let path = message.bodyPath {
            try await FileManager.set(req: req, with: path, data: .init())
        }
        
        return .ok
    }
    
}
