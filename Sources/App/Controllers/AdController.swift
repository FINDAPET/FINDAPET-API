//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 05.08.2022.
//

import Foundation
import Vapor

struct AdController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let ads = routes.grouped("ads")
        let userTokenProtected = ads.grouped(UserToken.authenticator())
        
        ads.get("all", use: self.index(req:))
        
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.post("new", "admin", use: self.createAdmin(req:))
        userTokenProtected.put("change", "admin", use: self.change(req:))
        userTokenProtected.put(":adID", "deactivate", use: self.deactivate(req:))
        userTokenProtected.put(":adID", "activate", use: self.activate(req:))
        userTokenProtected.delete(":adID", "delete", use: self.delete(req:))
        userTokenProtected.get("all", "admin", use: self.index(req:))
        userTokenProtected.get("random", use: self.randomAd(req:))
    }
    
    private func index(req: Request) async throws -> [Ad.Output] {
        let ads = try await Ad.query(on: req.db).all().filter { $0.isActive }
        var adsOutput = [Ad.Output]()
        
        for ad in ads {
            let cattery = try await ad.$cattery.get(on: req.db)
            var avatarData: Data?
            
            if let path = cattery?.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            adsOutput.append(Ad.Output(
                id: ad.id,
                contentData: (try? await FileManager.get(req: req, with: ad.contentPath)) ?? Data(),
                custromerName: ad.custromerName,
                link: ad.link,
                cattery: User.Output(
                    id: cattery?.id,
                    name: cattery?.name ?? "",
                    avatarData: avatarData,
                    documentData: nil,
                    description: cattery?.description,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: cattery?.isPremiumUser ?? false
                )
            ))
        }
        
        return adsOutput
    }
    
    private func randomAd(req: Request) async throws -> Ad.Output {
        guard let ad = try await Ad.query(on: req.db).all().randomElement() else {
            throw Abort(.notFound)
        }
        
        let cattery = try await ad.$cattery.get(on: req.db)
        var avatarData: Data?
        
        if let path = cattery?.avatarPath {
            avatarData = try? await FileManager.get(req: req, with: path)
        }
        
        return Ad.Output(
            id: ad.id,
            contentData: (try? await FileManager.get(req: req, with: ad.contentPath)) ?? Data(),
            custromerName: ad.custromerName,
            link: ad.link,
            cattery: User.Output(
                id: cattery?.id,
                name: cattery?.name ?? "",
                avatarData: avatarData,
                documentData: nil,
                description: cattery?.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: cattery?.isPremiumUser ?? false
            )
        )
    }
    
    private func indexAdimn(req: Request) async throws -> [Ad.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let ads = try await Ad.query(on: req.db).all()
        var adsOutput = [Ad.Output]()
        
        for ad in ads {
            let cattery = try await ad.$cattery.get(on: req.db)
            var avatarData: Data?
            
            if let path = cattery?.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            adsOutput.append(Ad.Output(
                id: ad.id,
                contentData: (try? await FileManager.get(req: req, with: ad.contentPath)) ?? Data(),
                custromerName: ad.custromerName,
                link: ad.link,
                cattery: User.Output(
                    id: cattery?.id,
                    name: cattery?.name ?? "",
                    avatarData: avatarData,
                    documentData: nil,
                    description: cattery?.description,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: cattery?.isPremiumUser ?? false
                )
            ))
        }
        
        return adsOutput
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        let ad = try req.content.decode(Ad.Input.self)
        let path = req.application.directory.publicDirectory.appending(UUID().uuidString)
        
        try await FileManager.set(req: req, with: path, data: ad.contentData)
        
        try await Ad(contentPath: path, catteryID: ad.catteryID, isActive: true).save(on: req.db)
        
        return .ok
    }
    
    private func createAdmin(req: Request) async throws -> HTTPStatus {
        let cattery = try req.auth.require(User.self)
        let ad = try req.content.decode(Ad.Input.self)
        let path = req.application.directory.publicDirectory.appending(UUID().uuidString)
        
        guard cattery.isAdmin else {
            throw Abort(.badRequest)
        }
        
        try await FileManager.set(req: req, with: path, data: ad.contentData)

        try await Ad(contentPath: path, custromerName: ad.customerName, link: ad.customerName, isActive: true).save(on: req.db)
        
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        let cattery = try req.auth.require(User.self)
        let newAd = try req.content.decode(Ad.Input.self)
        
        guard cattery.isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let oldAd = try await Ad.find(newAd.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await FileManager.set(req: req, with: oldAd.contentPath, data: newAd.contentData)

        oldAd.$cattery.id = newAd.catteryID
        oldAd.link = newAd.link
        oldAd.custromerName = newAd.customerName
        
        try await oldAd.save(on: req.db)
        
        return .ok
    }
    
    private func deactivate(req: Request) async throws -> HTTPStatus {
        let cattery = try req.auth.require(User.self)
        
        guard cattery.isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let ad = try await Ad.find(req.parameters.get("adID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        ad.isActive = false
        
        try await ad.save(on: req.db)
        
        return .ok
    }
    
    private func activate(req: Request) async throws -> HTTPStatus {
        let cattery = try req.auth.require(User.self)
        
        guard cattery.isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let ad = try await Ad.find(req.parameters.get("adID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        ad.isActive = true
        
        try await ad.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let ad = try await Ad.find(req.parameters.get("adID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await ad.delete(on: req.db)
        try await FileManager.set(req: req, with: ad.contentPath, data: .init())
        
        return .ok
    }
    
}
