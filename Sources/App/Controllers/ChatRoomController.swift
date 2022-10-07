//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 06.10.2022.
//

import Foundation
import Vapor

struct ChatRoomController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let chats = routes.grouped("chats")
        let userTokenProtected = chats.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", "admin", use: self.index(req:))
        userTokenProtected.get("all", use: self.userChats(req:))
        userTokenProtected.get(":chatRoomID", use: self.chatRoom(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete("delete", ":chatRoomID", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [ChatRoom] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        return try await ChatRoom.query(on: req.db).all()
    }
    
    private func userChats(req: Request) async throws -> [ChatRoom.Output] {
        let user = try req.auth.require(User.self)
        var chatRooms = [ChatRoom.Output]()
        
        for chatRoomID in user.chatRoomsID {
            var messages = [Message.Output]()
            var users = [User.Output]()
            
            if let chatRoom = try? await ChatRoom.find(chatRoomID, on: req.db) {
                for message in (try? await chatRoom.$messages.get(on: req.db)) ?? [Message]() {
                    if let messageUser = try? await message.$user.get(on: req.db) {
                        messages.append(Message.Output(
                            id: message.id,
                            text: message.text,
                            user: User.Output(
                                id: messageUser.id,
                                name: messageUser.name,
                                deals: [Deal.Output](),
                                boughtDeals: [Deal.Output](),
                                ads: [Ad.Output](),
                                myOffers: [Offer.Output](),
                                offers: [Offer.Output](),
                                chatRooms: [ChatRoom.Output]()
                            ),
                            createdAt: message.$createdAt.timestamp,
                            chatRoom: ChatRoom.Output(users: [User.Output](), messages: [Message.Output]())
                        ))
                    }
                }
                
                for userID in chatRoom.usersID {
                    if let chatUser = try? await User.find(userID, on: req.db) {
                        var avatarData: Data?
                        
                        if let path = chatUser.avatarPath,
                           let buffer = try? await req.fileio.collectFile(at: path) {
                            avatarData = Data(buffer: buffer)
                        }
                        
                        users.append(User.Output(
                            id: chatUser.id,
                            name: chatUser.name,
                            avatarData: avatarData,
                            deals: [Deal.Output](),
                            boughtDeals: [Deal.Output](),
                            ads: [Ad.Output](),
                            myOffers: [Offer.Output](),
                            offers: [Offer.Output](),
                            chatRooms: [ChatRoom.Output]()
                        ))
                    }
                }
                
                chatRooms.append(ChatRoom.Output(
                    id: chatRoom.id,
                    users: users,
                    messages: messages
                ))
            }
        }
        
        return chatRooms
    }
    
    private func chatRoom(req: Request) async throws -> ChatRoom.Output {
        let user = try req.auth.require(User.self)
        var messages = [Message.Output]()
        var users = [User.Output]()
        
        guard let chatRoom = try? await ChatRoom.find(req.parameters.get("chatRoomID"), on: req.db) else {
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
                    user: User.Output(
                        id: messageUser.id,
                        name: messageUser.name,
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output]()
                    ),
                    createdAt: message.$createdAt.timestamp,
                    chatRoom: ChatRoom.Output(users: [User.Output](), messages: [Message.Output]())
                ))
            }
        }
        
        for userID in chatRoom.usersID {
            if let chatUser = try? await User.find(userID, on: req.db) {
                var avatarData: Data?
                
                if let path = chatUser.avatarPath,
                   let buffer = try? await req.fileio.collectFile(at: path) {
                    avatarData = Data(buffer: buffer)
                }
                
                users.append(User.Output(
                    id: chatUser.id,
                    name: chatUser.name,
                    avatarData: avatarData,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output]()
                ))
            }
        }
        
        return ChatRoom.Output(
            id: chatRoom.id,
            users: users,
            messages: messages
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let chatRoom = try req.content.decode(ChatRoom.Input.self)
        
        try await ChatRoom(usersID: chatRoom.usersID).save(on: req.db)
        
        if let chatRoomID = try await ChatRoom.query(on: req.db).all().filter({ $0.usersID == chatRoom.usersID }).first?.id {
            user.chatRoomsID.append(chatRoomID)
            
            try await user.save(on: req.db)
        }
                
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let newChatRoom = try req.content.decode(ChatRoom.Input.self)
        
        guard let oldChatRoom = try await ChatRoom.find(newChatRoom.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        oldChatRoom.usersID = newChatRoom.usersID
        
        try await oldChatRoom.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let chatRoom = try await ChatRoom.find(req.parameters.get("chatRoomID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chatRoom.delete(on: req.db)
        
        return .ok
    }
    
}
