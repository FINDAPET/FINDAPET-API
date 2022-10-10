//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import WebSocketKit

final class ChatRoomWebSocketManager {
    
    private(set) var chatRoomWebSockets: [ChatRoomWebSocket]
    
    init(_ chatRoomWebSockets: [ChatRoomWebSocket]) {
        self.chatRoomWebSockets = chatRoomWebSockets
    }
    
    static let shared = ChatRoomWebSocketManager([ChatRoomWebSocket]())
    
    func addChatRoomWebSocket(id: UUID?, userWebSockets: [UserWebSocket] = [UserWebSocket]()) {
        if !self.chatRoomWebSockets.contains(where: { $0.id == id }) {
            self.chatRoomWebSockets.append(ChatRoomWebSocket(id: id, users: userWebSockets))
        }
    }
    
    func addUserWebSocketInChatRoom(chatRoomID: UUID?, userID: UUID?, ws: WebSocket) {
        if !self.chatRoomWebSockets.contains(where: { $0.id == chatRoomID }) {
            self.chatRoomWebSockets.append(ChatRoomWebSocket(id: chatRoomID, users: [UserWebSocket(id: userID, ws: ws)]))
            
            return
        }
        
        for i in 0 ..< self.chatRoomWebSockets.count {
            if self.chatRoomWebSockets[i].id == chatRoomID {
                if !self.chatRoomWebSockets[i].users.contains(where: { $0.id == userID }) {
                    self.chatRoomWebSockets[i].users.append(UserWebSocket(id: userID, ws: ws))
                } else {
                    for j in 0 ..< self.chatRoomWebSockets[i].users.count {
                        if self.chatRoomWebSockets[i].users[j].id == userID {
                            self.chatRoomWebSockets[i].users[j].ws = ws
                        }
                    }
                }
            }
        }
    }
    
    func removeChatRoomWebSocket(id: UUID?) {
        self.chatRoomWebSockets.removeAll { $0.id == id }
    }
    
    func removeUserWebSocketInChatRoom(chatRoomID: UUID?, userID: UUID?) {
        for i in 0 ..< self.chatRoomWebSockets.count {
            if self.chatRoomWebSockets[i].id == chatRoomID {
                self.chatRoomWebSockets[i].users.removeAll(where: { $0.id == userID })
            }
        }
    }
    
}
