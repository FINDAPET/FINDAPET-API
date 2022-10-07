//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import NIOFoundationCompat
import Vapor
import APNS

struct DealController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let deals = routes.grouped("deals")
        let userTokenProtected = deals.grouped(UserToken.authenticator())
        
        deals.get("all", use: self.index(req:))
        deals.get(":dealID", use: self.someDeal(req:))
        deals.get(":dealID", "offers", use: self.dealOffers(req:))
        
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.put(":dealID", "deactivate", use: self.deactivateDeal(req:))
        userTokenProtected.put(":dealID", "activate", use: self.activateDeal(req:))
        userTokenProtected.put(":dealID", "offer", ":offerID", "sold", use: self.sold(req:))
        userTokenProtected.delete(":dealID", "delete", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [Deal.Output] {
        let filter = try? req.content.decode(Filter.self)
        var deals = try await Deal.query(on: req.db).all()
        var dealsOutput = [Deal.Output]()
        
        self.filterDeals(deals: &deals, filter: filter)
        
        for deal in deals {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let buffer = try? await req.fileio.collectFile(at: photoPath) {
                    photoDatas.append(Data(buffer: buffer))
                }
            }
            
            dealsOutput.append(Deal.Output(
                id: deal.id,
                title: deal.title,
                photoDatas: photoDatas,
                tags: deal.tags,
                isPremiumDeal: deal.isPremiumDeal,
                isActive: deal.isActive,
                viewsCount: deal.viewsCount,
                mode: deal.mode,
                petType: deal.petType,
                petBreed: deal.petBreed,
                showClass: deal.showClass,
                isMale: deal.isMale,
                age: deal.age,
                color: deal.color,
                price: deal.price,
                cattery: User.Output(
                    name: String(),
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output]()
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
        
        let cattery = try await deal.$cattery.get(on: req.db)
        let buyer = try await deal.$buyer.get(on: req.db)
        var photoDatas = [Data]()
        var offersOutput = [Offer.Output]()
        var catteryAvatarData: Data?
        var buyerAvatarData: Data?
        
        if let path = cattery.avatarPath, let buffer = try? await req.fileio.collectFile(at: path) {
            catteryAvatarData = Data(buffer: buffer)
        }
        
        if let path = buyer?.avatarPath, let buffer = try? await req.fileio.collectFile(at: path) {
            buyerAvatarData = Data(buffer: buffer)
        }
        
        for photoPath in deal.photoPaths {
            if let buffer = try? await req.fileio.collectFile(at: photoPath) {
                photoDatas.append(Data(buffer: buffer))
            }
        }
        
        for offer in try await deal.$offers.get(on: req.db) {
            let offerBuyer = try await offer.$buyer.get(on: req.db)
            var offerBuyerAvatarData: Data?
            
            if let path = offerBuyer.avatarPath, let buffer = try? await req.fileio.collectFile(at: path) {
                offerBuyerAvatarData = Data(buffer: buffer)
            }
            
            offersOutput.append(Offer.Output(
                id: offer.id,
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
                    chatRooms: [ChatRoom.Output]()
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
                    petType: deal.petType,
                    petBreed: deal.petBreed,
                    showClass: deal.showClass,
                    isMale: deal.isMale,
                    age: deal.age,
                    color: deal.color,
                    price: deal.price,
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
                        chatRooms: [ChatRoom.Output]()
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
                        chatRooms: [ChatRoom.Output]()
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
                    chatRooms: [ChatRoom.Output]()
                )
            ))
        }
        
        return Deal.Output(
            id: deal.id,
            title: deal.title,
            photoDatas: photoDatas,
            tags: deal.tags,
            isPremiumDeal: deal.isPremiumDeal,
            isActive: deal.isActive,
            viewsCount: deal.viewsCount,
            mode: deal.mode,
            petType: deal.petType,
            petBreed: deal.petBreed,
            showClass: deal.showClass,
            isMale: deal.isMale,
            age: deal.age,
            color: deal.color,
            price: deal.price,
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
                chatRooms: [ChatRoom.Output]()
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
                chatRooms: [ChatRoom.Output]()
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
            if deleteOffer.id != offer.id {
                try? await deleteOffer.delete(on: req.db)
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
            
            try await req.fileio.writeFile(ByteBuffer(data: photoData), at: path)
            
            photoPaths.append(path)
        }
        
        try await Deal(id: deal.id,
                       title: deal.title,
                       photoPaths: photoPaths,
                       tags: deal.tags,
                       isPremiumDeal: deal.isPremiumDeal,
                       isActive: deal.isActive,
                       mode: deal.mode,
                       petType: deal.petType,
                       petBreed: deal.petBreed,
                       showClass: deal.showClass,
                       isMale: deal.isMale,
                       age: deal.age,
                       color: deal.color,
                       price: deal.price,
                       catteryID: deal.catteryID,
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
        
        oldDeal.mail = newDeal.mail
        oldDeal.vkUsername = newDeal.vkUsername
        oldDeal.facebookUsername = newDeal.facebookUsername
        oldDeal.instagramUsername = newDeal.instagramUsername
        oldDeal.telegramUsername = newDeal.telegramUsername
        oldDeal.city = newDeal.city
        oldDeal.country = newDeal.country
        oldDeal.price = newDeal.price
        oldDeal.age = newDeal.age
        oldDeal.isMale = newDeal.isMale
        oldDeal.showClass = newDeal.showClass
        oldDeal.petBreed = newDeal.petBreed
        oldDeal.petType = newDeal.petType
        oldDeal.mode = newDeal.mode
        oldDeal.title = newDeal.title
        oldDeal.description = newDeal.description
        oldDeal.photoPaths = photoPaths
        oldDeal.tags = newDeal.tags
        oldDeal.color = newDeal.color
        
        try await oldDeal.save(on: req.db)
        
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
        
        return .ok
    }
    
    private func filterDeals(deals: inout [Deal], filter: Filter?) {
        deals = deals.filter { $0.isActive }
        
        if let mode = filter?.mode {
            deals = deals.filter { $0.mode == mode }
        }
        
        if let petType = filter?.petType {
            deals = deals.filter { $0.petType == petType }
        }
        
        if let petBreed = filter?.petBreed {
            deals = deals.filter { $0.petBreed == petBreed }
        }
        
        if let showClass = filter?.showClass {
            deals = deals.filter { $0.showClass == showClass }
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
        var mode: String?
        var petType: String?
        var petBreed: String?
        var showClass: String?
        var isMale: Bool?
        var country: String?
        var city: String?
        
        enum PriceMode: Codable {
            case ascending, descending
        }
    }
    
}