//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 23.10.2022.
//

import Foundation

final class URLConstructor {
    
    private let baseURL: URL
    
    init(scheme: Schemes, host: Hosts, port: Ports? = nil) {
        var urlComponents = URLComponents()
        
        urlComponents.host = host.rawValue
        urlComponents.port = port?.rawValue
        urlComponents.scheme = scheme.rawValue
        
        self.baseURL = urlComponents.url ?? URL(fileURLWithPath: "")
    }
    
    static let exchange = URLConstructor(scheme: .http, host: .exchange)
    
//    MARK: Exchange
    func convert(_ model: ExchangeConvert.Input) -> URL {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(Paths.convert.rawValue).absoluteString)
        
        components?.queryItems = [
            .init(name: "from", value: model.from),
            .init(name: "to", value: model.to),
            .init(name: "amount", value: .init(model.amount ?? 1))
        ]
                        
        return components?.url ?? self.baseURL.appendingPathComponent(Paths.convert.rawValue)
    }
    
}
