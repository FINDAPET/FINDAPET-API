//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.08.2022.
//

import Foundation
import NIOFoundationCompat
import Vapor

struct OfferController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let offers = routes.grouped("offers")
        let userTokenProtected = offers.grouped(UserToken.authenticator())
        
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.delete(":offerID", "delete", use: self.delete(req:))
        userTokenProtected.get("all", "admin", use: self.index(req:))
    }
    
    private func index(req: Request) async throws -> [Offer.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let offers = try await Offer.query(on: req.db).all()
        let user = try req.auth.require(User.self)
        var offersOutput = [Offer.Output]()
        
        for offer in offers {
            let deal = try await offer.$deal.get(on: req.db)
            let buyer = try await offer.$buyer.get(on: req.db)
            let cattery = try await offer.$cattery.get(on: req.db)
            var dealPhotoData: Data?
            var buyerPhotoData: Data?
            var catteryPhtotData: Data?
            
            if let path = deal.photoPaths.first {
                dealPhotoData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = buyer.avatarPath {
                buyerPhotoData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = cattery.avatarPath {
                catteryPhtotData = try? await FileManager.get(req: req, with: path)
            }
            
            offersOutput.append(Offer.Output(
                id: offer.id,
                price: offer.price,
                currencyName: offer.currencyName,
                buyer: User.Output(
                    id: buyer.id,
                    name: buyer.name,
                    avatarData: buyerPhotoData,
                    documentData: nil,
                    description: buyer.description,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: buyer.isPremiumUser
                ),
                deal: Deal.Output(
                    id: deal.id,
                    title: deal.title,
                    photoDatas: [dealPhotoData ?? Data()],
                    tags: deal.tags,
                    isPremiumDeal: deal.isPremiumDeal,
                    isActive: deal.isActive,
                    viewsCount: deal.viewsCount,
                    mode: deal.mode,
                    petType: deal.petType,
                    petBreed: deal.petBreed,
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
                ),
                cattery: User.Output(
                    id: cattery.id,
                    name: cattery.name,
                    avatarData: catteryPhtotData,
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
        
        return offersOutput
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard (try? req.auth.require(User.self)) != nil else {
            throw Abort(.unauthorized)
        }
        
        guard let offerInput = try? req.content.decode(Offer.Input.self), offerInput.catteryID != offerInput.buyerID else {
            throw Abort(.badRequest)
        }
        
        guard let deviceToken = try await User.find(offerInput.catteryID, on: req.db)?.deviceToken else {
            throw Abort(.notFound)
        }
        
        try await Offer(
            buyerID: offerInput.buyerID,
            dealID: offerInput.dealID,
            catteryID: offerInput.catteryID,
            price: offerInput.price,
            currencyName: offerInput.currencyName.rawValue
        ).save(on: req.db)
        
        try? req.apns.send(.init(title: "You have a new offer"), to: deviceToken).wait()
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(User.self)
        
        guard let offer = try await Offer.find(req.parameters.get("offerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await offer.delete(on: req.db)
                
        return .ok
    }
    
}
