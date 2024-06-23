//
//  BLEModel.swift
//  EventPass
//
//  Created by Andrew A on 23/06/2024.
//

import Foundation

struct Profile: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let workplace: String
    let profilePictureURL: URL?
    
    init(id: String, firstName: String, lastName: String, workplace: String, profilePictureURL: URL? = nil) {
         self.id = id  // This could be a unique identifier like a UUID or a database ID
         self.firstName = firstName
         self.lastName = lastName
         self.workplace = workplace
         self.profilePictureURL = profilePictureURL ?? Constants.defaultProfileImageURL
    
     }
    
}
