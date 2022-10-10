//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 08.10.2022.
//

import Foundation
import WebSocketKit

final class UserWebSocketManager {
    
    private(set) var userWebSockets: [UserWebSocket]
    
    init(_ userWebSockets: [UserWebSocket]) {
        self.userWebSockets = userWebSockets
    }
    
    static let shared = UserWebSocketManager([UserWebSocket]())
    
    func addUserWebSocket(id: UUID?, ws: WebSocket) {
        for i in 0 ..< self.userWebSockets.count {
            if self.userWebSockets[i].id == id {
                self.userWebSockets[i].ws = ws
            }
        }
        
        if !self.userWebSockets.contains(where: { $0.id == id }) {
            self.userWebSockets.append(UserWebSocket(id: id, ws: ws))
        }
    }
    
    func removeUserWebSocket(id: UUID?) {
        for i in 0 ..< self.userWebSockets.count {
            if self.userWebSockets[i].id == id {
                self.userWebSockets[i].ws.close().whenFailure { print("❌ Error: \($0.localizedDescription)") }
                self.userWebSockets.remove(at: i)
            }
        }
    }
    
}
