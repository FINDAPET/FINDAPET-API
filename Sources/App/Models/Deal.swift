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
    var mode: DealMode.RawValue
    
    @Field(key: "pet_type")
    var petType: DealPetType.RawValue
    
    @Field(key: "pet_breed")
    var petBreed: DealPetBreed.RawValue
    
    @Field(key: "show_class")
    var showClass: DealShowClass.RawValue
    
    @Field(key: "is_male")
    var isMale: Bool
    
    @Field(key: "age")
    var age: String
    
    @Field(key: "color")
    var color: String
    
    @Field(key: "price")
    var price: String
    
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
        
    init() {}
    
    init(id: UUID? = nil, title: String, photoPaths: [String], tags: [String] = [String](), isPremiumDeal: Bool = false, isActive: Bool = true, viewsCount: Int = 0, mode: DealMode.RawValue, petType: DealPetType.RawValue, petBreed: DealPetBreed.RawValue, showClass: DealShowClass.RawValue, isMale: Bool, age: String, color: String, price: String, catteryID: User.IDValue, country: String? = nil, city: String? = nil, description: String? = nil, whatsappNumber: String? = nil, telegramUsername: String? = nil, instagramUsername: String? = nil, facebookUsername: String? = nil, vkUsername: String? = nil, mail: String? = nil, buyerID: User.IDValue? = nil) {
        self.id = id
        self.title = title
        self.photoPaths = photoPaths
        self.tags = tags
        self.isPremiumDeal = isPremiumDeal
        self.isActive = isActive
        self.viewsCount = viewsCount
        self.mode = mode
        self.petType = petType
        self.age = age
        self.color = color
        self.price = price
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
        var petType: DealPetType
        var petBreed: DealPetBreed
        var showClass: DealShowClass
        var isMale: Bool
        var age: String
        var color: String
        var price: String
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
        
        init(id: UUID? = nil, title: String, photoDatas: [Data], tags: [String] = [String](), isPremiumDeal: Bool = false, isActive: Bool = true, mode: DealMode, petType: DealPetType, petBreed: DealPetBreed, showClass: DealShowClass, isMale: Bool, age: String, color: String, price: String, catteryID: User.IDValue, country: String? = nil, city: String? = nil, description: String? = nil, whatsappNumber: String? = nil, telegramUsername: String? = nil, instagramUsername: String? = nil, facebookUsername: String? = nil, vkUsername: String? = nil, mail: String? = nil, buyerID: User.IDValue?) {
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
        var mode: DealMode.RawValue
        var petType: DealPetType.RawValue
        var petBreed: DealPetBreed.RawValue
        var showClass: DealShowClass.RawValue
        var isMale: Bool
        var age: String
        var color: String
        var price: String
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
        
        var score: Int { self.cattery.deals.filter { !$0.isActive }.count * (self.isPremiumDeal ? 2 : 1) }
    }
}
