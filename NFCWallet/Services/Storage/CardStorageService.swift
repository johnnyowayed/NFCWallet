//
//  CardStorageService.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import Foundation

protocol CardStorageService {
    func saveCards(_ cards: [Card])
    func loadCards() -> [Card]
    func addCard(_ card: Card)
    func deleteCard(withId id: UUID)
}
