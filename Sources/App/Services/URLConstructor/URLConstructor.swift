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
    func convert() -> URL {
        self.baseURL
            .appendingPathComponent(Paths.convert.rawValue)
    }
    
}
