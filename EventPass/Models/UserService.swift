//
//  UserProfile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum UserError: Error {
    case userNotFound
}

enum DatabaseError: Error {
    case documentNotFound
}

class UserService {
    
    // This class is responsible for handling user-related Firebase operations
    // All exposed methods are static and there is no need for instantiation, hence:
    private init() {}
    
    private static var db = Firestore.firestore()
    
    
    // MARK: - Authentication
    
    static func signIn(email: String, password: String) async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            return authResult
        } catch {
            throw error
        }
    }
    
    static func signInAnonymously() async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            return authResult
        } catch {
            throw error
        }
    }
    
    static func signUp(email: String, password: String, user: User) async throws -> AuthDataResult {
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let authResult = try await user.link(with: credential)
            return authResult
        } catch {
            throw error
        }
    }
    
    
    
    static func signOut() throws {
        do {
          try Auth.auth().signOut()
        }
        catch {
          throw error
        }
      }
    
    
    
    static func deleteAccount(user: User) async throws {
        do {
            try await user.delete()
            try await deleteUserDetails(userId: user.uid)
        
        } catch {
                throw error
        }
    }
    
    //MARK: - Database Operations
    
    
    static func fetchUserDetails(userId: String) async throws -> [String: String?] {
        var document: DocumentSnapshot?
           
       do {
           document = try await db.collection("userDetails").document(userId).getDocument()
       } catch {
           throw error
       }
       
       guard let document = document, document.exists else {
           print("Document does not exist")
           throw DatabaseError.documentNotFound
       }
       
       let data = document.data()
       var fetchedDetails: [String: String?] = [
           "displayName": data?["displayName"] as? String,
           "title": data?["title"] as? String,
           "workplace": data?["workplace"] as? String,
           "email": data?["email"] as? String,
           "phone": data?["phone"] as? String,
           "profilePictureURL": data?["profile_picture"] as? String,
           "theme": data?["theme"] as? String
       ]
        
        return fetchedDetails
       
   }
    
    static func saveUserDetails(fromCard card: CardProfile) async throws {

        let cardData: [String: Any] = [
            "displayName": card.displayName ?? "",
            "workplace": card.workplace ?? "",
            "title": card.title ?? "",
            "email": card.email ?? "",
            "phone": card.phone ?? "",
            "profile_picture": card.profilePictureURL ?? "",
            "theme": String(card.theme.id)
        ]
    
        // asynchronous wrapper to for error throwing with firebase operation
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                db.collection("userDetails").document(card.id).setData(cardData) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
    }
    
    // delete information from firestore associated with an account
    static func deleteUserDetails(userId: String) async throws {
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                db.collection("userDetails").document(userId).delete() { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
    }
    
    
    
}
