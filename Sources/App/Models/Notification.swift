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
    
    init(title: String, countryCode: [String] = [String]()) {
        self.title = title
        self.coutryCodes = countryCode
    }
}
