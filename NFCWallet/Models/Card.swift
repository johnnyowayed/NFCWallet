//
//  Card.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import Foundation

struct Card: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let number: String
    let cardType: CardType
    let expiryDate: Date?
    let nfcData: Data?
    
    init(id: UUID = UUID(), name: String, number: String, cardType: CardType, expiryDate: Date? = nil, nfcData: Data? = nil) {
        self.id = id
        self.name = name
        self.number = number
        self.cardType = cardType
        self.expiryDate = expiryDate
        self.nfcData = nfcData
    }
}
