//
//  Event.swift
//  EventPass
//
//  Created by Andrew A on 02/08/2024.
//

import Foundation
import Firebase
import SwiftData



// Note: this class is of optional type

@Model
class Event {
    let code: String
    
    
    init?() {
        do {
            self.code =  try EventModel.generateUniqueCode()
            EventModel.storeActiveCode(code: self.code)
        }
            
        catch {
                print("Failed to generate code")
                return nil
        }
        
    }
    
    
    deinit {
        
        // ensure that the firebase record is deleted
        
    }
}
