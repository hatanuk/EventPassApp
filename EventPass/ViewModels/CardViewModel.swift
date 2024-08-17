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
    
    @Published var id: String = ""
    @Published var displayName: String = ""
    @Published var title: String = ""
    @Published var workplace: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var profilePictureURL: String = ""
    @Published var theme: ColorThemes = Constants.defaultColorTheme
    
    

    private var db = Firestore.firestore()
    
 
    
    func save() {
        let cardData: [String: Any] = [
            "name": displayName,
            "workplace": workplace,
            "title": title,
            "email": email,
            "phone": phone,
            "profile_picture": profilePictureURL
        ]
        
        db.collection("businessCards").document(id).setData(cardData) { error in
            if let error = error {
                print("Error saving card profile: \(error.localizedDescription)")
            } else {
                print("Card profile saved successfully.")
            }
        }
    }
        
}
