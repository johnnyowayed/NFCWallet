//
//  CardsViewModel.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import Combine
import Foundation

class CardsViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var selectedCardIndex: Int?
    @Published var showingAddCardSheet = false
    @Published var showingCardScannerSheet = false
    @Published var showingNFCActionAlert = false
    @Published var nfcActionSuccessful = false
    @Published var isNFCInProgress = false
    @Published var alertMessage = ""
    @Published var showingAlert = false
    
    private let cardStorage: CardStorageService
    private var cancellables = Set<AnyCancellable>()
    
    init(cardStorage: CardStorageService = KeychainCardStorage()) {
        self.cardStorage = cardStorage
        loadCards()
        
        // Subscribe to NFC scanning status changes
        NFCManager.shared.$isScanning
            .assign(to: \.isNFCInProgress, on: self)
            .store(in: &cancellables)
    }
    
    func loadCards() {
        cards = cardStorage.loadCards()
        if cards.isEmpty {
            selectedCardIndex = nil
        } else if selectedCardIndex == nil {
            selectedCardIndex = 0
        }
    }
    
    func addCard(_ card: Card) {
        cardStorage.addCard(card)
        loadCards()
    }
    
    func deleteCard(at indexSet: IndexSet) {
        for index in indexSet {
            let cardId = cards[index].id
            cardStorage.deleteCard(withId: cardId)
        }
        loadCards()
    }
    
    // This allows deleting a card by its UUID
    func deleteCard(withId id: UUID) {
        cardStorage.deleteCard(withId: id)
        loadCards()
    }
    
    func useSelectedCard() {
        guard let index = selectedCardIndex, index < cards.count else {
            alertMessage = "No card selected"
            showingAlert = true
            return
        }
        
        let selectedCard = cards[index]
        isNFCInProgress = true
        
        NFCManager.shared.simulateNFCTap(with: selectedCard) { [weak self] success in
            DispatchQueue.main.async {
                self?.isNFCInProgress = false
                self?.nfcActionSuccessful = success
                self?.showingNFCActionAlert = true
            }
        }
    }
}
