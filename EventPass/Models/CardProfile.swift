//
//  Profile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import SwiftData
import FirebaseFirestore



struct CardProfile {
    
    // Mandatory properties
    let id: String
    
    // Optional properties
    var firstName: String? = ""
    var lastName: String? = ""
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
            firstName = nilIfEmpty(queryResult["firstName"] ?? nil)
            lastName = nilIfEmpty(queryResult["lastName"] ?? nil)
            displayName = nilIfEmpty(queryResult["displayName"] ?? nil)
            title = nilIfEmpty(queryResult["title"] ?? nil)
            workplace = nilIfEmpty(queryResult["workplace"] ?? nil)
            email = nilIfEmpty(queryResult["email"] ?? nil)
            phone = nilIfEmpty(queryResult["phone"] ?? nil)
            profilePictureURL = nilIfEmpty(queryResult["profilePictureURL"] ?? nil) ?? Constants.defaultProfileImageURL
            
            if let themeResult = queryResult["theme"], let themeString = themeResult {
                theme = ColorThemes(id: Int(themeString) ?? 0)
            }
            
        } catch {
            throw error
        }
        
    }
    
    init(id: String,
             firstName: String? = nil,
             lastName: String? = nil,
             displayName: String? = nil,
             title: String? = nil,
             workplace: String? = nil,
             email: String? = nil,
             phone: String? = nil,
             profilePictureURL: String? = nil,
             theme: ColorThemes = Constants.defaultColorTheme) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.displayName = displayName
            self.title = title
            self.workplace = workplace
            self.email = email
            self.phone = phone
            self.profilePictureURL = profilePictureURL
            self.theme = theme
        }
    
    func nilIfEmpty(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }
    

    
}
