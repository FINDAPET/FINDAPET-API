//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 04.12.2022.
//

import Foundation
import Vapor
import Fluent

final class NotificationScreen: Model, Content {
    
    static let schema = "notification_screens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "country_code")
    var countryCode: String
    
    @Field(key: "background_image_path")
    var backgroundImagePath: String
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "text")
    var text: String
    
    @Field(key: "button_title")
    var buttonTitle: String
    
    @Field(key: "text_color_hex")
    var textColorHEX: String
    
    @Field(key: "button_title_color_hex")
    var buttonTitleColorHEX: String
    
    @Field(key: "button_color_hex")
    var buttonColorHEX: String
    
    init() { }
    
    init(
        id: UUID? = nil,
        countryCode: String,
        backgroundImagePath: String,
        title: String,
        text: String,
        buttonTitle: String,
        textColorHEX: String,
        buttonTitleColorHEX: String,
        buttonColorHEX: String
    ) {
        self.id = id
        self.countryCode = countryCode
        self.backgroundImagePath = backgroundImagePath
        self.title = title
        self.text = text
        self.buttonTitle = buttonTitle
        self.textColorHEX = textColorHEX
        self.buttonTitleColorHEX = buttonTitleColorHEX
        self.buttonColorHEX = buttonColorHEX
    }
    
}

extension NotificationScreen {
    struct Input: Content {
        var id: UUID?
        var countryCode: String
        var backgroundImageData: Data
        var title: String
        var text: String
        var buttonTitle: String
        var textColorHEX: String
        var buttonTitleColorHEX: String
        var buttonColorHEX: String
    }
}

extension NotificationScreen {
    struct Output: Content {
        var id: UUID?
        var backgroundImageData: Data
        var title: String
        var text: String
        var buttonTitle: String
        var textColorHEX: String
        var buttonTitleColorHEX: String
        var buttonColorHEX: String
    }
}

extension NotificationScreen: Equatable {
    static func == (lhs: NotificationScreen, rhs: NotificationScreen) -> Bool {
        lhs.id == rhs.id
    }
}
