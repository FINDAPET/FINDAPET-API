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
        
        offers.webSocket("new", onUpgrade: self.create(req:ws:))
        userTokenProtected.delete(":offerID", "delete", use: self.delete(req:))
        userTokenProtected.get("all", "admin", use: self.index(req:))
    }
    
    private func index(req: Request) async throws -> [Offer.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let offers = try await Offer.query(on: req.db).all()
        var offersOutput = [Offer.Output]()
        
        for offer in offers {
            let deal = try await offer.$deal.get(on: req.db)
            let buyer = try await offer.$buyer.get(on: req.db)
            let cattery = try await offer.$cattery.get(on: req.db)
            var dealPhotoData: Data?
            var buyerPhotoData: Data?
            var catteryPhtotData: Data?
            
            if let path = deal.photoPaths.first, let buffer = try? await req.fileio.collectFile(at: path) {
                dealPhotoData = Data(buffer: buffer)
            }
            
            if let path = buyer.avatarPath, let buffer = try? await req.fileio.collectFile(at: path) {
                buyerPhotoData = Data(buffer: buffer)
            }
            
            if let path = cattery.avatarPath, let buffer = try? await req.fileio.collectFile(at: path) {
                catteryPhtotData = Data(buffer: buffer)
            }
            
            offersOutput.append(Offer.Output(
                id: offer.id,
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
                    offers: [Offer.Output]()
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
                    showClass: deal.showClass,
                    isMale: deal.isMale,
                    age: deal.age,
                    color: deal.color,
                    price: deal.price,
                    cattery: User.Output(name: "", deals: [Deal.Output](), boughtDeals: [Deal.Output](), ads: [Ad.Output](), myOffers: [Offer.Output](), offers: [Offer.Output]()),
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
                    offers: [Offer.Output]()
                )
            ))
        }
        
        return offersOutput
    }
    
    private func create(req: Request, ws: WebSocket) {
        guard (try? req.auth.require(User.self)) != nil else {
            print("❌ Error: unautorized.")

            return
        }
        
        ws.onBinary { ws, buffer in
            guard let offerInput = try? JSONDecoder().decode(Offer.Input.self, from: buffer) else {
                print("❌ Error: decoding failed.")
                
                return
            }
            
            guard offerInput.catteryID != offerInput.buyerID else {
                print("❌ Error: illegal.")
                
                return
            }
            
            let offer = Offer(buyerID: offerInput.buyerID, dealID: offerInput.dealID, catteryID: offerInput.catteryID)
            
            offer.save(on: req.db).whenSuccess {
                WebSocketManager.shared.addOfferWebSocket(offer: offer, webSocket: ws)
            }
        }
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(User.self)
        
        guard let offer = try await Offer.find(req.parameters.get("offerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await offer.delete(on: req.db)
        
        WebSocketManager.shared.removeOfferWebSocket(offer: offer)
        
        return .ok
    }
    
}
