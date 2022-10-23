//
//  Exchange.swift
//  FINDAPET-App
//
//  Created by Artemiy Zuzin on 14.10.2022.
//

import Foundation

struct ExchangeConvert {
    struct Input: Encodable {
        var from: String?
        var to: String?
        var amount: Double?
    }
    
    struct Output: Decodable {
        var result: Float
    }
}
