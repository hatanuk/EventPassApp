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
    @Published var cardProfile: CardProfile

    private var db = Firestore.firestore()
    
        
    init(businessCard: CardProfile) {
        self.cardProfile = businessCard
    }
    
    func save() {
        let cardData: [String: Any] = [
            "name": cardProfile.displayName ?? "",
            "workplace": cardProfile.workplace ?? "",
            "title": cardProfile.title ?? "",
            "email": cardProfile.email ?? "",
            "phone": cardProfile.phone ?? "",
            "profile_picture": cardProfile.profilePictureURL ?? ""
        ]
        
        db.collection("businessCards").document(cardProfile.id).setData(cardData) { error in
            if let error = error {
                print("Error saving card profile: \(error.localizedDescription)")
            } else {
                print("Card profile saved successfully.")
            }
        }
    }
        
}
