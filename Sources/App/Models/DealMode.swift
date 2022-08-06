//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 26.07.2022.
//

import Foundation

enum DealMode: String, Codable {
    case onlyInCity = "Only in the City"
    case onlyInCountry = "Only in the Country"
    case onlyAbroad = "Only Abroad"
    case everywhere = "Everywhere"
}
