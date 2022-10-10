//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 06.10.2022.
//

import Foundation

struct Notification: Decodable {
    let title: String
    let coutryCodes: [String]
    let usersID: [UUID]
    
    init(title: String, countryCode: [String] = [String](), usersID: [UUID] = [UUID]()) {
        self.title = title
        self.coutryCodes = countryCode
        self.usersID = usersID
    }
}
