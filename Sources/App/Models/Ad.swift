//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Vapor
import Fluent

final class Ad: Model, Content {
    
    static let schema = "ads"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content_path")
    var contentPath: String
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @OptionalField(key: "customer_name")
    var custromerName: String?
    
    @OptionalField(key: "link")
    var link: String?
    
    @OptionalParent(key: "cattery_id")
    var cattery: User?
    
    init() { }
    
    init(id: UUID? = nil, contentPath: String, custromerName: String? = nil, link: String? = nil, catteryID: User.IDValue? = nil, isActive: Bool = true) {
        self.id = id
        self.contentPath = contentPath
        self.custromerName = custromerName
        self.link = link
        self.$cattery.id = catteryID
        self.isActive = isActive
    }
    
}

extension Ad {
    struct Input: Content {
        var id: UUID?
        var contentData: Data
        var customerName: String?
        var link: String?
        var catteryID: User.IDValue
        
        init(id: UUID? = nil, contentData: Data, customerName: String? = nil, link: String? = nil, catteryID: User.IDValue) {
            self.id = id
            self.contentData = contentData
            self.customerName = customerName
            self.link = link
            self.catteryID = catteryID
        }
    }
}

extension Ad {
    struct Output: Content {
        var id: UUID?
        var contentData: Data
        var custromerName: String?
        var link: String?
        var cattery: User.Output
    }
}
