//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Vapor
import Fluent

final class ChatRoom: Model, Content {
    
    static let schema = "chat_rooms"
    
    @ID(key: .id)
    var id: UUID?
    
    init() { }
    
    init(id: UUID? = nil) {
        self.id = id
    }
    
}

extension ChatRoom {
    struct Input: Content {
        
    }
}

extension ChatRoom {
    struct Output: Content {
        
    }
}
