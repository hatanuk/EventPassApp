//
//  Constants.swift
//  EventPass
//
//  Created by Andrew A on 23/06/2024.
//

import Foundation

struct Constants {
    static let defaultProfileImageURL = "https://avatars.githubusercontent.com/u/583231?v=4"
    
    static let defaultColorTheme = ColorThemes.coolBlue
    
    static let unspecifiedDisplayName = "Your name"
    
    static let testProfile = CardProfile(
        id: "1",
        displayName: "John Smitherson the third",
        title: "Software Engineer",
        workplace: "Tech Company",
        email: "john.doe@example.com",
        phone: "1234567890",
        profilePictureURL: Constants.defaultProfileImageURL
    )
    
    static let testProfile2 = CardProfile(
        id: "1",
        displayName: "John Smith",
        title: "Software Engineer",
        workplace: "Tech Company",
        email: "john.doe@example.com",
        phone: "1234567890",
        profilePictureURL: Constants.defaultProfileImageURL
    )
    
}
