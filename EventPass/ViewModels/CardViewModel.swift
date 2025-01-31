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
    // handles logic relating to the creation and retrieval of user cards
        
    @Published var errorMessage = ""
    
    // observers are used to update the card instance with the changed details
    
    var id: String
    var alias: String
    
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
    
    @Published var card: CardModel = CardModel(id: "nil", alias: "nil")
    
    @Published var selectedPhoto: UIImage? = nil
    
    init(id: String, alias: String) {
        self.id = id
        self.alias = alias
    }
    
    private func updateCard() {
        card = CardModel(
            id: id,
            alias: alias,
            displayName: displayName.isEmpty ? nil : displayName,
            title: title.isEmpty ? nil : title,
            workplace: workplace.isEmpty ? nil : workplace,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            profilePictureURL: profilePictureURL.isEmpty ? nil : profilePictureURL,
            theme: theme
        )
    }
    
    func validateInputs() async -> Bool {
        let optionals = [displayName, title, workplace, email, phone, profilePictureURL]
        
        return await MainActor.run {
        
            if (optionals.allSatisfy { $0.isEmpty }) {
                    errorMessage = "Please fill in at least one field"
                    return false
                }
            
            if !email.isEmpty && !email.isValidEmail {
                errorMessage = "Please make sure the email is valid"
                return false
            } else if !phone.isEmpty && !phone.isValidPhoneNumber {
                errorMessage = "Please make sure the phone number is valid"
                return false
            }
    
            return true
        }
    }
    
    //MARK: - Mixed DB Operations
    
    func save() async -> Bool {
        // saves the card both locally and on Firestore
        
        let card = CardModel(id: id,
                             alias: alias,
                               displayName: displayName,
                               title: title,
                               workplace: workplace,
                               email: email,
                               phone: phone,
                               profilePictureURL: profilePictureURL,
                               theme: theme)
        
        // save locally
        saveLocalCard()
        
        // save on firebase
        do {
            try await FirebaseService.save(card: card)
            return true
        } catch {
            return await MainActor.run {
                print(error)
                errorMessage = error.localizedDescription
                return false
            }
        }
        
    }
    
    func load() async {
        // loads the card from either UserDefaults or Firestore
        
        guard id != "" else {
            await MainActor.run {
                errorMessage = "User not authenticated"
            }
            return
        }
        
        let card = await CardViewModel.retrieveCardIfExists(userID: id)
            // this updates the viewmodel with the card info
            if let card = card {
                await MainActor.run {
                    self.id = card.id
                    self.alias = card.alias
                    self.displayName = card.displayName ?? ""
                    self.title = card.title ?? ""
                    self.workplace = card.workplace ?? ""
                    self.email = card.email ?? ""
                    self.phone = card.phone ?? ""
                    self.profilePictureURL = card.profilePictureURL ?? ""
                    self.theme = card.theme
                    self.card = card
                }
            }
        }
    
    
    
    //MARK: - Local DB Operations
    
    func saveLocalCard() {
        let defaults = UserDefaults.standard
           if let encodedData = try? JSONEncoder().encode(card) {
               defaults.set(encodedData, forKey: "savedCard")
           }
    }
    
    static func deleteLocalCard() {
        UserDefaults.standard.removeObject(forKey: "savedCard")
    }
    
    static func retrieveLocalCard() -> CardModel? {
        let defaults = UserDefaults.standard
        if let savedData = defaults.data(forKey: "savedCard"),
           let decodedObject = try? JSONDecoder().decode(CardModel.self, from: savedData) {
            return decodedObject
        }
        return nil
    }
    
    static func retrieveCardIfExists(userID: String) async -> CardModel? {
        
        // first, try fetching the card locally
        if let card = CardViewModel.retrieveLocalCard() {
            return card
        }
        // otherwise fetch it from firebase
        do {
            return try await CardModel(fromUserId: userID)
        } catch {
            return nil
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
