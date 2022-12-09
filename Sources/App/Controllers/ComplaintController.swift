//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.12.2022.
//

import Foundation
import Vapor

struct ComplaintController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let complaints = routes.grouped("complaints")
        let userTokenProtected = complaints.grouped(UserToken.authenticator())
        
        userTokenProtected.get("all", use: self.index(req:))
        userTokenProtected.get(":complaintID", use: self.complaint(req:))
        userTokenProtected.post("new", use: self.create(req:))
        userTokenProtected.put("change", use: self.change(req:))
        userTokenProtected.delete(":complaintID", "delete", use: self.delete(req:))
    }
    
    func index(req: Request) async throws -> [Complaint.Output] {
        var complaints = [Complaint.Output]()
        
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        for complaint in try await Complaint.query(on: req.db).all() {
            guard let sender = try? await complaint.$sender.get(on: req.db) else {
                continue
            }
            
            var avatarData: Data?
            var dealOutput: Deal.Output?
            var userOutput: User.Output?
            
            if let deal = try? await complaint.$deal.get(on: req.db) {
                var datas = [Data]()
                var avatarData: Data?
                let user = try await deal.$cattery.get(on: req.db)
                
                if let path = deal.photoPaths.first, let data = try? await FileManager.get(req: req, with: path) {
                    datas.append(data)
                }
                
                if let path = user.avatarPath, let data = try? await FileManager.get(req: req, with: path) {
                    avatarData = data
                }
                
                dealOutput = .init(
                    id: deal.id,
                    title: deal.title,
                    photoDatas: datas,
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
                    price: deal.price,
                    currencyName: deal.currencyName,
                    cattery: .init(
                        name: user.name,
                        avatarData: avatarData,
                        description: user.description,
                        deals: .init(),
                        boughtDeals: .init(),
                        ads: .init(),
                        myOffers: .init(),
                        offers: .init(),
                        chatRooms: .init(),
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
                )
            }
            
            if let user = try? await complaint.$user.get(on: req.db) {
                var avatarData: Data?
                
                if let path = user.avatarPath, let data = try? await FileManager.get(req: req, with: path) {
                    avatarData = data
                }
                
                userOutput = .init(
                    id: user.id,
                    name: user.name,
                    avatarData: avatarData,
                    description: user.description,
                    deals: .init(),
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
                    isPremiumUser: user.isPremiumUser
                )
            }
            
            if let path = sender.avatarPath, let data = try? await FileManager.get(req: req, with: path) {
                avatarData = data
            }
            
            complaints.append(.init(
                id: complaint.id,
                text: complaint.text,
                sender: .init(
                    name: sender.name,
                    avatarData: avatarData,
                    description: sender.description,
                    deals: .init(),
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
                    isPremiumUser: sender.isPremiumUser
                ),
                createdAt: complaint.createdAt,
                deal: dealOutput,
                user: userOutput
            ))
        }
        
        return complaints
    }
    
    func complaint(req: Request) async throws -> Complaint.Output {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let complaint = try await Complaint.find(req.parameters.get("complaintID"), on: req.db),
              let sender = try? await complaint.$sender.get(on: req.db) else {
            throw Abort(.notFound)
        }
        
        var avatarData: Data?
        var dealOutput: Deal.Output?
        var userOutput: User.Output?
        
        if let deal = try? await complaint.$deal.get(on: req.db) {
            var datas = [Data]()
            var avatarData: Data?
            let user = try await deal.$cattery.get(on: req.db)
            
            if let path = deal.photoPaths.first, let data = try? await FileManager.get(req: req, with: path) {
                datas.append(data)
            }
            
            if let path = user.avatarPath, let data = try? await FileManager.get(req: req, with: path) {
                avatarData = data
            }
            
            dealOutput = .init(
                id: deal.id,
                title: deal.title,
                photoDatas: datas,
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
                price: deal.price,
                currencyName: deal.currencyName,
                cattery: .init(
                    name: user.name,
                    avatarData: avatarData,
                    description: user.description,
                    deals: .init(),
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
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
            )
        }
        
        if let user = try? await complaint.$user.get(on: req.db) {
            var avatarData: Data?
            
            if let path = user.avatarPath, let data = try? await FileManager.get(req: req, with: path) {
                avatarData = data
            }
            
            userOutput = .init(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                description: user.description,
                deals: .init(),
                boughtDeals: .init(),
                ads: .init(),
                myOffers: .init(),
                offers: .init(),
                chatRooms: .init(),
                isPremiumUser: user.isPremiumUser
            )
        }
        
        if let path = sender.avatarPath, let data = try? await FileManager.get(req: req, with: path) {
            avatarData = data
        }
        
        return .init(
            id: complaint.id,
            text: complaint.text,
            sender: .init(
                name: sender.name,
                avatarData: avatarData,
                description: sender.description,
                deals: .init(),
                boughtDeals: .init(),
                ads: .init(),
                myOffers: .init(),
                offers: .init(),
                chatRooms: .init(),
                isPremiumUser: sender.isPremiumUser
            ),
            createdAt: complaint.createdAt,
            deal: dealOutput,
            user: userOutput
        )
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(User.self)
        let input = try req.content.decode(Complaint.Input.self)
        
        try await Complaint(text: input.text, senderID: input.senderID, dealID: input.dealID, userID: input.userID).save(on: req.db)
        
        return .ok
    }
    
    func change(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let input = try req.content.decode(Complaint.Input.self)
        
        guard let complaint = try await Complaint.find(input.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        complaint.text = input.text
        complaint.$sender.id = input.senderID
        complaint.$deal.id = input.dealID
        complaint.$user.id = input.userID
        
        try await complaint.save(on: req.db)
        
        return .ok
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let complaint = try await Complaint.find(req.parameters.get("complaintID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await complaint.delete(on: req.db)
        
        return .ok
    }
    
}