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
    var tags: String
    
    @Field(key: "is_premium_deal")
    var isPremiumDeal: Bool
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Field(key: "views_count")
    var viewsCount: Int
    
    @Field(key: "mode")
    var mode: String
    
    @Parent(key: "pet_type_id")
    var petType: PetType
    
    @Parent(key: "pet_breed_id")
    var petBreed: PetBreed
    
    @Field(key: "pet_class")
    var petClass: String
    
    @Field(key: "is_male")
    var isMale: Bool
    
    @Field(key: "birth_date")
    var birthDate: Date
    
    @Field(key: "color")
    var color: String
    
    @Field(key: "currency_name")
    var currencyName: String
    
    @Field(key: "score")
    var score: Int
    
    @Parent(key: "cattery_id")
    var cattery: User
    
    @OptionalField(key: "price")
    var price: Double?
    
    @OptionalField(key: "country")
    var country: String?
    
    @OptionalField(key: "city")
    var city: String?
    
    @OptionalField(key: "description")
    var description: String?
    
    @OptionalParent(key: "buyer_id")
    var buyer: User?
    
    @Children(for: \.$deal)
    var offers: [Offer]
        
    init() {}
    
    init(id: UUID? = nil, title: String, photoPaths: [String], tags: String = .init(), isPremiumDeal: Bool = false, isActive: Bool = true, viewsCount: Int = 0, mode: String, petTypeID: PetType.IDValue, petBreedID: PetBreed.IDValue, petClass: String, isMale: Bool, birthDate: Date, color: String, price: Double? = nil, catteryID: User.IDValue, currencyName: String, score: Int = .zero, country: String? = nil, city: String? = nil, description: String? = nil, buyerID: User.IDValue? = nil) {
        self.id = id
        self.title = title
        self.photoPaths = photoPaths
        self.tags = tags
        self.isPremiumDeal = isPremiumDeal
        self.isActive = isActive
        self.viewsCount = viewsCount
        self.mode = mode
        self.$petType.id = petTypeID
        self.$petBreed.id = petBreedID
        self.petClass = petClass
        self.isMale = isMale
        self.birthDate = birthDate
        self.color = color
        self.price = price
        self.currencyName = currencyName
        self.score = score
        self.$cattery.id = catteryID
        self.country = country
        self.city = city
        self.description = description
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
        var petTypeID: PetType.IDValue
        var petBreedID: PetBreed.IDValue
        var petClass: PetClass
        var isMale: Bool
        var birthDate: String
        var color: String
        var price: Double?
        var currencyName: Currency
        var catteryID: User.IDValue
        var country: String?
        var city: String?
        var description: String?
        var buyerID: User.IDValue?
        
        init(id: UUID? = nil, title: String, photoDatas: [Data], tags: [String] = [String](), isPremiumDeal: Bool = false, isActive: Bool = true, mode: DealMode, petTypeID: PetType.IDValue, petBreedID: PetBreed.IDValue, petClass: PetClass, isMale: Bool, birthDate: String, color: String, price: Double? = nil, catteryID: User.IDValue, currencyName: Currency, country: String? = nil, city: String? = nil, description: String? = nil, buyerID: User.IDValue? = nil) {
            self.id = id
            self.title = title
            self.photoDatas = photoDatas
            self.tags = tags
            self.isPremiumDeal = isPremiumDeal
            self.isActive = isActive
            self.mode = mode
            self.petTypeID = petTypeID
            self.petBreedID = petBreedID
            self.petClass = petClass
            self.isMale = isMale
            self.birthDate = birthDate
            self.color = color
            self.price = price
            self.currencyName = currencyName
            self.catteryID = catteryID
            self.country = country
            self.city = city
            self.description = description
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
        var petType: PetType.Output
        var petBreed: PetBreed.Output
        var petClass: PetClass
        var isMale: Bool
        var birthDate: Date
        var color: String
        var price: Double?
        var currencyName: String
        var score: Int
        var cattery: User.Output
        var country: String?
        var city: String?
        var description: String?
        var buyer: User.Output?
        var offers: [Offer.Output]
    }
}

extension Deal: Equatable {
    static func == (lhs: Deal, rhs: Deal) -> Bool {
        lhs.id == rhs.id
    }
}
