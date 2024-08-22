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
import PhoneNumberKit

class CardViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    
    // observers are used to update the card instance with the changed details
    
    // ID can be an empty string, but in practice, it should be set immediately by the view or the operation should be cancelled
    @Published var id: String = "" {
        didSet { updateCard() }
    }
    @Published var displayName: String = "" {
        didSet { updateCard() }
    }
    @Published var title: String = "" {
        didSet { updateCard() }
    }
    @Published var workplace: String = "" {
        didSet { updateCard() }
    }
    @Published var email: String = "" {
        didSet { updateCard() }
    }
    @Published var phone: String = "" {
        didSet { updateCard() }
    }
    @Published var profilePictureURL: String = "" {
        didSet { updateCard() }
    }
    @Published var theme: ColorThemes = Constants.defaultColorTheme {
        didSet { updateCard() }
    }
    
    @Published var card: CardProfile = CardProfile(id: "nil")
    
    @Published var selectedPhoto: UIImage? = nil
    
    private func updateCard() {
        card = CardProfile(
            id: id,
            displayName: displayName.isEmpty ? nil : displayName,
            title: title.isEmpty ? nil : title,
            workplace: workplace.isEmpty ? nil : workplace,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            profilePictureURL: profilePictureURL.isEmpty ? nil : profilePictureURL,
            theme: theme
        )
    }
    
    func validateInputs() -> Bool {
        
        if !email.isEmpty && !email.isValidEmail {
            errorMessage = "Please make sure the email is valid"
            return false
        } else if !phone.isEmpty && !phone.isValidPhoneNumber {
            errorMessage = "Please make sure the phone number is valid"
            return false
        }
        return true
    }
 
    // MARK: Firebase Operations
    
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
        
        guard id != "" else {
            errorMessage = "User not authenticated"
            return false
        }
    
        do {
            let card = try await CardProfile(fromUserId: id)
            self.id = card.id
            self.displayName = card.displayName ?? ""
            self.title = card.title ?? ""
            self.workplace = card.workplace ?? ""
            self.email = card.email ?? ""
            self.phone = card.phone ?? ""
            self.profilePictureURL = card.profilePictureURL ?? ""
            self.theme = card.theme
            self.card = card
            return true
        } catch FirestoreErrorCode.notFound {
            // user does not yet have a saved card, no worries
            return false
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            return false
        }
        
    }
        
}


extension String {
    var isValidPhoneNumber: Bool {
        // checks string is numeric and between 10-15 digits of length
           let phoneNumberRegex = "^[0-9]{10,15}$"
           let phoneNumberPred = NSPredicate(format: "SELF MATCHES %@", phoneNumberRegex)
           return phoneNumberPred.evaluate(with: self)
       }
}
