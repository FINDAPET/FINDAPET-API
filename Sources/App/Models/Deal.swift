//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 03.08.2022.
//

import Foundation
import Vapor
import Fluent

final class Deal: Model, Content {
    
    static let schema = "deals"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "photo_paths")
    var photoPaths: [String]
    
    @Field(key: "tags")
    var tags: [String]
    
    @Field(key: "is_premium_deal")
    var isPremiumDeal: Bool
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Field(key: "views_count")
    var viewsCount: Int
    
    @Field(key: "mode")
    var mode: String
    
    @Field(key: "pet_type")
    var petType: String
    
    @Field(key: "pet_breed")
    var petBreed: String
    
    @Field(key: "show_class")
    var showClass: String
    
    @Field(key: "is_male")
    var isMale: Bool
    
    @Field(key: "age")
    var age: String
    
    @Field(key: "color")
    var color: String
    
    @Field(key: "price")
    var price: Double
    
    @Field(key: "currency_name")
    var currencyName: String
    
    @Parent(key: "cattery_id")
    var cattery: User
    
    @OptionalField(key: "country")
    var country: String?
    
    @OptionalField(key: "city")
    var city: String?
    
    @OptionalField(key: "description")
    var description: String?
    
    @OptionalField(key: "whatsapp_number")
    var whatsappNumber: String?
    
    @OptionalField(key: "telegram_username")
    var telegramUsername: String?
    
    @OptionalField(key: "instagram_username")
    var instagramUsername: String?
    
    @OptionalField(key: "facebook_username")
    var facebookUsername: String?
    
    @OptionalField(key: "vk_username")
    var vkUsername: String?
    
    @OptionalField(key: "mail")
    var mail: String?
    
    @OptionalParent(key: "buyer_id")
    var buyer: User?
    
    @Children(for: \.$deal)
    var offers: [Offer]
        
    init() {}
    
    init(id: UUID? = nil, title: String, photoPaths: [String], tags: [String] = [String](), isPremiumDeal: Bool = false, isActive: Bool = true, viewsCount: Int = 0, mode: String, petType: String, petBreed: String, showClass: String, isMale: Bool, age: String, color: String, price: Double, catteryID: User.IDValue, currencyName: String, country: String? = nil, city: String? = nil, description: String? = nil, whatsappNumber: String? = nil, telegramUsername: String? = nil, instagramUsername: String? = nil, facebookUsername: String? = nil, vkUsername: String? = nil, mail: String? = nil, buyerID: User.IDValue? = nil) {
        self.id = id
        self.title = title
        self.photoPaths = photoPaths
        self.tags = tags
        self.isPremiumDeal = isPremiumDeal
        self.isActive = isActive
        self.viewsCount = viewsCount
        self.mode = mode
        self.petType = petType
        self.petBreed = petBreed
        self.showClass = showClass
        self.isMale = isMale
        self.age = age
        self.color = color
        self.price = price
        self.currencyName = currencyName
        self.$cattery.id = catteryID
        self.country = country
        self.city = city
        self.description = description
        self.whatsappNumber = whatsappNumber
        self.telegramUsername = telegramUsername
        self.instagramUsername = instagramUsername
        self.facebookUsername = facebookUsername
        self.vkUsername = vkUsername
        self.mail = mail
        self.$buyer.id = buyerID
    }
    
}

extension Deal {
    struct Input: Content {
        var id: UUID?
        var title: String
        var photoDatas: [Data]
        var tags: [String]
        var isPremiumDeal: Bool
        var isActive: Bool
        var mode: DealMode
        var petType: PetType
        var petBreed: PetBreed
        var showClass: PetClass
        var isMale: Bool
        var age: String
        var color: String
        var price: Double
        var currencyName: Currency
        var catteryID: User.IDValue
        var country: String?
        var city: String?
        var description: String?
        var whatsappNumber: String?
        var telegramUsername: String?
        var instagramUsername: String?
        var facebookUsername: String?
        var vkUsername: String?
        var mail: String?
        var buyerID: User.IDValue?
        
        init(id: UUID? = nil, title: String, photoDatas: [Data], tags: [String] = [String](), isPremiumDeal: Bool = false, isActive: Bool = true, mode: DealMode, petType: PetType, petBreed: PetBreed, showClass: PetClass, isMale: Bool, age: String, color: String, price: Double, catteryID: User.IDValue, currencyName: Currency, country: String? = nil, city: String? = nil, description: String? = nil, whatsappNumber: String? = nil, telegramUsername: String? = nil, instagramUsername: String? = nil, facebookUsername: String? = nil, vkUsername: String? = nil, mail: String? = nil, buyerID: User.IDValue?) {
            self.id = id
            self.title = title
            self.photoDatas = photoDatas
            self.tags = tags
            self.isPremiumDeal = isPremiumDeal
            self.isActive = isActive
            self.mode = mode
            self.petType = petType
            self.petBreed = petBreed
            self.showClass = showClass
            self.isMale = isMale
            self.age = age
            self.color = color
            self.price = price
            self.currencyName = currencyName
            self.catteryID = catteryID
            self.country = country
            self.city = city
            self.description = description
            self.whatsappNumber = whatsappNumber
            self.telegramUsername = telegramUsername
            self.instagramUsername = instagramUsername
            self.facebookUsername = facebookUsername
            self.vkUsername = vkUsername
            self.mail = mail
            self.buyerID = buyerID
        }
    }
}

extension Deal {
    struct Output: Content {
        var id: UUID?
        var title: String
        var photoDatas: [Data]
        var tags: [String]
        var isPremiumDeal: Bool
        var isActive: Bool
        var viewsCount: Int
        var mode: String
        var petType: String
        var petBreed: String
        var showClass: String
        var isMale: Bool
        var age: String
        var color: String
        var price: Double
        var currencyName: String
        var cattery: User.Output
        var country: String?
        var city: String?
        var description: String?
        var whatsappNumber: String?
        var telegramUsername: String?
        var instagramUsername: String?
        var facebookUsername: String?
        var vkUsername: String?
        var mail: String?
        var buyer: User.Output?
        var offers: [Offer.Output]
        
        var score: Int { self.cattery.deals.filter { $0.buyer != nil }.count * (self.isPremiumDeal ? 2 : 1) }
    }
}

extension Deal: Equatable {
    static func == (lhs: Deal, rhs: Deal) -> Bool {
        lhs.id == rhs.id
    }
}
