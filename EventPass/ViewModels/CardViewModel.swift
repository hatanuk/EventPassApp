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
        
    func load(user: UserProfile) {
        db.collection("businessCards").document(user.id).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.cardProfile = CardProfile(
                    id: user.id,
                    displayName: data?["displayName"] as? String,
                    title: data?["title"] as? String ?? "",
                    workplace: data?["workplace"] as? String ?? "",
                    email: data?["email"] as? String ?? "",
                    phone: data?["phone"] as? String ?? "",
                    profilePictureURL: data?["profile_picture"] as? String ?? Constants.defaultProfileImageURL
                )
                
                // sets the card's display name to the user's full name as a default
                if self.cardProfile.displayName?.count == 0 {
                    self.cardProfile.displayName = "John Doe"
                }
            } else {
                print("Document does not exist")
            }
        }
        
    }
}
