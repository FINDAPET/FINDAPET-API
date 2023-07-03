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
    
    @Field(key: "country_codes")
    var countryCodes: String
    
    @Field(key: "background_image_path")
    var backgroundImagePath: String
    
    @OptionalField(key: "title")
    var title: String?
    
    @OptionalField(key: "text")
    var text: String?
    
    @Field(key: "button_title")
    var buttonTitle: String
    
    @OptionalField(key: "text_color_hex")
    var textColorHEX: String?
    
    @Field(key: "button_title_color_hex")
    var buttonTitleColorHEX: String
    
    @Field(key: "button_color_hex")
    var buttonColorHEX: String
    
    @Field(key: "is_required")
    var isRequired: Bool
    
    @OptionalField(key: "web_view_url")
    var webViewURL: String?
    
    init() { }
    
    init(
        id: UUID? = nil,
        countryCodes: String,
        backgroundImagePath: String,
        title: String? = nil,
        text: String? = nil,
        buttonTitle: String,
        textColorHEX: String? = nil,
        buttonTitleColorHEX: String,
        buttonColorHEX: String,
        webViewURL: String? = nil,
        isRequired: Bool = false
    ) {
        self.id = id
        self.countryCodes = countryCodes
        self.backgroundImagePath = backgroundImagePath
        self.title = title
        self.text = text
        self.buttonTitle = buttonTitle
        self.textColorHEX = textColorHEX
        self.buttonTitleColorHEX = buttonTitleColorHEX
        self.buttonColorHEX = buttonColorHEX
        self.webViewURL = webViewURL
        self.isRequired = isRequired
    }
    
}

extension NotificationScreen {
    struct Input: Content {
        
        var id: UUID?
        var countryCodes: [String]
        var backgroundImageData: Data
        var title: String?
        var text: String?
        var buttonTitle: String
        var textColorHEX: String?
        var buttonTitleColorHEX: String
        var buttonColorHEX: String
        var webViewURL: String?
        var isRequired: Bool
        
        init(id: UUID? = nil,
             countryCodes: [String],
             backgroundImageData: Data,
             title: String? = nil,
             text: String? = nil,
             buttonTitle: String,
             textColorHEX: String? = nil,
             buttonTitleColorHEX: String,
             buttonColorHEX: String,
             webViewURL: String? = nil,
             isRequired: Bool = false
        ) {
            self.id = id
            self.countryCodes = countryCodes
            self.backgroundImageData = backgroundImageData
            self.title = title
            self.text = text
            self.buttonTitle = buttonTitle
            self.textColorHEX = textColorHEX
            self.buttonTitleColorHEX = buttonTitleColorHEX
            self.buttonColorHEX = buttonColorHEX
            self.webViewURL = webViewURL

            self.isRequired = isRequired
        }
        
    }
}

extension NotificationScreen {
    struct Output: Content {
        var id: UUID?
        var backgroundImageData: Data
        var title: String?
        var text: String?
        var buttonTitle: String
        var textColorHEX: String?
        var buttonTitleColorHEX: String
        var buttonColorHEX: String
        var webViewURL: String?
        var isRequired: Bool
    }
}

extension NotificationScreen: Equatable {
    static func == (lhs: NotificationScreen, rhs: NotificationScreen) -> Bool {
        lhs.id == rhs.id
    }
}
