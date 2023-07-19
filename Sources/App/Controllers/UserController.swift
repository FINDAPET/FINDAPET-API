//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
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
        userTokenProtected.get("chats", "id", use: self.chatRoomsID(req:))
        userTokenProtected.get("search", "titles", use: self.getSearchTitles(req:))
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
    }
    
    private func index(req: Request) async throws -> [User.Output] {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let users = try await User.query(on: req.db).all()
        var usersOutput = [User.Output]()
        
        for user in users {
            var avatarData: Data?
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: user.documentPath != nil && !user.isCatteryWaitVerify ? .init() : nil,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                score: user.score
            ))
        }
        
        return usersOutput
    }
    
    private func aprooveCatteryVerify(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard user.isAdmin, let userID = user.id else {
            throw Abort(.badRequest)
        }
        
        guard let cattery = try await User.find(req.parameters.get("userID"), on: req.db), let catteryID = cattery.id else {
            throw Abort(.notFound)
        }
        
        cattery.isActiveCattery = true
        cattery.isCatteryWaitVerify = false
        
        try await cattery.save(on: req.db)
        
        for deviceToken in try await cattery.$deviceTokens.get(on: req.db) {
            switch Platform.get(deviceToken.platform) {
            case .iOS:
                do {
                    req.apns.send(
                        .init(title: try LocalizationManager.main.get(cattery.countryCode, .yourCatteryIsConfirmed) + "!"),
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
        
        print("❕NOFIFICATION: admin with id \(userID) approove verify for cattery with id \(catteryID)")
        
        return .ok
    }
    
    private func deleteCatteryVerify(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard user.isAdmin, let userID = user.id else {
            throw Abort(.badRequest)
        }
        
        guard let cattery = try await User.find(req.parameters.get("userID"), on: req.db), let catteryID = cattery.id else {
            throw Abort(.notFound)
        }
        
        cattery.isActiveCattery = false
        cattery.isCatteryWaitVerify = false
        
        try await cattery.save(on: req.db)
        
        print("❕NOFIFICATION: admin with id \(userID) delete verify for cattery with id \(catteryID)")
                
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
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: user.documentPath != nil && !user.isCatteryWaitVerify ? .init() : nil,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                score: user.score
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
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: user.documentPath != nil && !user.isCatteryWaitVerify ? .init() : nil,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                score: user.score
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
            
            if let path = user.avatarPath {
                avatarData = try? await FileManager.get(req: req, with: path)
            }
            
            usersOutput.append(User.Output(
                id: user.id,
                name: user.name,
                avatarData: avatarData,
                documentData: user.documentPath != nil && !user.isCatteryWaitVerify ? .init() : nil,
                description: user.description,
                deals: [Deal.Output](),
                boughtDeals: [Deal.Output](),
                ads: [Ad.Output](),
                myOffers: [Offer.Output](),
                offers: [Offer.Output](),
                chatRooms: [ChatRoom.Output](),
                score: user.score
            ))
        }
        
        return usersOutput
    }
    
    private func someUser(req: Request) async throws -> User.Output {
        try req.auth.require(User.self)
        
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        var avatarData: Data?
        var deals = [Deal.Output]()
        var boughtDeals = [Deal.Output]()
        
        if let path = someUser.avatarPath {
            avatarData = try? await FileManager.get(req: req, with: path)
        }
        
        for deal in try await someUser.$deals.get(on: req.db) {
            guard let petType = try? await deal.$petType.get(on: req.db),
                  let petBreed = try? await deal.$petBreed.get(on: req.db),
                  let dealUser = try? await deal.$cattery.get(on: req.db) else { continue }
            
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            let dealBuyer = try? await deal.$buyer.get(on: req.db)
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
                    buyer: dealBuyer != nil ? .init(
                        id: dealBuyer?.id,
                        name: dealBuyer?.name ?? .init(),
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
            
            deals.append(Deal.Output(
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
                    to: someUser.basicCurrencyName,
                    amount: deal.price ?? .zero
                ).result) : nil,
                currencyName: someUser.basicCurrencyName,
                score: deal.score,
                cattery: .init(
                    id: dealUser.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
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
        
        for deal in (try? await someUser.$boughtDeals.get(on: req.db)) ?? .init() {
            guard let petType = try? await deal.$petType.get(on: req.db),
                  let petBreed = try? await deal.$petBreed.get(on: req.db),
                  let dealUser = try? await deal.$cattery.get(on: req.db),
                  let buyer = try? await deal.$buyer.get(on: req.db) else { continue }
            
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            var userDeals = [Deal.Output]()
            var dealUserAvatarData: Data?
            var dealBuyerAvatarData: Data?
            
            if let path = dealUser.avatarPath {
                dealUserAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = buyer.avatarPath {
                dealBuyerAvatarData = try? await FileManager.get(req: req, with: path)
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
                    buyer: .init(
                        id: buyer.id,
                        name: buyer.name,
                        avatarData: dealBuyerAvatarData,
                        deals: .init(),
                        boughtDeals: .init(),
                        ads: .init(),
                        myOffers: .init(),
                        offers: .init(),
                        chatRooms: .init(),
                        score: .zero
                    ),
                    offers: .init()
                ))
            }
            
            boughtDeals.append(Deal.Output(
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
                    to: someUser.basicCurrencyName,
                    amount: deal.price ?? .zero
                ).result) : nil,
                currencyName: someUser.basicCurrencyName,
                score: deal.score,
                cattery: .init(
                    id: dealUser.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
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
                buyer: .init(
                    id: buyer.id,
                    name: buyer.name,
                    deals: .init(),
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
                    score: .zero
                ),
                offers: .init()
            ))
        }
        
        return .init(
            id: someUser.id,
            name: someUser.name,
            avatarData: avatarData,
            documentData: someUser.documentPath != nil && !someUser.isCatteryWaitVerify ? .init() : nil,
            description: someUser.description,
            deals: deals,
            boughtDeals: boughtDeals,
            ads: .init(),
            myOffers: .init(),
            offers: .init(),
            chatRooms: .init(),
            score: someUser.score
        )
    }
    
    private func user(req: Request) async throws -> User.Output {
        let user = try req.auth.require(User.self)
        
        var avatarData: Data?
        var deals = [Deal.Output]()
        var boughtDeals = [Deal.Output]()
        
        if let path = user.avatarPath {
            avatarData = try? await FileManager.get(req: req, with: path)
        }
        
        for deal in try await user.$deals.get(on: req.db) {
            guard let petType = try? await deal.$petType.get(on: req.db),
                  let petBreed = try? await deal.$petBreed.get(on: req.db),
                  let dealUser = try? await deal.$cattery.get(on: req.db) else { continue }
            
            var photoDatas = [Data]()
            
            for photoPath in deal.photoPaths {
                if let data = try? await FileManager.get(req: req, with: photoPath) {
                    photoDatas.append(data)
                }
            }
            
            let dealBuyer = try? await deal.$buyer.get(on: req.db)
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
            
            deals.append(Deal.Output(
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
                cattery: .init(
                    id: user.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
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
                buyer: dealBuyer != nil ? .init(
                    id: dealBuyer?.id,
                    name: dealBuyer?.name ?? .init(),
                    deals: .init(),
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
                    score: .zero
                ) : nil,
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
            
            let petType = try await deal.$petType.get(on: req.db)
            let petBreed = try await deal.$petBreed.get(on: req.db)
            let dealUser = try await deal.$cattery.get(on: req.db)
            var userDeals = [Deal.Output]()
            var dealUserAvatarData: Data?
            var buyerUserAvatarData: Data?
            
            guard let buyer = try? await deal.$buyer.get(on: req.db) else {
                continue
            }
            
            if let path = dealUser.avatarPath {
                dealUserAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = buyer.avatarPath {
                buyerUserAvatarData = try? await FileManager.get(req: req, with: path)
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
                    buyer: .init(
                        id: buyer.id,
                        name: buyer.name,
                        avatarData: buyerUserAvatarData,
                        deals: .init(),
                        boughtDeals: .init(),
                        ads: .init(),
                        myOffers: .init(),
                        offers: .init(),
                        chatRooms: .init(),
                        score: .zero
                    ),
                    offers: .init()
                ))
            }
            
            boughtDeals.append(Deal.Output(
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
                cattery: .init(
                    id: user.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
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
                buyer: .init(
                    id: user.id,
                    name: user.name,
                    deals: .init(),
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
                    score: .zero
                ),
                offers: [Offer.Output]()
            ))
        }
        
        return .init(
            id: user.id,
            name: user.name,
            avatarData: avatarData,
            documentData: user.documentPath != nil && !user.isCatteryWaitVerify ? .init() : nil,
            description: user.description,
            deals: deals,
            boughtDeals: boughtDeals,
            ads: .init(),
            myOffers: .init(),
            offers: .init(),
            chatRooms: .init(),
            score: user.score,
            isCatteryWaitVerify: user.isCatteryWaitVerify
        )
    }
    
    private func someUserDeals(req: Request) async throws -> [Deal.Output] {
        try req.auth.require(User.self)
        
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        var deals = [Deal.Output]()
        
        for deal in try await someUser.$deals.get(on: req.db) {
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
            
            deals.append(Deal.Output(
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
                    to: someUser.basicCurrencyName,
                    amount: deal.price ?? .zero
                ).result) : nil,
                currencyName: someUser.basicCurrencyName,
                score: deal.score,
                cattery: .init(
                    id: dealUser.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
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
        
        return deals
    }
    
    private func someUserBoughtDeals(req: Request) async throws -> [Deal.Output] {
        try req.auth.require(User.self)
        
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        var boughtDeals = [Deal.Output]()
        
        for deal in try await someUser.$boughtDeals.get(on: req.db) {
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
            
            boughtDeals.append(.init(
                id: deal.id,
                title: deal.title,
                photoDatas: photoDatas,
                tags: deal.tags.split(separator: "#").map(String.init),
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
                    to: someUser.basicCurrencyName,
                    amount: deal.price ?? .zero
                ).result) : nil,
                currencyName: someUser.basicCurrencyName,
                score: deal.score,
                cattery: .init(
                    id: dealUser.id,
                    name: dealUser.name,
                    avatarData: dealUserAvatarData,
                    deals: userDeals,
                    boughtDeals: .init(),
                    ads: .init(),
                    myOffers: .init(),
                    offers: .init(),
                    chatRooms: .init(),
                    score: .zero
                ),
                country: deal.country,
                city: deal.city,
                description: deal.description,
                buyer: nil,
                offers: .init()
            ))
        }
        
        return boughtDeals
    }
    
    private func someUserAds(req: Request) async throws -> [Ad.Output] {
        let user = try req.auth.require(User.self)
        var ads = [Ad.Output]()
        
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
        guard user.id == someUser.id || user.isAdmin else { throw Abort(.badRequest) }
        
        for ad in try await someUser.$ads.get(on: req.db) {
            if let data = try? await FileManager.get(req: req, with: ad.contentPath) {
                ads.append(Ad.Output(
                    id: ad.id,
                    contentData: data,
                    custromerName: ad.custromerName,
                    link: ad.link,
                    cattery: User.Output(
                        id: someUser.id,
                        name: someUser.name,
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
        }
        
        return ads
    }
    
    private func myOffers(req: Request) async throws -> [Offer.Output] {
        let user = try req.auth.require(User.self)
        var myOffers = [Offer.Output]()
        
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
        guard user.id == someUser.id || user.isAdmin else { throw Abort(.badRequest) }
        
        for myOffer in try await someUser.$myOffers.get(on: req.db) {
            guard let deal = try? await myOffer.$deal.get(on: req.db),
                  let buyer = try? await myOffer.$buyer.get(on: req.db),
                  let cattery = try? await myOffer.$cattery.get(on: req.db) else { continue }
            
            var dealPhotoDatas = [Data]()
            var buyerAvatarData: Data?
            var catteryAvatarData: Data?
            
            if let path = buyer.avatarPath {
                buyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = cattery.avatarPath {
                catteryAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            for path in deal.photoPaths {
                guard let data = try? await FileManager.get(req: req, with: path) else { continue }
                
                dealPhotoDatas.append(data)
            }
            
            guard let petType = try? await deal.$petType.get(on: req.db), let petBreed = try? await deal.$petBreed.get(on: req.db) else { continue }
            
            myOffers.append(Offer.Output(
                id: myOffer.id,
                price: myOffer.price,
                currencyName: myOffer.currencyName,
                buyer: User.Output(
                    id: buyer.id,
                    name: buyer.name,
                    avatarData: buyerAvatarData,
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
                    photoDatas: dealPhotoDatas,
                    tags: deal.tags.split(separator: "#").map({ String($0) }),
                    isPremiumDeal: deal.isPremiumDeal,
                    isActive: deal.isActive,
                    viewsCount: deal.viewsCount,
                    mode: deal.mode,
                    petType: .init(
                        id: petType.id,
                        localizedNames: petType.localizedNames,
                        imageData: (try? await FileManager.get(req: req, with: petType.imagePath)) ?? .init(),
                        petBreeds: (try? await petType.$petBreeds.get(on: req.db)) ?? .init()
                    ),
                    petBreed: .init(id: petBreed.id, name: petBreed.name, petType: petType),
                    petClass: .get(deal.petClass) ?? .allClass,
                    isMale: deal.isMale,
                    birthDate: deal.birthDate,
                    color: deal.color,
                    price: deal.price != nil ? Double((try? await CurrencyConverter.convert(
                        req,
                        from: deal.currencyName,
                        to: someUser.basicCurrencyName,
                        amount: deal.price ?? .zero
                    ).result) ?? .zero) : nil,
                    currencyName: someUser.basicCurrencyName,
                    score: deal.score,
                    cattery: User.Output(
                        id: cattery.id,
                        name: cattery.name,
                        avatarData: catteryAvatarData,
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
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    id: cattery.id,
                    name: cattery.name,
                    avatarData: catteryAvatarData,
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
        
        return myOffers
    }
    
    private func offers(req: Request) async throws -> [Offer.Output] {
        let user = try req.auth.require(User.self)
        var offers = [Offer.Output]()
        
        guard let someUser = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
        guard user.id == someUser.id || user.isAdmin else { throw Abort(.badRequest) }
        
        for offer in try await someUser.$offers.get(on: req.db) {
            guard let deal = try? await offer.$deal.get(on: req.db),
                  let buyer = try? await offer.$buyer.get(on: req.db),
                  let cattery = try? await offer.$cattery.get(on: req.db) else { continue }
            
            var dealPhotoDatas = [Data]()
            var buyerAvatarData: Data?
            var catteryAvatarData: Data?
            
            if let path = buyer.avatarPath {
                buyerAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            if let path = cattery.avatarPath {
                catteryAvatarData = try? await FileManager.get(req: req, with: path)
            }
            
            for path in deal.photoPaths {
                guard let data = try? await FileManager.get(req: req, with: path) else { continue }
                
                dealPhotoDatas.append(data)
            }
            
            guard let petType = try? await deal.$petType.get(on: req.db), let petBreed = try? await deal.$petBreed.get(on: req.db) else { continue }
            
            offers.append(Offer.Output(
                id: offer.id,
                price: offer.price,
                currencyName: offer.currencyName,
                buyer: User.Output(
                    id: buyer.id,
                    name: buyer.name,
                    avatarData: buyerAvatarData,
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
                    photoDatas: dealPhotoDatas,
                    tags: deal.tags.split(separator: "#").map({ String($0) }),
                    isPremiumDeal: deal.isPremiumDeal,
                    isActive: deal.isActive,
                    viewsCount: deal.viewsCount,
                    mode: deal.mode,
                    petType: .init(
                        id: petType.id,
                        localizedNames: petType.localizedNames,
                        imageData: (try? await FileManager.get(req: req, with: petType.imagePath)) ?? .init(),
                        petBreeds: (try? await petType.$petBreeds.get(on: req.db)) ?? .init()
                    ),
                    petBreed: .init(id: petBreed.id, name: petBreed.name, petType: petType),
                    petClass: .get(deal.petClass) ?? .allClass,
                    isMale: deal.isMale,
                    birthDate: deal.birthDate,
                    color: deal.color,
                    price: deal.price != nil ? Double((try? await CurrencyConverter.convert(
                        req,
                        from: deal.currencyName,
                        to: someUser.basicCurrencyName,
                        amount: deal.price ?? .zero
                    ).result) ?? .zero) : nil,
                    currencyName: someUser.basicCurrencyName,
                    score: deal.score,
                    cattery: User.Output(
                        id: cattery.id,
                        name: cattery.name,
                        avatarData: catteryAvatarData,
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
                    offers: [Offer.Output]()
                ),
                cattery: User.Output(
                    id: cattery.id,
                    name: cattery.name,
                    avatarData: catteryAvatarData,
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
        
        return offers
    }
    
    private func chatRooms(req: Request) async throws -> [ChatRoom.Output] {
        let user = try req.auth.require(User.self)
        var chatRooms = [ChatRoom.Output]()
        
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
                            isViewed: message.isViewed,
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
                                score: .zero
                            ),
                            createdAt: ISO8601DateFormatter().date(from: message.$createdAt.timestamp ?? .init()),
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
                            score: .zero
                        ))
                    }
                }
                
                chatRooms.append(ChatRoom.Output(
                    id: chatRoomID,
                    users: users,
                    messages: messages
                ))
            }
        }
        
        return chatRooms
    }
    
    private func chatRoomsID(req: Request) async throws -> [String] {
        try req.auth.require(User.self).chatRoomsID
    }
    
    private func getSearchTitles(req: Request) async throws -> [SearchTitle.Output] {
        let user = try req.auth.require(User.self)
        
        return try await user.$searchTitles.get(on: req.db).map { [ user ] in
            SearchTitle.Output(id: $0.id, title: $0.title, user: user)
        }
    }
    
    private func subcription(req: Request) async throws -> Subscription.Output {
        guard let subscription = try await req.auth.require(User.self).$subscrtiption.get(on: req.db) else {
            throw Abort(.notFound)
        }
        
        return .init(
            id: subscription.id,
            titleSubscription: try await subscription.$titleSubscription.get(on: req.db),
            expirationDate: subscription.expirationDate,
            user: subscription.user,
            createdAt: subscription.createdAt
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        try User.Create.validate(content: req)
        
        let create = try req.content.decode(User.Create.self)
        
        try await User(
            email: create.email,
            passwordHash: Bcrypt.hash(create.password),
            isAdmin: (try? await User.query(on: req.db).count()) == .zero
        ).save(on: req.db)
        
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
            try! await FileManager.set(req: req, with: avatarPath, data: avatarData)

            oldUser.avatarPath = avatarPath
        }
        
        if let documentData = newUser.documentData,
           let documentPath = oldUser.documentPath != nil ? oldUser.documentPath : req.application.directory.publicDirectory.appending(UUID().uuidString) {
            try! await FileManager.set(req: req, with: documentPath, data: documentData)

            oldUser.documentPath = documentPath
        }
        
        oldUser.name = newUser.name
        oldUser.description = newUser.description
        oldUser.isCatteryWaitVerify = newUser.isCatteryWaitVerify
        oldUser.countryCode = newUser.countryCode
        oldUser.basicCurrencyName = newUser.basicCurrencyName.rawValue
        
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
        
        if let path = user.documentPath {
            try await FileManager.set(req: req, with: path, data: .init())
        }
        
        if let path = user.avatarPath {
            try await FileManager.set(req: req, with: path, data: .init())
        }
        
        return .ok
    }
    
    private func userWebSocket(req: Request, ws: WebSocket) async {
        guard let userID = try? req.auth.require(User.self).id else {
            Swift.print("❌ Error: not authorized.", separator: "\n")
            
            try? await ws.close()
            
            return
        }
        
        ws.onClose.whenSuccess {
            UserWebSocketManager.shared.removeUserWebSocket(id: userID.uuidString)
        }
        
        UserWebSocketManager.shared.addUserWebSocket(id: userID.uuidString, ws: ws)
    }
    
}
