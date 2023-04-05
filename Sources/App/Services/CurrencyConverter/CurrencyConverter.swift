//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 23.10.2022.
//

import Foundation
import Vapor

final class CurrencyConverter {
    
//    MARK: Convert 1
    static func convert(_ req: Request, from first: String, to second: String, amount: Double) async throws -> ExchangeConvert.Output {
        try await Network.request(
            req,
            url: URLConstructor.exchange.convert(.init(from: first, to: second, amount: amount)),
            method: .GET
        )
    }
    
//    MARK: Convert 2
    static func convert(_ req: Request, _ model: ExchangeConvert.Input) async throws -> ExchangeConvert.Output {
        try await Network.request(
            req,
            url: URLConstructor.exchange.convert(model),
            encodableModel: model,
            method: .GET
        )
    }
    
}
