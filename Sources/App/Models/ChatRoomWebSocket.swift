//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 07.10.2022.
//

import Foundation
import WebSocketKit

struct ChatRoomWebSocket {
    var id: UUID?
    var users: [UserWebSocket]
}

extension ChatRoomWebSocket: Equatable {
    static func == (lhs: ChatRoomWebSocket, rhs: ChatRoomWebSocket) -> Bool {
        lhs.id == rhs.id
    }
}
