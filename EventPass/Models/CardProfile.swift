//
//  Profile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import SwiftData



struct CardProfile {
    
    /// Mandatory properties
    let id: String
    
    /// Optional properties
    var displayName: String? = ""
    var title: String? = ""
    var workplace: String? = ""
    var email: String? = ""
    var phone: String? = ""
    var profilePictureURL: String? = ""
    var theme: ColorThemes = Constants.defaultColorTheme
    
    init(fromUserId userId: String) async throws {
        self.id = userId
        
        do {
            let queryResult = try await UserService.fetchUserDetails(userId: userId)
            displayName = queryResult["displayName"] ?? "(unknown)"
            title = queryResult["title"] ?? ""
            workplace = queryResult["workplace"] ?? ""
            email = queryResult["email"] ?? ""
            phone = queryResult["phone"] ?? ""
            profilePictureURL = queryResult["profilePictureURL"] ?? Constants.defaultProfileImageURL
            if let themeResult = queryResult["theme"], let themeString = themeResult {
                theme = ColorThemes(id: Int(themeString) ?? 0)
            }
            
        } catch {
            throw error
        }
        
    }
    
    init(id: String,
             displayName: String? = nil,
             title: String? = nil,
             workplace: String? = nil,
             email: String? = nil,
             phone: String? = nil,
             profilePictureURL: String? = nil,
             theme: ColorThemes = Constants.defaultColorTheme) {
            self.id = id
            self.displayName = displayName
            self.title = title
            self.workplace = workplace
            self.email = email
            self.phone = phone
            self.profilePictureURL = profilePictureURL
            self.theme = theme
        }
    

    
}
