//
//  KeychainCardStorage.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import Foundation
import Security
import LocalAuthentication

class KeychainCardStorage: CardStorageService {
    private let serviceName = "com.cardwallet.cards"
    private let keychainKey = "savedCards"
    
    func saveCards(_ cards: [Card]) {
        let encoder = JSONEncoder()
        guard let encodedCards = try? encoder.encode(cards) else {
            return
        }
        
        // Delete any existing data first
        deleteKeychainItem()
        
        // Save the cards as a new keychain item
        saveToKeychain(data: encodedCards)
    }
    
    func loadCards() -> [Card] {
        guard let keychainData = readFromKeychain() else {
            return []
        }
        
        let decoder = JSONDecoder()
        guard let savedCards = try? decoder.decode([Card].self, from: keychainData) else {
            return []
        }
        
        return savedCards
    }
    
    func addCard(_ card: Card) {
        var cards = loadCards()
        cards.append(card)
        saveCards(cards)
    }
    
    func deleteCard(withId id: UUID) {
        var cards = loadCards()
        cards.removeAll { $0.id == id }
        saveCards(cards)
    }
    
    // MARK: - Keychain Helper Methods
    
    private func saveToKeychain(data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Add the item to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Error adding item to Keychain: \(status)")
        }
    }
    
    private func readFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            print("Error reading from Keychain: \(status)")
            return nil
        }
    }
    
    private func deleteKeychainItem() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keychainKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error deleting from Keychain: \(status)")
        }
    }
}
