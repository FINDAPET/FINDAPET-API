//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 07.10.2022.
//

import Foundation
import WebSocketKit

struct UserWebSocket {
    var id: UUID?
    var ws: WebSocket
}

extension UserWebSocket: Equatable {
    static func == (lhs: UserWebSocket, rhs: UserWebSocket) -> Bool {
        lhs.id == rhs.id
    }
}
