//
//  AddCardView.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import SwiftUI

struct AddCardView: View {
    @ObservedObject var viewModel: CardsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var cardName = ""
    @State private var cardNumber = ""
    @State private var selectedCardType = CardType.accessCard
    @State private var capturedNFCData: Data?
    @State private var isCapturingNFC = false
    @State private var hasNFCData = false
    
    var prefillCardNumber: String?
    var prefillNFCData: Data?
    
    init(viewModel: CardsViewModel, prefillCardNumber: String? = nil, prefillNFCData: Data? = nil) {
        self.viewModel = viewModel
        self.prefillCardNumber = prefillCardNumber
        self.prefillNFCData = prefillNFCData
        
        // Initialize the state with prefilled data if available
        if let number = prefillCardNumber {
            _cardNumber = State(initialValue: number)
        } else {
            _cardNumber = State(initialValue: "")
        }
        
        if let nfcData = prefillNFCData {
            _capturedNFCData = State(initialValue: nfcData)
            _hasNFCData = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Details")) {
                    TextField("Card Name", text: $cardName)
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .onAppear {
                            // If we have a prefilled number but no name, suggest a name
                            if !cardNumber.isEmpty && cardName.isEmpty {
                                cardName = "Card \(viewModel.cards.count + 1)"
                            }
                        }
                }
                
                Section(header: Text("Card Type")) {
                    Picker("Card Type", selection: $selectedCardType) {
                        ForEach(CardType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section {
                    Button(action: captureNFC) {
                        HStack {
                            Text(hasNFCData ? "NFC Data Captured ✓" : "Capture NFC Data (Optional)")
                            Spacer()
                            if isCapturingNFC {
                                ProgressView()
                            }
                        }
                    }
                    .foregroundColor(hasNFCData ? .green : .blue)
                    .disabled(selectedCardType == .paymentCard)
                }
                
                if selectedCardType == .paymentCard {
                    Section {
                        Text("Payment cards cannot be read with NFC due to Apple restrictions.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                    .disabled(cardName.isEmpty || cardNumber.isEmpty)
                }
            }
        }
    }
    
    private func captureNFC() {
        // Check if we're trying to read a payment card
        if selectedCardType == .paymentCard {
            NFCManager.shared.showAlert(
                title: "Cannot Read Payment Cards",
                message: "Apple restricts iOS apps from reading payment or bank cards. This is a security limitation set by Apple to protect payment information. Please add your payment card information manually."
            )
            return
        }
        
        isCapturingNFC = true
        
        NFCManager.shared.beginScan(for: selectedCardType) { result in
            DispatchQueue.main.async {
                self.isCapturingNFC = false
                
                switch result {
                case .success(let data):
                    self.capturedNFCData = data
                    self.hasNFCData = true
                    
                    if let number = NFCManager.shared.lastScannedNumber, !number.isEmpty {
                        self.cardNumber = number
                    }
                    
                case .failure(let error):
                    NFCManager.shared.showAlert(
                        title: "NFC Error",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func saveCard() {
        let newCard = Card(
            name: cardName,
            number: cardNumber,
            cardType: selectedCardType,
            nfcData: capturedNFCData
        )
        
        viewModel.addCard(newCard)
        presentationMode.wrappedValue.dismiss()
    }
}
