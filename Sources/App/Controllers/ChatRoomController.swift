//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 06.10.2022.
//

import Foundation
import Vapor
import Fluent

struct ChatRoomController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let chats = routes.grouped("chats")
        let userTokenProtected = chats.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", "admin", use: self.index(req:))
        userTokenProtected.get("all", use: self.userChats(req:))
        userTokenProtected.get(":chatRoomID", use: self.chatRoom(req:))
        userTokenProtected.get("chat", "with", ":userID", use: self.chatRoomWithUser(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put(":chatRoomID", "messages", "view", use: self.viewAllMessages(req:))
        userTokenProtected.webSocket(
            "with",
            ":userID",
            maxFrameSize: .init(integerLiteral: 1 << 24),
            onUpgrade: self.chatRoomWebSocket(req:ws:)
        )
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
                
                for userID in chatRoom.usersID {
                    if let chatUser = try? await User.find(userID, on: req.db) {
                        var avatarData: Data?
                        
                        if let path = chatUser.avatarPath {
                            avatarData = try? await FileManager.get(req: req, with: path)
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
                            chatRooms: [ChatRoom.Output](),
                            score: .zero,
                            isPremiumUser: chatUser.isPremiumUser
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
        
        for userID in chatRoom.usersID {
            if let chatUser = try? await User.find(userID, on: req.db) {
                var avatarData: Data?
                
                if let path = chatUser.avatarPath {
                    avatarData = try? await FileManager.get(req: req, with: path)
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
                    chatRooms: [ChatRoom.Output](),
                    score: .zero,
                    isPremiumUser: chatUser.isPremiumUser
                ))
            }
        }
        
        return ChatRoom.Output(
            id: chatRoom.id,
            users: users,
            messages: messages
        )
    }
    
    private func chatRoomWithUser(req: Request) async throws -> ChatRoom.Output {
        let user = try req.auth.require(User.self)
        var messages = [Message.Output]()
        var users = [User.Output]()
        
        guard let id = req.parameters.get("userID"),
              let chatRoom = try await ChatRoom.find(id + (user.id?.uuidString ?? .init()), on: req.db) else {
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
        
        for userID in chatRoom.usersID {
            if let chatUser = try? await User.find(userID, on: req.db) {
                var avatarData: Data?
                
                if let path = chatUser.avatarPath {
                    avatarData = try? await FileManager.get(req: req, with: path)
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
                    chatRooms: [ChatRoom.Output](),
                    score: .zero,
                    isPremiumUser: chatUser.isPremiumUser
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
        var id = String()
        
        for userID in chatRoom.usersID {
            id += userID.uuidString
        }
        
        guard !id.isEmpty else {
            throw Abort(.badRequest)
        }
        
        guard let secondUser = try await User.find(chatRoom.usersID.first { $0 != user.id }, on: req.db) else {
            throw Abort(.notFound)
        }
        
        user.chatRoomsID.append(id)
        secondUser.chatRoomsID.append(id)
        
        try await ChatRoom(id: id, usersID: chatRoom.usersID).save(on: req.db)
        try await secondUser.save(on: req.db)
        try await user.save(on: req.db)
        
        return .ok
    }
    
    private func viewAllMessages(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let chatRoom = try await ChatRoom.find(req.parameters.get("chatRoomID"), on: req.db), let userID = user.id else {
            throw Abort(.notFound)
        }
        
        guard chatRoom.usersID.contains(userID) || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        for message in try await chatRoom.$messages.get(on: req.db).filter({ !$0.isViewed }) {
            guard let id = try? await message.$user.get(on: req.db).id, id != userID else {
                continue
            }
            
            message.isViewed = true
            
            try? await message.save(on: req.db)
        }
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let chatRoom = try await ChatRoom.find(req.parameters.get("chatRoomID"), on: req.db),
              let firstUser = try await User.find(chatRoom.usersID.first, on: req.db),
              let secondUser = try await User.find(chatRoom.usersID.last, on: req.db),
              let id = chatRoom.id else {
            throw Abort(.notFound)
        }
        
        for message in try await chatRoom.$messages.get(on: req.db) {
            try? await message.delete(on: req.db)
        }
        
        firstUser.chatRoomsID.removeAll { $0 == id }
        secondUser.chatRoomsID.removeAll { $0 == id }
        
        try await chatRoom.delete(on: req.db)
        try await firstUser.save(on: req.db)
        try await secondUser.save(on: req.db)
        
        ChatRoomWebSocketManager.shared.removeChatRoomWebSocket(id: chatRoom.id)
        
        return .ok
    }
    
    private func chatRoomWebSocket(req: Request, ws: WebSocket) async {
        guard let firstUser = try? req.auth.require(User.self), let firstUserID = firstUser.id else {
            print("❌ Error: not autorized.")
            
            try? await ws.close()
            
            return
        }
        
        guard let secondUser = try? await User.find(req.parameters.get("userID"), on: req.db),
              let secondUserID = secondUser.id else {
            print("❌ Error: not found.")
            
            try? await ws.close()
            
            return
        }
        
        if (try? await ChatRoom.query(on: req.db).group(.or, {
            $0.filter(\.$id == firstUserID.uuidString + secondUserID.uuidString)
                .filter(\.$id == secondUserID.uuidString + firstUserID.uuidString)
        }).first()) == nil {
            do {
                let id = firstUserID.uuidString + secondUserID.uuidString
                
                try await ChatRoom(
                    id: id,
                    usersID: [firstUserID, secondUserID]
                ).save(on: req.db)
                
                firstUser.chatRoomsID.append(id)
                secondUser.chatRoomsID.append(id)
                
                try await firstUser.save(on: req.db)
                try await secondUser.save(on: req.db)
            } catch {
                print("❌ Error: \(error.localizedDescription)")
            }
        }
        
        guard let chatRoomID = try? await ChatRoom.query(on: req.db).group(.or, {
            $0.filter(\.$id == secondUserID.uuidString + firstUserID.uuidString)
                .filter(\.$id == firstUserID.uuidString + secondUserID.uuidString)
        }).first()?.id else {
            print("❌ Error: not found.")
            
            try? await ws.close()
            
            return
        }
        
        ws.onClose.whenSuccess {
            ChatRoomWebSocketManager.shared.removeUserWebSocketInChatRoom(chatRoomID: chatRoomID, userID: firstUserID.uuidString)
        }
        
        ws.onBinary { ws, buffer in
            var path: String?
            
            guard let input = try? JSONDecoder().decode(Message.Input.self, from: buffer) else {
                print("❌ Error: deconding failed.")
                
                return
            }
            
            if let data = input.bodyData {
                let newPath = req.application.directory.publicDirectory.appending(UUID().uuidString)
                
                try? await FileManager.set(req: req, with: newPath, data: data)

                path = newPath
            }
            
            let message = Message(text: input.text, bodyPath: path, userID: input.userID, chatRoomID: chatRoomID)
            
            do {
                try await message.save(on: req.db)
                
                if ChatRoomWebSocketManager.shared.chatRoomWebSockets.first(where: {
                    $0.id == chatRoomID
                })?.users.count ?? 2 < 2 {
                    for deviceToken in firstUser.deviceTokens {
                        _ = req.apns.send(
                            .init(title: firstUser.name, subtitle: "Sent you a new message"),
                            to: deviceToken
                        )
                    }
                } else {
                    for userWebSocket in ChatRoomWebSocketManager.shared.chatRoomWebSockets.first(where: {
                        $0.id == chatRoomID
                    })?.users ?? [UserWebSocket]() {
                        if userWebSocket.id == secondUserID.uuidString {
                            if !message.isViewed {
                                message.isViewed = true
                                
                                try await message.save(on: req.db)
                            }
                                                        
                            if let newMessage = try? await Message.find(message.id, on: req.db),
                               let data = try? JSONEncoder().encode(Message.Output(
                                id: newMessage.id,
                                text: newMessage.text,
                                isViewed: newMessage.isViewed,
                                bodyData: input.bodyData,
                                user: .init(
                                    id: input.userID,
                                    name: .init(),
                                    deals: .init(),
                                    boughtDeals: .init(),
                                    ads: .init(),
                                    myOffers: .init(),
                                    offers: .init(),
                                    chatRooms: .init(),
                                    score: .zero,
                                    isPremiumUser: .random()
                                ),
                                createdAt: newMessage.createdAt,
                                chatRoom: .init(id: input.chatRoomID, users: .init(), messages: .init())
                            )) {
                                try await userWebSocket.ws.send([UInt8](data))
                                try await UserWebSocketManager.shared.userWebSockets.first {
                                    $0.id == secondUserID.uuidString
                                }?.ws.send("update")
                            }
                        }
                    }
                }
            } catch {
                print("❌ Error: \(error.localizedDescription)")
            }
        }
        
        ws.onText { ws, text in
            try? await ws.send("❌ Error: text doesn't support for this connection.")
        }
        
        ChatRoomWebSocketManager.shared.addUserWebSocketInChatRoom(
            chatRoomID: chatRoomID,
            userID: firstUserID.uuidString,
            ws: ws
        )
    }
    
}
