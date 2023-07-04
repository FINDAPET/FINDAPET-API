//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 21.05.2023.
//

import Foundation

protocol LocalizationManagerDataSourceable {
    typealias LocalizedString = String
    
    var values: [CountryCode : [LocalizationKey : LocalizedString]] { get }
}
