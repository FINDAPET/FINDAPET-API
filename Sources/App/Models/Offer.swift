//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.08.2022.
//

import Foundation
import Vapor
import Fluent

final class Offer: Model, Content {
    
    static let schema = "offers"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "price")
    var price: Int
    
    @Field(key: "currency_name")
    var currencyName: String
    
    @Parent(key: "buyer_id")
    var buyer: User
    
    @Parent(key: "deal_id")
    var deal: Deal
    
    @Parent(key: "cattery_id")
    var cattery: User
    
    init() { }
    
    init(id: UUID? = nil, buyerID: User.IDValue, dealID: Deal.IDValue, catteryID: User.IDValue, price: Int, currencyName: String) {
        self.id = id
        self.price = price
        self.currencyName = currencyName
        self.$buyer.id = buyerID
        self.$deal.id = dealID
        self.$cattery.id = catteryID
    }
    
}

extension Offer {
    struct Input: Content {
        var id: UUID?
        var price: Int
        var currencyName: Currency
        var buyerID: User.IDValue
        var dealID: Deal.IDValue
        var catteryID: User.IDValue
        
        init(id: UUID? = nil, buyerID: User.IDValue, dealID: Deal.IDValue, catteryID: User.IDValue, price: Int, currencyName: Currency) {
            self.id = id
            self.price = price
            self.currencyName = currencyName
            self.buyerID = buyerID
            self.dealID = dealID
            self.catteryID = catteryID
        }
    }
}

extension Offer {
    struct Output: Content {
        var id: UUID?
        var price: Int
        var currencyName: String
        var buyer: User.Output
        var deal: Deal.Output
        var cattery: User.Output
    }
}

extension Offer: Equatable {
    static func == (lhs: Offer, rhs: Offer) -> Bool {
        lhs.id == rhs.id
    }
}
