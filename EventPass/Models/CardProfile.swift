//
//  Profile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import SwiftData


class CardProfile {
    
    let id: String
    var displayName: String?
    var title: String?
    var workplace: String?
    var email: String?
    var phone: String?
    var profilePictureURL: String?
    
    init(id: String, displayName: String? = nil, title: String? = nil, workplace: String? = nil, email: String? = nil, phone: String? = nil, profilePictureURL: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.title = title
        self.workplace = workplace
        self.email = email
        self.phone = phone
        self.profilePictureURL = profilePictureURL
    }

    
}
