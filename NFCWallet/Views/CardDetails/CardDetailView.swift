//
//  CardDetailView.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import SwiftUI

struct CardDetailView: View {
    let card: Card
    @State private var showDeleteAlert = false
    var onDelete: ((Card) -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Card display at the top
                CardView(card: card)
                    .frame(height: 200)
                    .padding(.horizontal)
                
                // NFC Data Section
                if let nfcData = card.nfcData {
                    nfcDataSection(data: nfcData)
                        .padding(.horizontal)
                }
                
                // Card Info Section
                cardInfoSection
                    .padding(.horizontal)
                
                // Delete Section
                deleteSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Card"),
                message: Text("Are you sure you want to delete this card? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let onDelete = onDelete {
                        onDelete(card)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func nfcDataSection(data: Data) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NFC Data")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Format the raw data as hex
            Text("Raw Data (Hex):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(data.map { String(format: "%02X", $0) }.joined(separator: " "))
                .font(.system(.footnote, design: .monospaced))
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(5)
            
            // Data size
            HStack {
                Text("Data Size:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(data.count) bytes")
                    .font(.subheadline)
            }
            
            // Card ID/UID (first few bytes)
            if data.count >= 4 {
                HStack {
                    Text("Card ID:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(data.prefix(4).map { String(format: "%02X", $0) }.joined(separator: ":"))
                        .font(.system(.subheadline, design: .monospaced))
                }
            }
            
            // Last read time
            HStack {
                Text("Last Read:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formatDate(Date()))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Details")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                Text("Name:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text(card.name)
                    .font(.subheadline)
            }
            
            HStack {
                Text("Number:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text(formatCardNumber(card.number))
                    .font(.subheadline)
            }
            
            HStack {
                Text("Type:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text(card.cardType.rawValue)
                    .font(.subheadline)
            }
            
            if let expiry = card.expiryDate {
                HStack {
                    Text("Expires:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(formatDate(expiry))
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                // Show delete confirmation alert
                showDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Card")
                }
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatCardNumber(_ number: String) -> String {
        var formattedString = ""
        var index = 0
        
        for character in number where character != " " {
            if index > 0 && index % 4 == 0 {
                formattedString += " "
            }
            formattedString.append(character)
            index += 1
        }
        
        return formattedString
    }
}
