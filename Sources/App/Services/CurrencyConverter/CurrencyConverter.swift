//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 23.10.2022.
//

import Foundation

final class CurrencyConverter {
    
//    MARK: Convert 1
    static func convert(from first: String, to second: String, amount: Double) async throws -> ExchangeConvert.Output {
        try await Network.request(
            url: URLConstructor.exchange.convert(),
            encodableModel: ExchangeConvert.Input(from: first, to: second, amount: amount),
            method: .GET
        )
    }
    
//    MARK: Convert 2
    static func convert(_ model: ExchangeConvert.Input) async throws -> ExchangeConvert.Output {
        try await Network.request(url: URLConstructor.exchange.convert(), encodableModel: model, method: .GET)
    }
    
}
