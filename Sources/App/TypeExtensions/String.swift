//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 14.03.2023.
//

import Foundation

extension String {
    init(_ str: StaticString) {
        self = str.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
    }
}
