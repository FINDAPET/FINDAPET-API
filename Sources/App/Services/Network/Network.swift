//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 22.10.2022.
//

import Foundation
import Vapor

final class Network {
    
//    MARK: Request 1
    static func request<T: Decodable>(
        url: URL,
        encodableModel: Encodable? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws -> T {
        var req = URLRequest(url: url)
        
        req.httpMethod = method.rawValue
        req.setValue(Headers.applicationJson.rawValue, forHTTPHeaderField: Headers.contentType.rawValue)
        
        if let encodableModel = encodableModel {
            req.httpBody = try? JSONEncoder().encode(encodableModel)
        }
        
        if let authMode = authMode {
            switch authMode {
            case .base(email: let email, password: let password):
                req.setValue(
                    Headers.authorization.rawValue,
                    forHTTPHeaderField: Headers.authString(email: email, password: password) ?? ""
                )
            case .bearer(value: let value):
                req.setValue(Headers.authorization.rawValue, forHTTPHeaderField: Headers.bearerAuthString(token: value))
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        if let httpURLResponse = response as? HTTPURLResponse {
            guard httpURLResponse.statusCode == 200 else {
                throw Abort(.badRequest)
            }
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
//    MARK: Request 2
    static func request(
        url: URL,
        encodableModel: Encodable? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws {
        var req = URLRequest(url: url)
        
        req.httpMethod = method.rawValue
        req.setValue(Headers.applicationJson.rawValue, forHTTPHeaderField: Headers.contentType.rawValue)
        
        if let encodableModel = encodableModel {
            req.httpBody = try? JSONEncoder().encode(encodableModel)
        }
        
        if let authMode = authMode {
            switch authMode {
            case .base(email: let email, password: let password):
                req.setValue(
                    Headers.authorization.rawValue,
                    forHTTPHeaderField: Headers.authString(email: email, password: password) ?? ""
                )
            case .bearer(value: let value):
                req.setValue(Headers.authorization.rawValue, forHTTPHeaderField: Headers.bearerAuthString(token: value))
            }
        }
        
        let (_, response) = try await URLSession.shared.data(for: req)
        
        if let httpURLResponse = response as? HTTPURLResponse {
            guard httpURLResponse.statusCode == 200 else {
                throw Abort(.badRequest)
            }
        }
    }
    
//    MARK: Request 3
    static func request(
        url: URL,
        encodableModel: Encodable? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws -> Data {
        var req = URLRequest(url: url)
        
        req.httpMethod = method.rawValue
        req.setValue(Headers.applicationJson.rawValue, forHTTPHeaderField: Headers.contentType.rawValue)
        
        if let encodableModel = encodableModel {
            req.httpBody = try? JSONEncoder().encode(encodableModel)
        }
        
        if let authMode = authMode {
            switch authMode {
            case .base(email: let email, password: let password):
                req.setValue(
                    Headers.authorization.rawValue,
                    forHTTPHeaderField: Headers.authString(email: email, password: password) ?? ""
                )
            case .bearer(value: let value):
                req.setValue(Headers.authorization.rawValue, forHTTPHeaderField: Headers.bearerAuthString(token: value))
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        if let httpURLResponse = response as? HTTPURLResponse {
            guard httpURLResponse.statusCode == 200 else {
                throw Abort(.badRequest)
            }
        }
        
        return data
    }
        
//    MARK: Request 4
    static func request(
        url: URL,
        bodyData: Data? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws {
        var req = URLRequest(url: url)
        
        req.httpMethod = method.rawValue
        req.setValue(Headers.applicationJson.rawValue, forHTTPHeaderField: Headers.contentType.rawValue)
        req.httpBody = bodyData
        
        if let authMode = authMode {
            switch authMode {
            case .base(email: let email, password: let password):
                req.setValue(
                    Headers.authorization.rawValue,
                    forHTTPHeaderField: Headers.authString(email: email, password: password) ?? ""
                )
            case .bearer(value: let value):
                req.setValue(Headers.authorization.rawValue, forHTTPHeaderField: Headers.bearerAuthString(token: value))
            }
        }
        
        let (_, response) = try await URLSession.shared.data(for: req)
        
        if let httpURLResponse = response as? HTTPURLResponse {
            guard httpURLResponse.statusCode == 200 else {
                throw Abort(.badRequest)
            }
        }
    }
    
//    MARK: Request 5
    static func request(
        url: URL,
        bodyData: Data? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws -> Data {
        var req = URLRequest(url: url)
        
        req.httpMethod = method.rawValue
        req.setValue(Headers.applicationJson.rawValue, forHTTPHeaderField: Headers.contentType.rawValue)
        req.httpBody = bodyData
        
        if let authMode = authMode {
            switch authMode {
            case .base(email: let email, password: let password):
                req.setValue(
                    Headers.authorization.rawValue,
                    forHTTPHeaderField: Headers.authString(email: email, password: password) ?? ""
                )
            case .bearer(value: let value):
                req.setValue(Headers.authorization.rawValue, forHTTPHeaderField: Headers.bearerAuthString(token: value))
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        if let httpURLResponse = response as? HTTPURLResponse {
            guard httpURLResponse.statusCode == 200 else {
                throw Abort(.badRequest)
            }
        }
        
        return data
    }
    
}
