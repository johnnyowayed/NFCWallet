//
//  NFCManger.swift
//  NFCWallet
//
//  Created by Johnny Owayed on 13/05/2025.
//

import CoreNFC
import UIKit

class NFCManager: NSObject, NFCTagReaderSessionDelegate, ObservableObject {
    static let shared = NFCManager()
    
    @Published var isScanning = false
    @Published var lastErrorMessage: String?
    @Published var lastScannedNumber: String?
    
    private var session: NFCTagReaderSession?
    private var completionHandler: ((Result<Data, Error>) -> Void)?
    private var currentCardType: CardType?
    
    enum NFCError: Error, LocalizedError {
        case readFailed
        case unsupportedTag
        case invalidData
        case notAvailable
        
        var errorDescription: String? {
            switch self {
            case .readFailed: return "Failed to read NFC tag"
            case .unsupportedTag: return "Unsupported NFC tag type"
            case .invalidData: return "Invalid data in NFC tag"
            case .notAvailable: return "NFC reading not available on this device"
            }
        }
    }
    
    private override init() {
        super.init()
    }
    
    // Helper function to show alerts in SwiftUI context
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                let alert = UIAlertController(
                    title: title,
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    private func extractCardNumberFromNFCData(_ data: Data) -> String {
        // Different card types may encode their numbers differently
        // This is a simplified implementation that tries a few common approaches
        
        // For demonstration, let's try different approaches to extract a number
        
        // 1. First try direct ASCII conversion of the whole data
        if let asciiString = String(data: data, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !asciiString.isEmpty, asciiString.contains(where: { $0.isNumber }) {
            // Basic validation: must contain at least one number
            let filtered = asciiString.filter { $0.isNumber || $0 == " " }
            if filtered.count >= 4 {  // Assuming card numbers are at least 4 digits
                return filtered
            }
        }
        
        // 2. Try to extract numbers from hexadecimal representation
        // Some cards store numbers in hex or BCD (Binary Coded Decimal) format
        let hexString = data.map { String(format: "%02X", $0) }.joined()
        
        // Check if we have a sequence of digits in the hex string
        // For BCD format, each digit is stored as a 4-bit value (0-9)
        var cardNumber = ""
        var digitCount = 0
        
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let startIndex = hexString.index(hexString.startIndex, offsetBy: i)
            let endIndex = hexString.index(startIndex, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString.endIndex
            let byteString = String(hexString[startIndex..<endIndex])
            
            if let byte = UInt8(byteString, radix: 16) {
                // Extract high and low nibbles (4 bits each)
                let highNibble = byte >> 4
                let lowNibble = byte & 0x0F
                
                // If these are valid BCD digits (0-9), add them to the result
                if highNibble <= 9 {
                    cardNumber.append(String(highNibble))
                    digitCount += 1
                }
                
                if lowNibble <= 9 {
                    cardNumber.append(String(lowNibble))
                    digitCount += 1
                }
                
                // Add a space every 4 digits for readability
                if digitCount % 4 == 0 && digitCount > 0 && digitCount < 16 {
                    cardNumber.append(" ")
                }
                
                // Stop once we have a reasonable card number length
                if digitCount >= 16 {
                    break
                }
            }
        }
        
        // 3. If extracting as BCD didn't yield a good result, try reading bytes directly as numbers
        if cardNumber.count < 8 {
            cardNumber = ""
            for byte in data {
                if byte >= 48 && byte <= 57 { // ASCII 0-9
                    cardNumber.append(String(UnicodeScalar(byte)))
                    
                    // Add a space every 4 digits for readability
                    if cardNumber.count % 4 == 0 && cardNumber.count < 16 {
                        cardNumber.append(" ")
                    }
                }
            }
        }
        
        // Finally, if we couldn't extract anything meaningful, generate a fallback
        if cardNumber.count < 8 {
            // Use a hash of the NFC data to create a consistent but unique card number
            let hash = data.hashValue
            let hashString = String(abs(hash))
            
            // Take last 16 digits or pad with zeros
            let digits = hashString.suffix(16)
            let padded = String(repeating: "0", count: max(0, 16 - digits.count)) + digits
            
            // Format with spaces
            var formatted = ""
            for (index, char) in padded.enumerated() {
                if index > 0 && index % 4 == 0 {
                    formatted.append(" ")
                }
                formatted.append(char)
            }
            
            return formatted
        }
        
        return cardNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func beginScan(for cardType: CardType, completion: @escaping (Result<Data, Error>) -> Void) {
        // Check if payment card - Apple does not allow reading payment cards with NFC
        if cardType == .paymentCard {
            showAlert(
                title: "Cannot Read Payment Cards",
                message: "Apple restricts iOS apps from reading payment or bank cards. This is a security limitation."
            )
            completion(.failure(NFCError.unsupportedTag))
            return
        }
        
        guard NFCTagReaderSession.readingAvailable else {
            showAlert(
                title: "NFC Not Available",
                message: "NFC reading is not available on this device."
            )
            completion(.failure(NFCError.notAvailable))
            return
        }
        
        self.completionHandler = completion
        self.currentCardType = cardType
        self.isScanning = true
        
        // Choose appropriate polling option based on card type
        let pollingOption: NFCTagReaderSession.PollingOption
        switch cardType {
        case .transitCard:
            pollingOption = .iso15693 // For FeliCa transit cards
        case .accessCard, .idCard:
            pollingOption = .iso14443 // For MIFARE and ISO15693
        default:
            pollingOption = .iso14443
        }
        
        session = NFCTagReaderSession(pollingOption: pollingOption, delegate: self)
        session?.alertMessage = "Hold your device near the NFC card"
        session?.begin()
    }
    
    func simulateNFCTap(with card: Card, completion: @escaping (Bool) -> Void) {
        // In a real app, this would interact with the CoreNFC framework
        // For this example, we'll simulate the action
        isScanning = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isScanning = false
            completion(true)
        }
    }
    
    // MARK: - NFCTagReaderSessionDelegate
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session started
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // Handle session errors
        isScanning = false
        lastErrorMessage = error.localizedDescription
        completionHandler?(.failure(error))
        self.session = nil
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No valid tag found")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }
            
            // Process tag based on type
            switch tag {
            case .miFare(let mifareTag):
                self.readMiFareTag(mifareTag, session: session)
            case .iso15693(let iso15693Tag):
                self.readISO15693Tag(iso15693Tag, session: session)
            case .feliCa(let feliCaTag):
                self.readFeliCaTag(feliCaTag, session: session)
            default:
                session.invalidate(errorMessage: "Unsupported tag type")
            }
        }
    }
    
