//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 21.05.2023.
//

import Foundation

enum CountryCode: String, CaseIterable {
    case ru, en
    
    static func get(_ key: String) -> CountryCode? {
        for countryCode in self.allCases {
            if countryCode.rawValue == key {
                return countryCode
            }
        }
        
        return nil
    }
}
