//
//  CardListView.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import SwiftUI

struct CardListView: View {
    @StateObject private var viewModel = CardsViewModel()
    @State private var scannedCardNumber: String?
    @State private var selectedCard: Card?
    @State private var showDetailView = false
    @State private var cardToShow: Card?
    @State private var scannedCardNFCData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.cards.isEmpty {
                    emptyStateView
                } else {
                    Spacer()
                    cardCarouselView
                    Spacer()
                    buttonsView
                    Spacer()
                }
            }
            .navigationTitle("Card Wallet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingAddCardSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddCardSheet) {
                if let cardNumber = scannedCardNumber {
                    AddCardView(
                        viewModel: viewModel,
                        prefillCardNumber: cardNumber,
                        prefillNFCData: scannedCardNFCData
                    )
                    .onDisappear {
                        // Clear the scanned data after form closes
                        scannedCardNumber = nil
                        scannedCardNFCData = nil
                    }
                } else {
                    AddCardView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showDetailView) {
                if let card = cardToShow {
                    NavigationView {
                        CardDetailView(card: card, onDelete: { deletedCard in
                            // Find and delete the card
                            if let index = viewModel.cards.firstIndex(where: { $0.id == deletedCard.id }) {
                                viewModel.deleteCard(at: IndexSet([index]))
                            }
                            
                            // Close the detail view
                            showDetailView = false
                            cardToShow = nil
                        })
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showDetailView = false
                                    cardToShow = nil
                                }
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text("Card Wallet"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $viewModel.showingNFCActionAlert) {
                Alert(
                    title: Text(viewModel.nfcActionSuccessful ? "Success" : "Failed"),
                    message: Text(viewModel.nfcActionSuccessful ? "Card used successfully!" : "Failed to use card. Please try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay {
                if viewModel.isNFCInProgress {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Using NFC...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NFCCardScanned"))) { notification in
            if let userInfo = notification.userInfo,
               let number = userInfo["cardNumber"] as? String {
                self.scannedCardNumber = number
                // Store the NFC data as well
                if let data = userInfo["nfcData"] as? Data {
                    DispatchQueue.main.async {
                        // You may need to add a property to store this
                        self.scannedCardNFCData = data
                        viewModel.showingAddCardSheet = true
                    }
                } else {
                    DispatchQueue.main.async {
                        viewModel.showingAddCardSheet = true
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("No Cards Added")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first card to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.showingAddCardSheet = true
            }) {
                Text("Add Card")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cardCarouselView: some View {
        // Use ZStack to position elements with proper spacing
        VStack{
            // Card carousel
            TabView(selection: $viewModel.selectedCardIndex) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card)
                        .padding(.horizontal)
                        .tag(index)
                        .onTapGesture {
                            // Set to nil first to ensure onChange is triggered even for the same card
                            cardToShow = nil
                            // Use slight delay to ensure the nil value is processed first
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                cardToShow = card
                            }
                        }
                }
            }
            .onChange(of: cardToShow) {
                if cardToShow != nil {
                    DispatchQueue.main.async {
                        showDetailView = true
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default indicator
            .frame(height: 230) // Reduced height
            
            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.cards.count, id: \.self) { index in
                    Circle()
                        .fill(viewModel.selectedCardIndex == index ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 10) // Reduced top padding
    }
    
    private var buttonsView: some View {
        VStack(spacing: 15) {
            Button(action: {
                viewModel.showingAddCardSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Card")
                }
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.useSelectedCard()
            }) {
                HStack {
                    Image(systemName: "wave.3.right")
                    Text("Use Selected Card")
                }
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.selectedCardIndex != nil ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.selectedCardIndex == nil)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom)
    }
}
