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
        self.chatRoomWebSockets.append(ChatRoomWebSocket(id: id, users: userWebSockets))
    }
    
    func addUserWebSocketInChatRoom(chatRoomID: UUID?, userID: UUID?, ws: WebSocket) {
        for i in 0 ..< self.chatRoomWebSockets.count {
            if self.chatRoomWebSockets[i].id == chatRoomID {
                if !self.chatRoomWebSockets[i].users.contains(where: { $0.id == userID }) {
                    self.chatRoomWebSockets[i].users.append(UserWebSocket(id: userID, ws: ws))
                } else {
                    for j in 0 ..< self.chatRoomWebSockets[i].users.count {
                        if self.chatRoomWebSockets[i].users[j].id == userID {
                            self.chatRoomWebSockets[i].users[j].ws.close().whenComplete { result in
                                switch result {
                                case .success(_):
                                    self.chatRoomWebSockets[i].users[j].ws = ws
                                case .failure(let error):
                                    print("❌ Error: \(error.localizedDescription)")
                                    
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func removeChatRoomWebSocket(id: UUID?) {
        var indexes = [Int]()
        
        for i in 0 ..< self.chatRoomWebSockets.count {
            if self.chatRoomWebSockets[i].id == id {
                for user in self.chatRoomWebSockets[i].users {
                    user.ws.close().whenFailure { print("❌ Error: \($0.localizedDescription)") }
                }
                
                indexes.append(i)
            }
        }
        
        for index in indexes {
            self.chatRoomWebSockets.remove(at: index)
        }
    }
    
    func removeUserWebSocketInChatRoom(chatRoomID: UUID?, userID: UUID?) {
        var indexes = [Int]()
        
        for i in 0 ..< self.chatRoomWebSockets.count {
            if self.chatRoomWebSockets[i].id == chatRoomID {
                for j in 0 ..< self.chatRoomWebSockets[i].users.count {
                    if self.chatRoomWebSockets[i].users[j].id == userID {
                        self.chatRoomWebSockets[i].users[j].ws.close().whenFailure { print("❌ Error: \($0.localizedDescription)") }
                    }
                    
                    indexes.append(j)
                }
                
                for index in indexes {
                    self.chatRoomWebSockets[i].users.remove(at: index)
                }
                
                indexes = [Int]()
            }
        }
    }
    
}