    private func readMiFareTag(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
        // Example command for reading from Mifare tag
        let readCommand = Data([0x30, 0x00]) // Example command (may vary based on card)
        tag.sendMiFareCommand(commandPacket: readCommand) { data, error in
            if let error = error {
                session.invalidate(errorMessage: "Read failed: \(error.localizedDescription)")
                self.completionHandler?(.failure(NFCError.readFailed))
                return
            }
            
            // Process the data and try to extract a card number
            let cardNumber = self.extractCardNumberFromNFCData(data)
            self.lastScannedNumber = cardNumber
            
            session.alertMessage = "Tag read successfully!"
            session.invalidate()
            self.isScanning = false
            self.completionHandler?(.success(data))
        }
    }
    
    private func readISO15693Tag(_ tag: NFCISO15693Tag, session: NFCTagReaderSession) {
        // Read a block of data (block 0 in this example)
        tag.readSingleBlock(requestFlags: .highDataRate, blockNumber: 0) { data, error in
            if let error = error {
                session.invalidate(errorMessage: "Read failed: \(error.localizedDescription)")
                self.completionHandler?(.failure(NFCError.readFailed))
                return
            }
            
            // Process the data and try to extract a card number
            let cardNumber = self.extractCardNumberFromNFCData(data)
            self.lastScannedNumber = cardNumber
            
            session.alertMessage = "Tag read successfully!"
            session.invalidate()
            self.isScanning = false
            self.completionHandler?(.success(data))
        }
    }
    
    private func readFeliCaTag(_ tag: NFCFeliCaTag, session: NFCTagReaderSession) {
        
        let serviceCode = Data([0x0F, 0x00]) // Example service code
        let blockList = [Data([0x80, 0x00])] // Block 0
        
        tag.requestService(nodeCodeList: [serviceCode]) { result, error in
            if let error = error {
                session.invalidate(errorMessage: "Service request failed: \(error.localizedDescription)")
                self.completionHandler?(.failure(NFCError.readFailed))
                return
            }
            
            tag.readWithoutEncryption(serviceCodeList: [serviceCode], blockList: blockList) { data, sCode, blockData, error in
                if let error = error {
                    session.invalidate(errorMessage: "Read failed: \(error.localizedDescription)")
                    self.completionHandler?(.failure(NFCError.readFailed))
                    return
                }
                
                // Process the first block data if available
                if let firstBlockData = blockData.first {
                    let cardNumber = self.extractCardNumberFromNFCData(firstBlockData)
                    self.lastScannedNumber = cardNumber
                    
                    session.alertMessage = "Tag read successfully!"
                    session.invalidate()
                    self.isScanning = false
                    self.completionHandler?(.success(firstBlockData))
                } else {
                    session.invalidate(errorMessage: "No valid data found")
                    self.completionHandler?(.failure(NFCError.invalidData))
                }
            }
        }
    }
}
