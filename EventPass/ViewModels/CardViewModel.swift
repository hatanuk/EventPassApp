//
//  CardViewModel.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import SwiftUI
import Combine
import Firebase

class CardViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    
    @Published var id: String = ""
    @Published var displayName: String = ""
    @Published var title: String = ""
    @Published var workplace: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var profilePictureURL: String = ""
    @Published var theme: ColorThemes = Constants.defaultColorTheme
    @EnvironmentObject var authViewModel: AuthViewModel
    
    
 
    
    func save() async -> Bool {
        let card = CardProfile(id: id,
                           displayName: displayName,
                           title: title,
                           workplace: workplace,
                           email: email,
                           phone: phone,
                           profilePictureURL: profilePictureURL,
                           theme: theme)
        do {
            try await UserService.saveUserDetails(fromCard: card)
            return true
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            return false
        }
        
    }
    
    func load() async -> Bool {
        
        guard let id = authViewModel.getUserId() else {
            errorMessage = "User not authenticated"
            return false
        }
    
        do {
            let card = try await CardProfile(fromUserId: id)
            return true
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            return false
        }
        
    }
        
}
