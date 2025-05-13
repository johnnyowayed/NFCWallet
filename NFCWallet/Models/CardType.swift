//
//  CardType.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import SwiftUICore

enum CardType: String, Codable, CaseIterable {
    case accessCard = "Access Card"
    case paymentCard = "Payment Card"
    case idCard = "ID Card"
    case transitCard = "Transit Card"
    
    var icon: String {
        switch self {
        case .accessCard: return "lock.open.fill"
        case .paymentCard: return "creditcard.fill"
        case .idCard: return "person.fill"
        case .transitCard: return "tram.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .accessCard: return .indigo
        case .paymentCard: return .blue
        case .idCard: return .green
        case .transitCard: return .orange
        }
    }
    
    var isReadable: Bool {
        self != .paymentCard
    }
}
