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
    
    @OptionalField(key: "background_image_path")
    var backgroundImagePath: String?
    
    @OptionalField(key: "title")
    var title: String?
    
    @OptionalField(key: "text")
    var text: String?
    
    @OptionalField(key: "button_title")
    var buttonTitle: String?
    
    @OptionalField(key: "text_color_hex")
    var textColorHEX: String?
    
    @OptionalField(key: "button_title_color_hex")
    var buttonTitleColorHEX: String?
    
    @OptionalField(key: "button_color_hex")
    var buttonColorHEX: String?
    
    init() { }
    
    init(
        id: UUID? = nil,
        backgroundImagePath: String? = nil,
        title: String? = nil,
        text: String? = nil,
        buttonTitle: String? = nil,
        textColorHEX: String? = nil,
        buttonTitleColorHEX: String? = nil,
        buttonColorHEX: String? = nil
    ) {
        self.id = id
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
        var backgroundImageData: Data?
        var title: String?
        var text: String?
        var buttonTitle: String?
        var textColorHEX: String?
        var buttonTitleColorHEX: String?
        var buttonColorHEX: String?
    }
}

extension NotificationScreen {
    struct Output: Content {
        var id: UUID?
        var backgroundImageData: Data?
        var title: String?
        var text: String?
        var buttonTitle: String?
        var textColorHEX: String?
        var buttonTitleColorHEX: String?
        var buttonColorHEX: String?
    }
}

extension NotificationScreen: Equatable {
    static func == (lhs: NotificationScreen, rhs: NotificationScreen) -> Bool {
        lhs.id == rhs.id
    }
}
