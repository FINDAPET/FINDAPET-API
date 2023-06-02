//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import Vapor
import APNS
import FluentKit
import PostgresNIO

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
        var query = Deal.query(on: req.db)
        var dealsOutput = [Deal.Output]()
        
        self.filterDeals(deals: &query, filter: filter)
        
        var deals = !user.isAdmin ?
        try await query.filter(\.$isActive == true).sort(\.$score, .descending).range(..<10).all() :
        try await query.sort(\.$score, .descending).range(..<10).all()
        
        if !user.isAdmin {
            deals = deals.filter { $0.buyer == nil }
        }
        
        for deal in deals {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            let petType = try await deal.$petType.get(on: req.db)
            let petBreed = try await deal.$petBreed.get(on: req.db)
            let dealUser = try await deal.$cattery.get(on: req.db)
            var userDeals = [Deal.Output]()
            var dealUserAvatarData: Data?
            
            if let path = dealUser.avatarPath {
                dealUserAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            for deal in (try? await dealUser.$deals.get(on: req.db)) ?? .init() {
                userDeals.append(.init(
                    title: deal.title,
                    photoDatas: .init(),
                    tags: .init(),
                    isPremiumDeal: deal.isPremiumDeal,
                    isActive: deal.isActive,
                    viewsCount: deal.viewsCount,
                    mode: deal.mode,
                    petType: .init(localizedNames: .init(), imageData: .init(), petBreeds: .init()),
                    petBreed: .init(name: .init(), petType: .init(localizedNames: .init(), imagePath: .init())),
                    petClass: .allClass,
                    isMale: deal.isMale,
                    birthDate: deal.birthDate,
                    color: deal.color,
                    price: deal.price,
                    currencyName: deal.currencyName,
                    score: deal.score,
                    cattery: .init(
                        name: .init(),
                        deals: .init(),
                        boughtDeals: .init(),
                        ads: .init(),
                        myOffers: .init(),
                        offers: .init(),
                        chatRooms: .init(),
                        score: .zero
                    ),
                    buyer: deal.buyer != nil ? .init(
                        name: .init(),
                        deals: .init(),
                        boughtDeals: .init(),
                        ads: .init(),
                        myOffers: .init(),
                        offers: .init(),
                        chatRooms: .init(),
                        score: .zero
                    ) : nil,
                    offers: .init()
                ))
            }
            
            dealsOutput.append(Deal.Output(
                id: deal.id,
                title: deal.title,
                photoDatas: photoDatas,
                tags: deal.tags.split(separator: "#").map({ String($0) }),
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
                petClass: .get(deal.petClass) ?? .allClass,
                isMale: deal.isMale,
                birthDate: deal.birthDate,
                color: deal.color,
                price: deal.price != nil ? .init(try await CurrencyConverter.convert(
                    req,
                    from: deal.currencyName,
                    to: user.basicCurrencyName,
                    amount: deal.price ?? .zero
                ).result) : nil,
                currencyName: user.basicCurrencyName,
                score: deal.score,
                cattery: .init(
                    id: dealUser.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
                    documentData: dealUser.documentPath != nil && !dealUser.isCatteryWaitVerify ? .init() : nil,
                    deals: userDeals,
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    score: .zero
                ),
                country: deal.country,
                city: deal.city,
                description: deal.description,
                buyer: nil,
                offers: [Offer.Output]()
            ))
        }
        
        return dealsOutput
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
                    score: .zero
                ),
                deal: Deal.Output(
                    id: deal.id,
                    title: deal.title,
                    photoDatas: photoDatas,
                    tags: deal.tags.split(separator: "#").map({ String($0) }),
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
                    petClass: .get(deal.petClass) ?? .allClass,
                    isMale: deal.isMale,
                    birthDate: deal.birthDate,
                    color: deal.color,
                    price: deal.price != nil ? Double(try await CurrencyConverter.convert(
                        req,
                        from: deal.currencyName,
                        to: user.basicCurrencyName,
                        amount: deal.price ?? .zero
                    ).result) : nil,
                    currencyName: user.basicCurrencyName,
                    score: deal.score,
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
                        score: .zero
                    ),
                    country: deal.country,
                    city: deal.city,
                    description: deal.description,
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
                        score: .zero
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
                    score: .zero
                )
            ))
        }
        
        let petType = try await deal.$petType.get(on: req.db)
        let petBreed = try await deal.$petBreed.get(on: req.db)
        
        return Deal.Output(
            id: deal.id,
            title: deal.title,
            photoDatas: photoDatas,
            tags: deal.tags.split(separator: "#").map({ String($0) }),
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
            petClass: .get(deal.petClass) ?? .allClass,
            isMale: deal.isMale,
            birthDate: deal.birthDate,
            color: deal.color,
            price: deal.price != nil ? Double(try await CurrencyConverter.convert(
                req,
                from: deal.currencyName,
                to: user.basicCurrencyName,
                amount: deal.price ?? .zero
            ).result) : nil,
            currencyName: user.basicCurrencyName,
            score: deal.score,
            cattery: User.Output(
                id: cattery.id,
                name: cattery.name,
                avatarData: catteryAvatarData,
                documentData: cattery.documentPath != nil && !cattery.isCatteryWaitVerify ? .init() : nil,
                description: cattery.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                score: .zero
            ),
            country: deal.country,
            city: deal.city,
            description: deal.description,
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
                score: .zero
            ),
            offers: offersOutput
        )
    }
    
    private func dealOffers(req: Request) async throws -> [Offer.Output] {
        return try await self.someDeal(req: req).offers
    }
    
    private func sold(req: Request) async throws -> HTTPStatus {
        try req.auth.require(User.self)
        
        guard let deal = try await Deal.find(req.parameters.get("dealID"), on: req.db),
              let offer = try await Offer.find(req.parameters.get("offerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let buyer = try await offer.$buyer.get(on: req.db)
        let cattery = try await deal.$cattery.get(on: req.db)
        
        deal.$buyer.id = buyer.id
        deal.isActive = false
        
        cattery.score += 1 * (cattery.subscrtiption != nil ? 2 : 1)
        
        try await deal.save(on: req.db)
        try await cattery.save(on: req.db)
        
        for deviceToken in (try? await buyer.$deviceTokens.get(on: req.db)) ?? .init() {
            switch Platform.get(deviceToken.platform) {
            case .iOS:
                do {
                    req.apns.send(
                        .init(title: try LocalizationManager.main.get(buyer.countryCode, .youBoughtAPet)),
                        to: deviceToken.value
                    ).whenComplete {
                        switch $0 {
                        case .success():
                            print("❕NOTIFICATION: push notification is sent.")
                        case .failure(let error):
                            print("❌ ERROR: \(error.localizedDescription)")
                        }
                    }
                } catch {
                    print("❌ ERROR: \(error.localizedDescription)")
                }
            case .Android:
//                full version
                continue
            case .custom(_):
//                full version
                continue
            }
        }
        
        for deleteOffer in try await deal.$offers.get(on: req.db) {
            if deleteOffer.id != offer.id {
                try? await deleteOffer.delete(on: req.db)
                
                for deviceToken in (try? await deleteOffer.buyer.$deviceTokens.get(on: req.db)) ?? .init() {
                    switch Platform.get(deviceToken.platform) {
                    case .iOS:
                        do {
                            req.apns.send(
                                .init(title: try LocalizationManager.main.get(buyer.countryCode, .yourOfferIsRejected)),
                                to: deviceToken.value
                            ).whenComplete {
                                switch $0 {
                                case .success():
                                    print("❕NOTIFICATION: push notification is sent.")
                                case .failure(let error):
                                    print("❌ ERROR: \(error.localizedDescription)")
                                }
                            }
                        } catch {
                            print("❌ ERROR: \(error.localizedDescription)")
                        }
                    case .Android:
//                full version
                        continue
                    case .custom(_):
//                full version
                        continue
                    }
                }
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
        
        var tags = String()
        
        for tag in deal.tags where !tag.isEmpty {
            tags += "#\(tag)"
        }
        
        let sub = try? await user.$subscrtiption.get(on: req.db)
        
        try await Deal(
            id: deal.id,
            title: deal.title,
            photoPaths: photoPaths,
            tags: tags,
            isPremiumDeal: deal.isPremiumDeal || sub != nil,
            isActive: deal.isActive,
            mode: deal.mode.rawValue,
            petTypeID: deal.petTypeID,
            petBreedID: deal.petBreedID,
            petClass: deal.petClass.rawValue,
            isMale: deal.isMale,
            birthDate: ISO8601DateFormatter().date(from: deal.birthDate) ?? .init(),
            color: deal.color,
            price: deal.price,
            catteryID: deal.catteryID,
            currencyName: deal.currencyName.rawValue,
            score: user.score * (deal.isPremiumDeal || sub != nil ? 2 : 1),
            country: deal.country,
            city: deal.city,
            description: deal.description
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
        
        for photoPath in oldDeal.photoPaths {
            try await FileManager.set(req: req, with: photoPath, data: .init())
        }
        
        for photoData in newDeal.photoDatas {
            let path = req.application.directory.publicDirectory.appending(UUID().uuidString)
            
            try await FileManager.set(req: req, with: path, data: photoData)
            
            photoPaths.append(path)
        }
        
        var tags = String()
        
        for tag in newDeal.tags where !tag.isEmpty {
            tags += "#\(tag)"
        }
        
        let sub = try? await user.$subscrtiption.get(on: req.db)
        
        oldDeal.isPremiumDeal = oldDeal.isPremiumDeal || sub != nil || newDeal.isPremiumDeal
        oldDeal.city = newDeal.city
        oldDeal.country = newDeal.country
        oldDeal.price = newDeal.price
        oldDeal.currencyName = newDeal.currencyName.rawValue
        oldDeal.score = user.score * (oldDeal.isPremiumDeal || sub != nil ? 2 : 1)
        oldDeal.birthDate = ISO8601DateFormatter().date(from: newDeal.birthDate) ?? .init()
        oldDeal.isMale = newDeal.isMale
        oldDeal.petClass = newDeal.petClass.rawValue
        oldDeal.$petBreed.id = newDeal.petBreedID
        oldDeal.$petType.id = newDeal.petTypeID
        oldDeal.mode = newDeal.mode.rawValue
        oldDeal.title = newDeal.title
        oldDeal.description = newDeal.description
        oldDeal.photoPaths = photoPaths
        oldDeal.tags = tags
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
        
        for photoPath in deal.photoPaths {
            try? await FileManager.set(req: req, with: photoPath, data: .init())
        }
        
        try await deal.delete(on: req.db)
        
        return .ok
    }
    
    private func filterDeals(deals: inout QueryBuilder<Deal>, filter: Filter? = nil) {
        let checkedIDs = filter?.checkedIDs ?? .init()
        
        deals = deals.filter(\.$isActive == true).filter(\.$id !~ checkedIDs)
        
        if let petTypeID = filter?.petTypeID {
            deals = deals.filter(\.$petType.$id == petTypeID)
        }
        
        if let petBreedID = filter?.petBreedID {
            deals = deals.filter(\.$petBreed.$id == petBreedID)
        }
        
        if let petClass = filter?.petClass, petClass != .allClass {
            deals = deals.filter(\.$petClass == petClass.rawValue)
        }
        
        if let isMale = filter?.isMale {
            deals = deals.filter(\.$isMale == isMale)
        }
        
        if let country = filter?.country, !country.isEmpty {
            deals = deals.filter(\.$country == country)
        }
        
        if let city = filter?.city, !city.isEmpty {
            deals = deals.filter(\.$city == city)
        }
        
        if let title = filter?.title, !title.isEmpty {
            deals = deals.group(.or) {
                for word in title.split(separator: " ").map({ String($0) }) where !word.isEmpty {
                    $0.group(.or) {
                        $0.filter(Deal.self, \.$title, .custom("ilike"), "%\(word)%")
                            .filter(Deal.self, \.$tags, .custom("ilike"), word)
                    }
                }
            }
        }
    }
    
}
