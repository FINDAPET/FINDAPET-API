//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 22.10.2022.
//

import Foundation
import Vapor

final class Network {
    
//    MARK: - Request 1
    static func request<T: Decodable>(
        _ request: Request,
        url: URL,
        encodableModel: Encodable? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws -> T {
        switch method {
        case .GET:
            let response = try await request.client.get(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return try JSONDecoder().decode(T.self, from: .init(buffer: buffer))
        case .PUT:
            let response = try await request.client.put(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return try JSONDecoder().decode(T.self, from: .init(buffer: buffer))
        case .POST:
            let response = try await request.client.post(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return try JSONDecoder().decode(T.self, from: .init(buffer: buffer))
        case .DELETE:
            let response = try await request.client.delete(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return try JSONDecoder().decode(T.self, from: .init(buffer: buffer))
        }
    }
    
//    MARK: - Request 2
    static func request(
        _ request: Request,
        url: URL,
        encodableModel: Encodable? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws {
        switch method {
        case .GET:
            let response = try await request.client.get(
                .init(string: url.absoluteString),
                
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
        case .PUT:
            let response = try await request.client.put(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
        case .POST:
            let response = try await request.client.post(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
        case .DELETE:
            let response = try await request.client.delete(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
        }
    }
    
//    MARK: - Request 3
    static func request(
        _ request: Request,
        url: URL,
        encodableModel: Encodable? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws -> Data {
        switch method {
        case .GET:
            let response = try await request.client.get(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        case .PUT:
            let response = try await request.client.put(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        case .POST:
            let response = try await request.client.post(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        case .DELETE:
            let response = try await request.client.delete(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let encodableModel else {
                        return
                    }
                    
                    try clientReq.content.encode(encodableModel, using: JSONEncoder())
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        }
    }
        
//    MARK: - Request 4
    static func request(
        _ request: Request,
        url: URL,
        bodyData: Data? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws {
        switch method {
        case .GET:
            let response = try await request.client.get(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
        case .PUT:
            let response = try await request.client.put(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
        case .POST:
            let response = try await request.client.post(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
        case .DELETE:
            let response = try await request.client.delete(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
        }
    }
    
//    MARK: - Request 5
    static func request(
        _ request: Request,
        url: URL,
        bodyData: Data? = nil,
        authMode: HTTPAuthentaficationMode? = nil,
        method: HTTPMethods
    ) async throws -> Data {
        switch method {
        case .GET:
            let response = try await request.client.get(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        case .PUT:
            let response = try await request.client.put(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        case .POST:
            let response = try await request.client.post(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        case .DELETE:
            let response = try await request.client.delete(
                .init(string: url.absoluteString),
                beforeSend: { clientReq in
                    if let authMode {
                        switch authMode {
                        case .base(email: let email, password: let password):
                            clientReq.headers.basicAuthorization = .init(username: email, password: password)
                        case .bearer(value: let value):
                            clientReq.headers.bearerAuthorization = .init(token: value)
                        }
                    }
                    
                    guard let bodyData else {
                        return
                    }
                    
                    try clientReq.content.encode(bodyData, as: .formData)
                }
            )
            
            guard response.status.code == 200 else {
                throw Abort(.badRequest)
            }
            
            guard let buffer = response.body else {
                throw Abort(.notFound)
            }
            
            return .init(buffer: buffer)
        }
    }
    
}
