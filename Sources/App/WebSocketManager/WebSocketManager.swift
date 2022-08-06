//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.08.2022.
//

import Foundation
import WebSocketKit

final class WebSocketManager {
    
    private(set) var catteryWebSockets: [CatteryWebSocket]
    private(set) var offerWebSockets: [OfferWebSocket]
    
    init() {
        self.catteryWebSockets = [CatteryWebSocket]()
        self.offerWebSockets = [OfferWebSocket]()
    }
    
    static let shared = WebSocketManager()
    
    func addCatteryWebSocket(cattery: User, webSocket: WebSocket) {
        guard cattery.isCatteryWaitVerify else {
            print("❌ Error: illegal.")
            
            return
        }
        
        self.catteryWebSockets.append(CatteryWebSocket(cattery: cattery, webSocket: webSocket))
    }
    
    func addOfferWebSocket(offer: Offer, webSocket: WebSocket) {
        self.offerWebSockets.append(OfferWebSocket(offer: offer, webSocket: webSocket))
    }
    
    func removeCatteryWebSocket(cattery: User) {
        guard !cattery.isCatteryWaitVerify || cattery.isActiveCattery else {
            return
        }
        
        for i in 0 ..< self.catteryWebSockets.count {
            if self.catteryWebSockets[i].cattery.id == cattery.id {
                self.catteryWebSockets[i].webSocket.close().whenSuccess { self.catteryWebSockets.remove(at: i) }
                
                break
            }
        }
    }
    
    func removeOfferWebSocket(offer: Offer) {
        for i in 0 ..< self.offerWebSockets.count {
            if self.offerWebSockets[i].offer.id == offer.id {
                self.offerWebSockets[i].webSocket.close().whenSuccess { self.offerWebSockets.remove(at: i) }
                
                break
            }
        }
    }
    
    func sendMessageCatteryWebSocket(cattery: User, message: String) {
        guard cattery.isActiveCattery else {
            print("❌ Error: illegal.")
            
            return
        }
        
        for i in 0 ..< self.catteryWebSockets.count {
            if self.catteryWebSockets[i].cattery.id == cattery.id {
                self.catteryWebSockets[i].webSocket.send(message)
                self.removeCatteryWebSocket(cattery: cattery)
                
                break
            }
        }
    }
    
    func sendMessageOfferWeSocket(offer: Offer, message: String) {
        for i in 0 ..< self.offerWebSockets.count {
            if self.offerWebSockets[i].offer.id == offer.id {
                self.offerWebSockets[i].webSocket.send(message)
                self.removeOfferWebSocket(offer: offer)
                
                break
            }
        }
    }
    
}
