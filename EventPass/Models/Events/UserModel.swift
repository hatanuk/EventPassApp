//
//  UserModel.swift
//  EventPass
//
//  Created by Andrew A on 26/10/2024.
//


import Foundation
import CoreBluetooth

struct UserModel: Identifiable, Codable {
    // this is a truncated CardModel that will represent nearby users, to fit under the 182 byte limit
    
    let id: String
    let displayName: String?
    let profilePictureURL: String?
    let workplace: String?
    let title: String?
    
    // 178 bytes max
    init(fromCard card: CardModel) {
        self.id = card.id.trimmedTo(maxBytes: 28)
        self.displayName = card.displayName?.trimmedTo(maxBytes: 30)
        self.profilePictureURL = card.profilePictureURL?.trimmedTo(maxBytes: 45)
        self.workplace = card.workplace?.trimmedTo(maxBytes: 30)
        self.title = card.title?.trimmedTo(maxBytes: 30)
        
        if let jsonData = try? JSONEncoder().encode(self) {
            print("UserModel JSON size: \(jsonData.count) bytes")
        }
    }
}

extension String {
    func trimmedTo(maxBytes: Int) -> String {
        var currentString = self
        while currentString.lengthOfBytes(using: .utf8) > maxBytes {
            currentString = String(currentString.dropLast())
        }
        return currentString
    }
}
