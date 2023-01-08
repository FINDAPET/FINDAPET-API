//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import Vapor
import APNS

struct DealController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let deals = routes.grouped("deals")
        let userTokenProtected = deals.grouped(UserToken.authenticator())
        
        userTokenProtected.put("all", use: self.index(req:))
        userTokenProtected.get(":dealID", use: self.someDeal(req:))
        userTokenProtected.get(":dealID", "offers", use: self.dealOffers(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.put(":dealID", "view", use: self.viewDeal(req:))
        userTokenProtected.put(":dealID", "deactivate", use: self.deactivateDeal(req:))
        userTokenProtected.put(":dealID", "activate", use: self.activateDeal(req:))
        userTokenProtected.put(":dealID", "offer", ":offerID", "sold", use: self.sold(req:))
        userTokenProtected.delete(":dealID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [Deal.Output] {
        let user = try req.auth.require(User.self)
        let filter = try? req.content.decode(Filter.self)
        var deals = try await Deal.query(on: req.db).all()
        var dealsOutput = [Deal.Output]()
        
        if !user.isAdmin {
            deals = deals.filter { $0.buyer == nil }
        }
        
        self.filterDeals(deals: &deals, filter: filter)
        
        for deal in deals {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            let petType = try await deal.$petType.get(on: req.db)
            let petBreed = try await deal.$petBreed.get(on: req.db)
            
            dealsOutput.append(Deal.Output(
                id: deal.id,
                title: deal.title,
                photoDatas: photoDatas,
                tags: deal.tags,
                isPremiumDeal: deal.isPremiumDeal,
                isActive: deal.isActive,
                viewsCount: deal.viewsCount,
                mode: deal.mode,
                petType: .init(
                    id: petType.id,
                    localizedNames: petType.localizedNames,
                    imageData: (try? await FileManager.get(req: req, with: petType.imagePath)) ?? .init(),
                    petBreeds: try await petType.$petBreeds.get(on: req.db)
                ),
                petBreed: .init(id: petBreed.id, name: petBreed.name, petType: petType),
                petClass: deal.petClass,
                isMale: deal.isMale,
                age: deal.age,
                color: deal.color,
                price: Double(try await CurrencyConverter.convert(
                    from: deal.currencyName,
                    to: user.basicCurrencyName,
                    amount: deal.price
                ).result),
                currencyName: user.basicCurrencyName,
                cattery: User.Output(
                    name: String(),
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: user.isPremiumUser
                ),
                country: deal.country,
                city: deal.city,
                description: deal.description,
                whatsappNumber: deal.whatsappNumber,
                telegramUsername: deal.telegramUsername,
                instagramUsername: deal.instagramUsername,
                facebookUsername: deal.facebookUsername,
                vkUsername: deal.vkUsername,
                mail: deal.mail,
                buyer: nil,
                offers: [Offer.Output]()
            ))
        }
        
        return dealsOutput.sorted(by: { $0.score > $1.score })
    }
    
    private func someDeal(req: Request) async throws -> Deal.Output {
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        deal.viewsCount += 1
        
        try await deal.save(on: req.db)
        
        let user = try req.auth.require(User.self)
        let cattery = try await deal.$cattery.get(on: req.db)
        let buyer = try await deal.$buyer.get(on: req.db)
        var photoDatas = [Data]()
        var offersOutput = [Offer.Output]()
        var catteryAvatarData: Data?
        var buyerAvatarData: Data?
        
        if let path = cattery.avatarPath {
            catteryAvatarData = try? await FileManager.get(req: req, with: path)
        }
        
        if let path = buyer?.avatarPath {
            buyerAvatarData = try? await FileManager.get(req: req, with: path)
        }
        
        for photoPath in deal.photoPaths {
            if let data = try? await FileManager.get(req: req, with: photoPath) {
                photoDatas.append(data)
            }
        }
        
        for offer in try await deal.$offers.get(on: req.db) {
            let offerBuyer = try await offer.$buyer.get(on: req.db)
            var offerBuyerAvatarData: Data?
            
            if let path = offerBuyer.avatarPath {
                offerBuyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            let petType = try await deal.$petType.get(on: req.db)
            let petBreed = try await deal.$petBreed.get(on: req.db)
            
            offersOutput.append(Offer.Output(
                id: offer.id,
                price: offer.price,
                currencyName: offer.currencyName,
                buyer: User.Output(
                    id: offerBuyer.id,
                    name: offerBuyer.name,
                    avatarData: offerBuyerAvatarData,
                    documentData: nil,
                    description: offerBuyer.description,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: offerBuyer.isPremiumUser
                ),
                deal: Deal.Output(
                    id: deal.id,
                    title: deal.title,
                    photoDatas: photoDatas,
                    tags: deal.tags,
                    isPremiumDeal: deal.isPremiumDeal,
                    isActive: deal.isActive,
                    viewsCount: deal.viewsCount,
                    mode: deal.mode,
                    petType: .init(
                        id: petType.id,
                        localizedNames: petType.localizedNames,
                        imageData: (try? await FileManager.get(req: req, with: petType.imagePath)) ?? .init(),
                        petBreeds: try await petType.$petBreeds.get(on: req.db)
                    ),
                    petBreed: .init(id: petBreed.id, name: petBreed.name, petType: petType),
                    petClass: deal.petClass,
                    isMale: deal.isMale,
                    age: deal.age,
                    color: deal.color,
                    price: Double(try await CurrencyConverter.convert(
                        from: deal.currencyName,
                        to: user.basicCurrencyName,
                        amount: deal.price
                    ).result),
                    currencyName: user.basicCurrencyName,
                    cattery: User.Output(
                        id: cattery.id,
                        name: cattery.name,
                        avatarData: catteryAvatarData,
                        documentData: nil,
                        description: cattery.description,
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output](),
                        isPremiumUser: cattery.isPremiumUser
                    ),
                    country: deal.country,
                    city: deal.city,
                    description: deal.description,
                    whatsappNumber: deal.whatsappNumber,
                    telegramUsername: deal.telegramUsername,
                    instagramUsername: deal.instagramUsername,
                    facebookUsername: deal.facebookUsername,
                    vkUsername: deal.vkUsername,
                    mail: deal.mail,
                    buyer: buyer == nil ? nil : User.Output(
                        id: buyer?.id,
                        name: buyer?.name ?? "",
                        avatarData: buyerAvatarData,
                        documentData: nil,
                        description: buyer?.description,
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output](),
                        isPremiumUser: buyer?.isPremiumUser ?? false
                    ),
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    id: cattery.id,
                    name: cattery.name,
                    avatarData: catteryAvatarData,
                    documentData: nil,
                    description: cattery.description,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: cattery.isPremiumUser
                )
            ))
        }
        
        let petType = try await deal.$petType.get(on: req.db)
        let petBreed = try await deal.$petBreed.get(on: req.db)
        
        return Deal.Output(
            id: deal.id,
            title: deal.title,
            photoDatas: photoDatas,
            tags: deal.tags,
            isPremiumDeal: deal.isPremiumDeal,
            isActive: deal.isActive,
            viewsCount: deal.viewsCount,
            mode: deal.mode,
            petType: .init(
                id: petType.id,
                localizedNames: petType.localizedNames,
                imageData: (try? await FileManager.get(req: req, with: petType.imagePath)) ?? .init(),
                petBreeds: try await petType.$petBreeds.get(on: req.db)
            ),
            petBreed: .init(id: petBreed.id, name: petBreed.name, petType: petType),
            petClass: deal.petClass,
            isMale: deal.isMale,
            age: deal.age,
            color: deal.color,
            price: Double(try await CurrencyConverter.convert(
                from: deal.currencyName,
                to: user.basicCurrencyName,
                amount: deal.price
            ).result),
            currencyName: user.basicCurrencyName,
            cattery: User.Output(
                id: cattery.id,
                name: cattery.name,
                avatarData: catteryAvatarData,
                documentData: nil,
                description: cattery.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: cattery.isPremiumUser
            ),
            country: deal.country,
            city: deal.city,
            description: deal.description,
            whatsappNumber: deal.whatsappNumber,
            telegramUsername: deal.telegramUsername,
            instagramUsername: deal.instagramUsername,
            facebookUsername: deal.facebookUsername,
            vkUsername: deal.vkUsername,
            mail: deal.mail,
            buyer: buyer == nil ? nil : User.Output(
                id: buyer?.id,
                name: buyer?.name ?? "",
                avatarData: buyerAvatarData,
                documentData: nil,
                description: buyer?.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: buyer?.isPremiumUser ?? false
            ),
            offers: offersOutput
        )
    }
    
    private func dealOffers(req: Request) async throws -> [Offer.Output] {
        return try await self.someDeal(req: req).offers
    }
    
    private func sold(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(User.self)
        
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db),
              let offer = try await Offer.find(req.parameters.get("offerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let buyer = try await offer.$buyer.get(on: req.db)
        
        deal.$buyer.id = buyer.id
        deal.isActive = false
        
        try await deal.save(on: req.db)
        
        if let deviceToken = buyer.deviceToken {
            try? req.apns.send(.init(title: "You bought a pet"), to: deviceToken).wait()
        }
        
        for deleteOffer in try await deal.$offers.get(on: req.db) {
            if deleteOffer.id != offer.id, let deviceToken = deleteOffer.buyer.deviceToken {
                try? await deleteOffer.delete(on: req.db)
                try? req.apns.send(.init(title: "Your offer is rejected"), to: deviceToken).wait()
            }
        }
        
        return .ok
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let deal = try req.content.decode(Deal.Input.self)
        var photoPaths = [String]()
        
        guard deal.catteryID == user.id else {
            throw Abort(.badRequest)
        }
        
        for photoData in deal.photoDatas {
            let path = req.application.directory.publicDirectory.appending(UUID().uuidString)
            
            try await FileManager.set(req: req, with: path, data: photoData)

            photoPaths.append(path)
        }
        
        try await Deal(
            id: deal.id,
            title: deal.title,
            photoPaths: photoPaths,
            tags: deal.tags,
            isPremiumDeal: deal.isPremiumDeal || user.isPremiumUser,
            isActive: deal.isActive,
            mode: deal.mode.rawValue,
            petTypeID: deal.petTypeID,
            petBreedID: deal.petBreedID,
            petClass: deal.petClass.rawValue,
            isMale: deal.isMale,
            age: deal.age,
            color: deal.color,
            price: deal.price,
            catteryID: deal.catteryID,
            currencyName: deal.currencyName.rawValue,
            country: deal.country,
            city: deal.city,
            description: deal.description,
            whatsappNumber: deal.whatsappNumber,
            telegramUsername: deal.telegramUsername,
            instagramUsername: deal.instagramUsername,
            facebookUsername: deal.facebookUsername,
            vkUsername: deal.vkUsername,
            mail: deal.mail,
            buyerID: deal.buyerID
        ).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let newDeal = try req.content.decode(Deal.Input.self)
        var photoPaths = [String]()
        
        guard newDeal.catteryID == user.id || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let oldDeal = try await Deal.find(newDeal.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        for photoData in newDeal.photoDatas {
            let path = req.application.directory.publicDirectory.appending(UUID().uuidString)
            
            try await req.fileio.writeFile(ByteBuffer(data: photoData), at: path)
            
            photoPaths.append(path)
        }
        
        oldDeal.isPremiumDeal = oldDeal.isPremiumDeal || user.isPremiumUser || newDeal.isPremiumDeal
        oldDeal.mail = newDeal.mail
        oldDeal.vkUsername = newDeal.vkUsername
        oldDeal.facebookUsername = newDeal.facebookUsername
        oldDeal.instagramUsername = newDeal.instagramUsername
        oldDeal.telegramUsername = newDeal.telegramUsername
        oldDeal.city = newDeal.city
        oldDeal.country = newDeal.country
        oldDeal.price = newDeal.price
        oldDeal.currencyName = newDeal.currencyName.rawValue
        oldDeal.age = newDeal.age
        oldDeal.isMale = newDeal.isMale
        oldDeal.petClass = newDeal.petClass.rawValue
        oldDeal.$petBreed.id = newDeal.petBreedID
        oldDeal.$petType.id = newDeal.petTypeID
        oldDeal.mode = newDeal.mode.rawValue
        oldDeal.title = newDeal.title
        oldDeal.description = newDeal.description
        oldDeal.photoPaths = photoPaths
        oldDeal.tags = newDeal.tags
        oldDeal.color = newDeal.color
        
        try await oldDeal.save(on: req.db)
        
        return .ok
    }
    
    private func viewDeal(req: Request) async throws -> HTTPStatus {
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard try await deal.$cattery.get(on: req.db).id != req.auth.require(User.self).id else {
            throw Abort(.badRequest)
        }
        
        deal.viewsCount += 1
        
        try await deal.save(on: req.db)
        
        return .ok
    }
    
    private func deactivateDeal(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let cattery = try await deal.$cattery.get(on: req.db)
        
        guard cattery.id == user.id || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        deal.isActive = false
        
        try await deal.save(on: req.db)
        
        return .ok
    }
    
    private func activateDeal(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let cattery = try await deal.$cattery.get(on: req.db)
        
        guard cattery.id == user.id || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        deal.isActive = true
        
        try await deal.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let cattery = try await deal.$cattery.get(on: req.db)
        
        guard cattery.id == user.id || user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        try await deal.delete(on: req.db)
        
        for photoPath in deal.photoPaths {
            try await FileManager.set(req: req, with: photoPath, data: .init())
        }
        
        return .ok
    }
    
    private func filterDeals(deals: inout [Deal], filter: Filter? = nil) {
        deals = deals.filter { $0.isActive }
        
        if let petTypeID = filter?.petTypeID {
            deals = deals.filter { $0.petType.id == petTypeID }
        }
        
        if let petBreedID = filter?.petBreedID {
            deals = deals.filter { $0.petBreed.id == petBreedID }
        }
        
        if let petClass = filter?.petClass, petClass != .allClass {
            deals = deals.filter { $0.petClass == petClass.rawValue }
        }
        
        if let isMale = filter?.isMale {
            deals = deals.filter { $0.isMale == isMale }
        }
        
        if let country = filter?.country {
            deals = deals.filter { $0.country == country }
        }
        
        if let city = filter?.city {
            deals = deals.filter { $0.city == city }
        }
        
        if let title = filter?.title {
            let titleWords = title.split(separator: " ")
            
            deals = deals.filter { deal in
                let words = deal.title.split(separator: " ")
                var count = 0
                
                for titleWord in titleWords {
                    if words.contains(titleWord) || deal.tags.contains(String(titleWord)) {
                        count += 1
                    }
                    
                    if count >= 3 {
                        break
                    }
                }
                
                if count < 3 {
                    return false
                }
                
                return true
            }
        }
        
    }
    
    private struct Filter: Content {
        var title: String?
        var petTypeID: PetType.IDValue?
        var petBreedID: PetType.IDValue?
        var petClass: PetClass?
        var isMale: Bool?
        var country: String?
        var city: String?
    }
    
}
