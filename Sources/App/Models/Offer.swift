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
    
    @Parent(key: "buyer_id")
    var buyer: User
    
    @Parent(key: "deal_id")
    var deal: Deal
    
    @Parent(key: "cattery_id")
    var cattery: User
    
    init() { }
    
    init(id: UUID? = nil, buyerID: User.IDValue, dealID: Deal.IDValue, catteryID: User.IDValue) {
        self.id = id
        self.$buyer.id = buyerID
        self.$deal.id = dealID
        self.$cattery.id = catteryID
    }
    
}

extension Offer {
    struct Input: Content {
        var id: UUID?
        var buyerID: User.IDValue
        var dealID: Deal.IDValue
        var catteryID: User.IDValue
        
        init(id: UUID? = nil, buyerID: User.IDValue, dealID: Deal.IDValue, catteryID: User.IDValue) {
            self.id = id
            self.buyerID = buyerID
            self.dealID = dealID
            self.catteryID = catteryID
        }
    }
}

extension Offer {
    struct Output: Content {
        var id: UUID?
        var buyer: User.Output
        var deal: Deal.Output
        var cattery: User.Output
    }
}
