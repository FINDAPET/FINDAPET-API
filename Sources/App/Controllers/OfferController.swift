//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.08.2022.
//

import Foundation
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
            
            let petType = try await deal.$petType.get(on: req.db)
            let petBreed = try await deal.$petBreed.get(on: req.db)
            
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
                    score: .zero
                ),
                deal: Deal.Output(
                    id: deal.id,
                    title: deal.title,
                    photoDatas: [dealPhotoData ?? Data()],
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
                        name: String(),
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
                    score: .zero
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
        
        guard let cattery = try await User.find(offerInput.catteryID, on: req.db) else { throw Abort(.notFound) }
        
        try await Offer(
            buyerID: offerInput.buyerID,
            dealID: offerInput.dealID,
            catteryID: offerInput.catteryID,
            price: offerInput.price,
            currencyName: offerInput.currencyName.rawValue
        ).save(on: req.db)
        
        for deviceToken in (try? await cattery.$deviceTokens.get(on: req.db)) ?? .init() {
            switch Platform.get(deviceToken.platform) {
            case .iOS:
                do {
                    req.apns.send(
                        .init(title: try LocalizationManager.main.get(cattery.countryCode, .youHaveANewOffer)),
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
//                    full version
                continue
            case .custom(_):
//                    full version
                continue
            }
        }
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        try req.auth.require(User.self)
        
        guard let offer = try await Offer.find(req.parameters.get("offerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await offer.delete(on: req.db)
                
        return .ok
    }
    
}
