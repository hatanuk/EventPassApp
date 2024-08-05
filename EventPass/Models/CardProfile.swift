//
//  Profile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation


struct CardProfile: Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let workplace: String
    let profilePictureURL: URL?
    
    init(id: UUID, firstName: String, lastName: String, workplace: String, profilePictureURL: URL? = nil) {
         self.id = id  // This could be a unique identifier like a UUID or a database ID
         self.firstName = firstName
         self.lastName = lastName
         self.workplace = workplace
         self.profilePictureURL = profilePictureURL ?? Constants.defaultProfileImageURL
    
     }
    
}
