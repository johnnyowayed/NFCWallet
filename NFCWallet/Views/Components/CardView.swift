//
//  CardView.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import SwiftUI

struct CardView: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: card.cardType.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Text(formatCardNumber(card.number))
                .font(.title3)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(card.cardType.rawValue)
                .font(.callout)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(card.cardType.color)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatCardNumber(_ number: String) -> String {
        // Format card number with spaces for readability
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
