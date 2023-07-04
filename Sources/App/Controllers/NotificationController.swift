//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 06.10.2022.
//

import Foundation
import Vapor

struct NotificationController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let notificatons = routes.grouped("notification")
        let userTokenProtected = notificatons.grouped(UserToken.authenticator())
        
        userTokenProtected.post("new", use: self.create(req:))
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let notification = try req.content.decode(Notification.self)
        
        if !notification.coutryCodes.isEmpty {
            for countryCode in notification.coutryCodes {
                for user in try await User.query(on: req.db).all().filter({ $0.countryCode == countryCode }) {
                    for deviceToken in (try? await user.$deviceTokens.get(on: req.db)) ?? .init() {
                        switch Platform.get(deviceToken.platform) {
                        case .iOS:
                            req.apns.send(.init(title: notification.title), to: deviceToken.value).whenComplete {
                                switch $0 {
                                case .success():
                                    print("❕NOTIFICATION: push notification is sent.")
                                case .failure(let error):
                                    print("❌ ERROR: \(error.localizedDescription)")
                                }
                            }
                        case .Android:
//                            full version
                            continue
                        case .custom(_):
//                            full version
                            continue
                        }
                    }
                }
            }
        } else {
            for user in try await User.query(on: req.db).all() {
                for deviceToken in (try? await user.$deviceTokens.get(on: req.db)) ?? .init() {
                    switch Platform.get(deviceToken.platform) {
                    case .iOS:
                        req.apns.send(.init(title: notification.title), to: deviceToken.value).whenComplete {
                            switch $0 {
                            case .success():
                                print("❕NOTIFICATION: push notification is sent.")
                            case .failure(let error):
                                print("❌ ERROR: \(error.localizedDescription)")
                            }
                        }
                    case .Android:
//                        full version
                        continue
                    case .custom(_):
//                        full version
                        continue
                    }
                }
            }
        }
        
        return .ok
    }
    
    private func sendToUser(req: Request) async throws -> HTTPStatus {
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        let notification = try req.content.decode(Notification.self)
        
        for userID in notification.usersID {
            for deviceToken in (try? await User.find(userID, on: req.db)?.$deviceTokens.get(on: req.db)) ?? .init() {
                switch Platform.get(deviceToken.platform) {
                case .iOS:
                    req.apns.send(.init(title: notification.title), to: deviceToken.value).whenComplete {
                        switch $0 {
                        case .success():
                            print("❕NOTIFICATION: push notification is sent.")
                        case .failure(let error):
                            print("❌ ERROR: \(error.localizedDescription)")
                        }
                    }
                case .Android:
//                    full version
                    continue
                case .custom(_):
//                    full version
                    continue
                }
            }
        }
        
        return .ok
    }
    
}
