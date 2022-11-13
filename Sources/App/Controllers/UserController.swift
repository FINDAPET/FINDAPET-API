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

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        let userTokenProtected = users.grouped(UserToken.authenticator())
        
        users.post("new", use: self.create(req:))
        
        userTokenProtected.get(":userID", "deals", use: self.someUserDeals(req:))
        userTokenProtected.get(":userID", "deals", "bought", use: self.someUserBoughtDeals(req:))
        userTokenProtected.get(":userID", "ads", use: self.someUserAds(req:))
        userTokenProtected.get(":userID", "offers", "my", use: self.myOffers(req:))
        userTokenProtected.get(":userID", "offers", use: self.offers(req:))
        userTokenProtected.get(":userID", use: self.someUser(req:))
        userTokenProtected.get("chats", use: self.chatRooms(req:))
        userTokenProtected.put("change", use: self.changeUser(req:))
        userTokenProtected.put("change", ":currencyName", use: self.changeUserCurrencyName(req:))
        userTokenProtected.get("me", use: self.user(req:))
        userTokenProtected.delete(":userID", "delete", "admin", use: self.deleteUser(req:))
        userTokenProtected.put(":userID", "admin", "on", use: self.createAdmin(req:))
        userTokenProtected.put(":userID", "admin", "off", use: self.deleteAdmin(req:))
        userTokenProtected.get("all", "admin", use: self.index(req:))
        userTokenProtected.get("all", "catteryes", "admin", use: self.indexCatteryes(req:))
        userTokenProtected.get("all", "users", "admin", use: self.indexUsers(req:))
        userTokenProtected.get("all", "catteryes", "wait", "admin", use: self.indexWaitVerify(req:))
        userTokenProtected.put(":userID", "approove", "cattery", "admin", use: self.aprooveCatteryVerify(req:))
        userTokenProtected.put(":userID", "delete", "cattery", "admin", use: self.deleteCatteryVerify(req:))
        userTokenProtected.webSocket("update", onUpgrade: self.userWebSocket(req:ws:))
        userTokenProtected.put("premium", use: self.makeUserPremium(req:))
        userTokenProtected.put("not", "premium", use: self.makeUserNotPremium(req:))
    }
    
    private func index(req: Request) async throws -> [User.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let users = try await User.query(on: req.db).all()
        var usersOutput = [User.Output]()
        
        for user in users {
            var avatarData: Data?
            var documentData: Data?
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = user.documentPath {
                documentData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: documentData,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: user.isPremiumUser
            ))
        }
        
        return usersOutput
    }
    
    private func aprooveCatteryVerify(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let cattery = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        cattery.isActiveCattery = true
        cattery.isCatteryWaitVerify = false
        
        if let path = cattery.documentPath {
            try await FileManager.set(req: req, with: path, data: .init())

            cattery.avatarPath = .init()
        }
        
        try await cattery.save(on: req.db)
        
        if let deviceToken = cattery.deviceToken {
            try req.apns.send(.init(title: "Your cattery is confirmed!"), to: deviceToken).wait()
        }
        
        return .ok
    }
    
    private func deleteCatteryVerify(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let cattery = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        cattery.isActiveCattery = false
        cattery.isCatteryWaitVerify = false
        
        try await cattery.save(on: req.db)
                
        return .ok
    }
    
    private func indexCatteryes(req: Request) async throws -> [User.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let users = try await User.query(on: req.db).all().filter { $0.isActiveCattery }
        var usersOutput = [User.Output]()
        
        for user in users {
            var avatarData: Data?
            var documentData: Data?
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = user.documentPath {
                documentData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: documentData,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: user.isPremiumUser
            ))
        }
        
        return usersOutput
    }
    
    private func indexUsers(req: Request) async throws -> [User.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let users = try await User.query(on: req.db).all().filter { !$0.isActiveCattery }
        var usersOutput = [User.Output]()
        
        for user in users {
            var avatarData: Data?
            var documentData: Data?
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = user.documentPath {
                documentData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: documentData,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: user.isPremiumUser
            ))
        }
        
        return usersOutput
    }
    
    private func indexWaitVerify(req: Request) async throws -> [User.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let users = try await User.query(on: req.db).all().filter { $0.isCatteryWaitVerify }
        var usersOutput = [User.Output]()
        
        for user in users {
            var avatarData: Data?
            var documentData: Data?
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = user.documentPath {
                documentData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: documentData,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                isPremiumUser: user.isPremiumUser
            ))
        }
        
        return usersOutput
    }
    
    private func someUser(req: Request) async throws -> User.Output {
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let user = try req.auth.require(User.self)
        var avatarData: Data?
        var documentData: Data?
        var deals = [Deal.Output]()
        var boughtDeals = [Deal.Output]()
        var ads = [Ad.Output]()
        var myOffers = [Offer.Output]()
        var offers = [Offer.Output]()
        
        if let path = someUser.avatarPath {
            avatarData = try? await FileManager.get(req: req, with: path)
        }
        
        if let path = someUser.documentPath {
            documentData = try? await FileManager.get(req: req, with: path)
        }
        
        for deal in try await someUser.$deals.get(on: req.db) {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            deals.append(Deal.Output(
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
                price: Double(try await CurrencyConverter.convert(
                    from: deal.currencyName,
                    to: someUser.basicCurrencyName,
                    amount: deal.price
                ).result),
                currencyName: someUser.basicCurrencyName,
                cattery: User.Output(
                    name: someUser.name,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: someUser.isPremiumUser
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
        
        for deal in try await someUser.$boughtDeals.get(on: req.db) {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            boughtDeals.append(Deal.Output(
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
                price: Double(try await CurrencyConverter.convert(
                    from: deal.currencyName,
                    to: user.basicCurrencyName,
                    amount: deal.price
                ).result),
                currencyName: user.basicCurrencyName,
                cattery: User.Output(
                    name: someUser.name,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: someUser.isPremiumUser
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
        
        for ad in try await someUser.$ads.get(on: req.db) {
            if let data = try? await FileManager.get(req: req, with: ad.contentPath) {
                ads.append(Ad.Output(
                    id: ad.id,
                    contentData: data,
                    custromerName: ad.custromerName,
                    link: ad.link,
                    cattery: User.Output(
                        name: someUser.name,
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output](),
                        isPremiumUser: someUser.isPremiumUser
                    )
                ))
            }
        }
        
        for myOffer in try await someUser.$myOffers.get(on: req.db) {
            let deal = try await myOffer.$deal.get(on: req.db)
            let buyer = try await myOffer.$buyer.get(on: req.db)
            var dealPhotoData: Data?
            var buyerAvatarData: Data?
            
            if let path = buyer.avatarPath {
                dealPhotoData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = deal.photoPaths.first {
                buyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            offers.append(Offer.Output(
                price: myOffer.price,
                currencyName: myOffer.currencyName,
                buyer: User.Output(
                    name: buyer.name,
                    avatarData: buyerAvatarData,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: buyer.isPremiumUser
                ),
                deal: Deal.Output(
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
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    name: String(),
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: user.isPremiumUser
                )
            ))
        }
        
        for offer in try await someUser.$offers.get(on: req.db) {
            let deal = try await offer.$deal.get(on: req.db)
            let buyer = try await offer.$buyer.get(on: req.db)
            var dealPhotoData: Data?
            var buyerAvatarData: Data?
            
            if let path = buyer.avatarPath {
                dealPhotoData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = deal.photoPaths.first {
                buyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            myOffers.append(Offer.Output(
                price: offer.price,
                currencyName: offer.currencyName,
                buyer: User.Output(
                    name: buyer.name,
                    avatarData: buyerAvatarData,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: buyer.isPremiumUser
                ),
                deal: Deal.Output(
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
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    name: String(),
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: user.isPremiumUser
                )
            ))
        }
        
        return User.Output(
            id: someUser.id,
            name: someUser.name,
            avatarData: avatarData,
            documentData: documentData,
            description: someUser.description,
            deals: deals,
            boughtDeals: boughtDeals,
            ads: ads,
            myOffers: myOffers,
            offers: offers,
            chatRooms: [ChatRoom.Output](),
            isPremiumUser: someUser.isPremiumUser
        )
    }
    
    private func user(req: Request) async throws -> User.Output {
        let user = try req.auth.require(User.self)
        
        var avatarData: Data?
        var documentData: Data?
        var deals = [Deal.Output]()
        var boughtDeals = [Deal.Output]()
        var ads = [Ad.Output]()
        var myOffers = [Offer.Output]()
        var offers = [Offer.Output]()
        var chatRooms = [ChatRoom.Output]()
        
        if let path = user.avatarPath {
            avatarData = try? await FileManager.get(req: req, with: path)
        }
        
        if let path = user.documentPath {
            documentData = try? await FileManager.get(req: req, with: path)
        }
        
        for deal in try await user.$deals.get(on: req.db) {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            deals.append(Deal.Output(
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
                price: Double(try await CurrencyConverter.convert(
                    from: deal.currencyName,
                    to: user.basicCurrencyName,
                    amount: deal.price
                ).result),
                currencyName: user.basicCurrencyName,
                cattery: User.Output(
                    name: user.name,
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
        
        for deal in try await user.$boughtDeals.get(on: req.db) {
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            boughtDeals.append(Deal.Output(
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
                price: Double(try await CurrencyConverter.convert(
                    from: deal.currencyName,
                    to: user.basicCurrencyName,
                    amount: deal.price
                ).result),
                currencyName: user.basicCurrencyName,
                cattery: User.Output(
                    name: user.name,
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
        
        for ad in try await user.$ads.get(on: req.db) {
            if let data = try? await FileManager.get(req: req, with: ad.contentPath) {
                ads.append(Ad.Output(
                    id: ad.id,
                    contentData: data,
                    custromerName: ad.custromerName,
                    link: ad.link,
                    cattery: User.Output(
                        name: user.name,
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output](),
                        isPremiumUser: user.isPremiumUser
                    )
                ))
            }
        }
        
        for myOffer in try await user.$myOffers.get(on: req.db) {
            let deal = try await myOffer.$deal.get(on: req.db)
            let buyer = try await myOffer.$buyer.get(on: req.db)
            var dealPhotoData: Data?
            var buyerAvatarData: Data?
            
            if let path = buyer.avatarPath {
                dealPhotoData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = deal.photoPaths.first {
                buyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            myOffers.append(Offer.Output(
                price: myOffer.price,
                currencyName: myOffer.currencyName,
                buyer: User.Output(
                    name: buyer.name,
                    avatarData: buyerAvatarData,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: buyer.isPremiumUser
                ),
                deal: Deal.Output(
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
                    price: Double(try await CurrencyConverter.convert(
                        from: deal.currencyName,
                        to: user.basicCurrencyName,
                        amount: deal.price
                    ).result),
                    currencyName: user.basicCurrencyName,
                    cattery: User.Output(
                        name: "",
                        deals: [Deal.Output](),
                        boughtDeals: [Deal.Output](),
                        ads: [Ad.Output](),
                        myOffers: [Offer.Output](),
                        offers: [Offer.Output](),
                        chatRooms: [ChatRoom.Output](),
                        isPremiumUser: user.isPremiumUser
                    ),
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    name: "",
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: user.isPremiumUser
                )
            ))
        }
        
        for offer in try await user.$offers.get(on: req.db) {
            let deal = try await offer.$deal.get(on: req.db)
            let buyer = try await offer.$buyer.get(on: req.db)
            var dealPhotoData: Data?
            var buyerAvatarData: Data?
            
            if let path = buyer.avatarPath {
                dealPhotoData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = deal.photoPaths.first {
                buyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            offers.append(Offer.Output(
                price: offer.price,
                currencyName: offer.currencyName,
                buyer: User.Output(
                    name: buyer.name,
                    avatarData: buyerAvatarData,
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: buyer.isPremiumUser
                ),
                deal: Deal.Output(
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
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    name: String(),
                    deals: [Deal.Output](),
                    boughtDeals: [Deal.Output](),
                    ads: [Ad.Output](),
                    myOffers: [Offer.Output](),
                    offers: [Offer.Output](),
                    chatRooms: [ChatRoom.Output](),
                    isPremiumUser: user.isPremiumUser
                )
            ))
        }
        
        for chatRoomID in user.chatRoomsID {
            var messages = [Message.Output]()
            var users = [User.Output]()
            
            if let chatRoom = try? await ChatRoom.find(chatRoomID, on: req.db) {
                for message in (try? await chatRoom.$messages.get(on: req.db)) ?? [Message]() {
                    if let messageUser = try? await message.$user.get(on: req.db) {
                        var bodyData: Data?
                        
                        if let path = message.bodyPath {
                            bodyData = try? await FileManager.get(req: req, with: path)
                        }
                        
                        messages.append(Message.Output(
                            id: message.id,
                            text: message.text,
                            bodyData: bodyData,
                            user: User.Output(
                                id: messageUser.id,
                                name: messageUser.name,
                                deals: [Deal.Output](),
                                boughtDeals: [Deal.Output](),
                                ads: [Ad.Output](),
                                myOffers: [Offer.Output](),
                                offers: [Offer.Output](),
                                chatRooms: [ChatRoom.Output](),
                                isPremiumUser: messageUser.isPremiumUser
                            ),
                            createdAt: message.$createdAt.timestamp,
                            chatRoom: ChatRoom.Output(users: [User.Output](), messages: [Message.Output]())
                        ))
                    }
                }
                
                for userID in chatRoom.usersID {
                    if let chatUser = try? await User.find(userID, on: req.db) {
                        var avatarData: Data?
                        
                        if let path = chatUser.avatarPath {
                            avatarData = try? await FileManager.get(req: req, with: path)
                        }
                        
                        users.append(User.Output(
                            id: chatUser.id,
                            name: chatUser.name,
                            avatarData: avatarData,
                            deals: [Deal.Output](),
                            boughtDeals: [Deal.Output](),
                            ads: [Ad.Output](),
                            myOffers: [Offer.Output](),
                            offers: [Offer.Output](),
                            chatRooms: [ChatRoom.Output](),
                            isPremiumUser: chatUser.isPremiumUser
                        ))
                    }
                }
                
                chatRooms.append(ChatRoom.Output(
                    id: chatRoom.id,
                    users: users,
                    messages: messages
                ))
            }
        }
        
        return User.Output(
            id: user.id,
            name: user.name,
            avatarData: avatarData,
            documentData: documentData,
            description: user.description,
            deals: deals,
            boughtDeals: boughtDeals,
            ads: ads,
            myOffers: myOffers,
            offers: offers,
            chatRooms: chatRooms,
            isPremiumUser: user.isPremiumUser
        )
    }
    
    private func someUserDeals(req: Request) async throws -> [Deal.Output] {
        try await self.someUser(req: req).deals
    }
    
    private func someUserBoughtDeals(req: Request) async throws -> [Deal.Output] {
        try await self.someUser(req: req).boughtDeals
    }
    
    private func someUserAds(req: Request) async throws -> [Ad.Output] {
        try await self.someUser(req: req).ads
    }
    
    private func myOffers(req: Request) async throws -> [Offer.Output] {
        try await self.someUser(req: req).myOffers
    }
    
    private func offers(req: Request) async throws -> [Offer.Output] {
        try await self.someUser(req: req).offers
    }
    
    private func chatRooms(req: Request) async throws -> [ChatRoom.Output] {
        try await self.user(req: req).chatRooms
    }
    
    private func makeUserPremium(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let productID = try req.content.decode(Subscription.self).productID
        let block: @Sendable (Timer) -> Void = { timer in
            req.redirect(to: "/users/not/premium").encodeResponse(for: req).whenFailure { print("❌ Error: \($0.localizedDescription)") }
        }
        
        user.isPremiumUser = true
        
        try await user.save(on: req.db)
        
        for deal in try await user.$deals.get(on: req.db) {
            deal.isPremiumDeal = true
            
            try await deal.save(on: req.db)
        }
        
        switch productID {
        case .premiumSubscriptionOneMonth:
            RunLoop.main.add(
                Timer(
                    timeInterval: Calendar.current.nextDate(
                        after: .init(),
                        matching: .init(month: 1),
                        matchingPolicy: .previousTimePreservingSmallerComponents
                    )?.timeIntervalSinceNow ?? .init(),
                    repeats: false,
                    block: block
                ),
                forMode: .common
            )
        case .premiumSubscriptionThreeMonth:
            RunLoop.main.add(
                Timer(
                    timeInterval: Calendar.current.nextDate(
                        after: .init(),
                        matching: .init(month: 3),
                        matchingPolicy: .previousTimePreservingSmallerComponents
                    )?.timeIntervalSinceNow ?? .init(),
                    repeats: false,
                    block: block
                ),
                forMode: .common
            )
        case .premiumSubscriptionSixMonth:
            RunLoop.main.add(
                Timer(
                    timeInterval: Calendar.current.nextDate(
                        after: .init(),
                        matching: .init(month: 6),
                        matchingPolicy: .previousTimePreservingSmallerComponents
                    )?.timeIntervalSinceNow ?? .init(),
                    repeats: false,
                    block: block
                ),
                forMode: .common
            )
        case .premiumSubscriptionOneYear:
            RunLoop.main.add(
                Timer(
                    timeInterval: Calendar.current.nextDate(
                        after: .init(),
                        matching: .init(year: 1),
                        matchingPolicy: .previousTimePreservingSmallerComponents
                    )?.timeIntervalSinceNow ?? .init(),
                    repeats: false,
                    block: block
                ),
                forMode: .common
            )
        default:
            break
        }
        
        return .ok
    }
    
    private func makeUserNotPremium(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        user.isPremiumUser = false
        
        try await user.save(on: req.db)
        
        for deal in try await user.$deals.get(on: req.db) {
            deal.isPremiumDeal = false
            
            try await deal.save(on: req.db)
        }
        
        return .ok
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        try User.Create.validate(content: req)
        
        let create = try req.content.decode(User.Create.self)
        
        try await User(email: create.email, passwordHash: Bcrypt.hash(create.password)).save(on: req.db)
        
        return .ok
    }
    
    private func changeUserCurrencyName(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let currencyName = req.parameters.get("currencyName") else {
            throw Abort(.notFound)
        }
        
        user.basicCurrencyName = currencyName
        
        try await user.save(on: req.db)
        
        return .ok
    }
    
    private func changeUser(req: Request) async throws -> HTTPStatus {
        let authUser = try req.auth.require(User.self)
        let newUser = try req.content.decode(User.Input.self)
        
        guard let oldUser = try await User.find(newUser.id, on: req.db),
              oldUser.id == authUser.id || authUser.isAdmin else {
            throw Abort(.badRequest)
        }
        
        if let avatarData = newUser.avatarData,
           let avatarPath = oldUser.avatarPath != nil && oldUser.avatarPath != "" ? oldUser.avatarPath : req.application.directory.publicDirectory.appending(UUID().uuidString) {
            try await FileManager.set(req: req, with: avatarPath, data: avatarData)

            oldUser.avatarPath = avatarPath
        }
        
        if let documentData = newUser.documentData,
           let documentPath = oldUser.documentPath != nil ? oldUser.documentPath : req.application.directory.publicDirectory.appending(UUID().uuidString) {
            try await FileManager.set(req: req, with: documentPath, data: documentData)

            oldUser.documentPath = documentPath
        }
        
        oldUser.name = newUser.name
        oldUser.description = newUser.description
        oldUser.isCatteryWaitVerify = newUser.isCatteryWaitVerify
        oldUser.deviceToken = newUser.deviceToken
        oldUser.countryCode = newUser.countryCode?.rawValue
        oldUser.basicCurrencyName = newUser.basicCurrencyName
        
        try await oldUser.save(on: req.db)
        
        return .ok
    }
    
    private func createAdmin(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin,
              let user = try await User.find(req.parameters.get("userID"), on: req.db), !user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        user.isAdmin = true
        
        try await user.save(on: req.db)
        
        return .ok
    }
    
    private func deleteAdmin(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin,
              let user = try await User.find(req.parameters.get("userID"), on: req.db), user.isAdmin else {
            throw Abort(.badRequest)
        }
        
        user.isAdmin = false
        
        try await user.save(on: req.db)
        
        return .ok
    }
    
    private func deleteUser(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await user.delete(on: req.db)
        
        return .ok
    }
    
    private func userWebSocket(req: Request, ws: WebSocket) async {
        guard let userID = try? req.auth.require(User.self).id else {
            print("❌ Error: not authorized.")
            
            try? await ws.close()
            
            return
        }
        
        ws.onClose.whenSuccess {
            UserWebSocketManager.shared.removeUserWebSocket(id: userID)
        }
        
        UserWebSocketManager.shared.addUserWebSocket(id: userID, ws: ws)
    }
    
}
