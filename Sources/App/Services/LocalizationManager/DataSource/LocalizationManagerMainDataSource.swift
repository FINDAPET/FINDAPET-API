//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 21.05.2023.
//

import Foundation

struct LocalizationManagerMainDataSource: LocalizationManagerDataSourceable {
    private(set) var values: [CountryCode : [LocalizationKey : LocalizedString]] = [
        .en : [
            .sentYouANewMessage : "Sent you a new message",
            .youBoughtAPet : "You bought a pet",
            .yourOfferIsRejected : "Your offer is rejected",
            .youHaveANewOffer : "You have a new offer",
            .yourCatteryIsConfirmed : "Your cattery is confirmed"
        ],
        .ru : [
            .sentYouANewMessage : "Отправил вам новое сообщение",
            .youBoughtAPet : "Вы купили животное",
            .yourOfferIsRejected : "Ваше предложение о покупке отклоненно",
            .youHaveANewOffer : "Вы получили новое предложение о покупке",
            .yourCatteryIsConfirmed : "Ваш питомник подтвержден"
        ]
    ]
}
