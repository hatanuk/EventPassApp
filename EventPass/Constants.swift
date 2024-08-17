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
    
    static let testProfile = CardProfile(
        id: "1",
        displayName: "John Smitherson the Third",
        title: "Software Engineer",
        workplace: "Tech Company",
        email: "john.doe@example.com",
        phone: "+1234567890",
        profilePictureURL: Constants.defaultProfileImageURL
    )
    
}
