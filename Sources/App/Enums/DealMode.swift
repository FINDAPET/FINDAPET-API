//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 13.11.2022.
//

import Foundation
import Vapor

enum DealMode: String, Content, CaseIterable {
    case onlyInCity = "Only in the City"
    case onlyInCountry = "Only in the Country"
    case onlyAbroad = "Only Abroad"
    case everywhere = "Everywhere"
}
