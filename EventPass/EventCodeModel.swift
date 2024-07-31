//
//  File.swift
//  EventPass
//
//  Created by Andrew A on 29/07/2024.
//

import Foundation
import Firebase

struct EventCode {
    let code: String
    static let codeLength = 6
    
    init?() {
        do {
            code = ""
            try generateUniqueCode()
        }
            
        catch {
                print("Failed to generate code")
                return nil
        }
        
    }
    
    private func generateUniqueCode() throws {
        let db = Firestore.firestore()
        let docRef = db.collection("activeEvents")
        
        
        
    }
}

extension EventCode: Equatable {
    static func == (lhs: EventCode, rhs: EventCode) -> Bool {
        lhs.code == rhs.code
    }
}
