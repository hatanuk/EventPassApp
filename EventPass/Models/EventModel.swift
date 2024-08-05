//
//  EventModel.swift
//  EventPass
//
//  Created by Andrew A on 02/08/2024.
//

import Foundation
import Firebase


class EventModel {

    // attempts to generate a unique six-digit code that is not already used by an active event
    static func generateUniqueCode() throws -> String {
        let db = Firestore.firestore()
        let docRef = db.collection("activeEvents")
        return "HI"
        
        
    }
    
    // stores an active code in firebase upon the creation of an event
    static func storeActiveCode(code: String) {
        
    }
    
    
    // removes an active code from firebase upon event inactivity
    static func removeActiveCode(code: String) {
        
    }
    
    

}


