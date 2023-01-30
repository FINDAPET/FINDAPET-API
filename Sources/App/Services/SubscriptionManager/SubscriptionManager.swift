//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 22.01.2023.
//

import Foundation
import Fluent
import Vapor
import APNS

final class SubscriptionManager {
    
//    MARK: - Country Code
    ///example: RU, US ...
    typealias CountryCode = String
    
//    MARK: Init
    private init() { }
    
//    MARK: - Shared
    static let shared = SubscriptionManager()
    
//    MARK: Start
    func start(_ app: Application) {
        self.addTimer(self.createManagerTimer(app))
    }
    
//    MARK: - Get Subscription
    func getSubscription(_ app: Application, with option: SubscriptionOption? = nil) async throws -> [Subscription] {
        switch option {
        case .expired:
            return try await Subscription.query(on: app.db).filter(\.$expirationDate >= .init()).all()
        case .nextDayExpiration:
            let date = Date().addingTimeInterval(.init(86_400))
            
            return try await Subscription.query(on: app.db)
                .filter(\.$expirationDate > .init())
                .filter(\.$expirationDate <= date)
                .all()
        default:
            return try await Subscription.query(on: app.db).all()
        }
    }
    
//    MARK: - Delete
    func delete(_ app: Application, subscription sub: Subscription) async throws {
        try await sub.delete(on: app.db)
    }
    
//    MARK: - Send Notification
    func sendNotification(
        _ app: Application,
        subscription sub: Subscription,
        localizedMessages: [CountryCode : String]
    ) async throws {
        let user = try await sub.$user.get(on: app.db)
        
        guard let deviceToken = user.deviceToken else {
            throw Abort(.notFound)
        }
        
        let message = localizedMessages[user.countryCode ?? "US"]
        
        try app.apns.send(.init(title: message), to: deviceToken).wait()
    }
    
//    MARK: Delte Expired Subscriptions
    func deleteExpiredSubscriprions(_ app: Application, isThrowEnable: Bool = false) async throws {
        for sub in try await self.getSubscription(app, with: .expired) {
            if isThrowEnable {
                try await self.delete(app, subscription: sub)
            } else {
                try? await self.delete(app, subscription: sub)
            }
        }
    }
    
//    MARK: Send Notification Subscriptions
    func sendNotificationSubscriptions(
        _ app: Application,
        localizedMessages: [CountryCode : String],
        isThrowEnable: Bool = false
    ) async throws {
        for sub in try await self.getSubscription(app, with: .nextDayExpiration) {
            if isThrowEnable {
                try await self.sendNotification(app, subscription: sub, localizedMessages: localizedMessages)
            } else {
                try? await self.sendNotification(app, subscription: sub, localizedMessages: localizedMessages)
            }
        }
    }
    
//    MARK: Manage
    func manage(_ app: Application, isThrowEnable: Bool = false) async throws {
        if isThrowEnable {
            try await self.deleteExpiredSubscriprions(app)
            try await self.sendNotificationSubscriptions(
                app,
                localizedMessages: [
                    "RU" : "Ваша подписка истечет завтра",
                    "US" : "Your subscription will expire tomorrow"
                ]
            )
        } else {
            try? await self.deleteExpiredSubscriprions(app)
            try? await self.sendNotificationSubscriptions(
                app,
                localizedMessages: [
                    "RU" : "Ваша подписка истечет завтра",
                    "US" : "Your subscription will expire tomorrow"
                ]
            )
        }
    }
    
//    MARK: Create Manage Timer
    func createManagerTimer(_ app: Application) -> Timer {
        .scheduledTimer(withTimeInterval: .init(86400), repeats: true) { _ in
            Task { [ weak self, weak app ] in
                if let app = app {
                    try? await self?.manage(app)
                }
            }
        }
    }
    
//    MARK: Add Timer
    func addTimer(_ timer: Timer) {
        RunLoop.current.add(timer, forMode: .common)
    }
    
}
