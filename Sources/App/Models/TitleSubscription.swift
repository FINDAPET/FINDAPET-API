//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.04.2023.
//

import Foundation
import Vapor
import Fluent

final class TitleSubscription: Model, Content {
    
    typealias CountryCode = String
    
    static let schema = "title_subscription"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "localized_title")
    var localizedTitle: [CountryCode : String]
    
    ///The price is always given in dollars
    @Field(key: "price")
    var price: Int
    
    @Field(key: "months_count")
    var monthsCount: Int
    
    init() { }
    
    ///The price is always given in dollars
    init(id: TitleSubscription.IDValue? = nil, localizedTitle: [CountryCode : String], price: Int, monthsCount: Int) {
        self.id = id
        self.localizedTitle = localizedTitle
        self.price = price
        self.monthsCount = monthsCount
    }
    
}

extension TitleSubscription: Equatable {
    
    static func == (lhs: TitleSubscription, rhs: TitleSubscription) -> Bool {
        lhs.id == rhs.id
    }
    
}
