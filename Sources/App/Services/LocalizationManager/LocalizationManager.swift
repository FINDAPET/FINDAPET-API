//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 21.05.2023.
//

import Foundation

final class LocalizationManager {
    
//    MARK: - Localized String
    typealias LocalizedString = String
    
    
//    MARK: - Properties
    static let main = LocalizationManager(dataSource: LocalizationManagerMainDataSource())
    
    private let dataSource: any LocalizationManagerDataSourceable
    
//    MARK: - Init
    init(dataSource: any LocalizationManagerDataSourceable) {
        self.dataSource = dataSource
    }
    
//    MARK: - Subscripts
    subscript(countryCode: CountryCode, localizationKey: LocalizationKey) -> LocalizedString? {
        self.get(countryCode, localizationKey)
    }
    
    subscript(countryCode: String, localizationKey: LocalizationKey) -> LocalizedString? {
        self.get(countryCode, localizationKey)
    }
    
//    MARK: - Get Funcs
    func get(_ countryCode: CountryCode, _ localizationKey: LocalizationKey) throws -> LocalizedString {
        guard let localizedString = self.dataSource.values[countryCode]?[localizationKey] else {
            throw LocalizationManagerError.notFound
        }
        
        return localizedString
    }
    
    func get(_ countryCode: String?, _ localizationKey: LocalizationKey) throws -> LocalizedString {
        guard let localizedString = self.dataSource.values[.get(countryCode ?? .init()) ?? .en]?[localizationKey] else {
            throw LocalizationManagerError.notFound
        }
        
        return localizedString
    }
    
    private func get(_ countryCode: CountryCode, _ localizationKey: LocalizationKey) -> LocalizedString? {
        self.dataSource.values[countryCode]?[localizationKey]
    }
    
    private func get(_ countryCode: String?, _ localizationKey: LocalizationKey) -> LocalizedString? {
        self.dataSource.values[.get(countryCode ?? .init()) ?? .en]?[localizationKey]
    }
    
}
