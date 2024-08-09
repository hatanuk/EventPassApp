//
//  Profile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import SwiftData


struct CardProfile {
    
    let model = UserModel()
    
    let id: String
    var displayName: String? = ""
    var title: String? = ""
    var workplace: String? = ""
    var email: String? = ""
    var phone: String? = "''"
    var profilePictureURL: String? = ""
    
    init(fromUserId userId: String) async {
        self.id = userId
        
        do {
            let queryResult = try await model.fetchUserDetails(userId: userId)
        } catch DatabaseError.documentNotFound {
            print("User not found")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
    }
    
    init(id: String,
             displayName: String? = nil,
             title: String? = nil,
             workplace: String? = nil,
             email: String? = nil,
             phone: String? = nil,
             profilePictureURL: String? = nil) {
            self.id = id
            self.displayName = displayName
            self.title = title
            self.workplace = workplace
            self.email = email
            self.phone = phone
            self.profilePictureURL = profilePictureURL
        }
    

    
}
