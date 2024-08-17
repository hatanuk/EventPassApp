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

struct UserModel {
    
    private var db = Firestore.firestore()
    
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            return authResult
        } catch {
            throw error
        }
    }
    
    func signInAnonymously() async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            return authResult
        } catch {
            throw error
        }
    }
    
    func signUp(email: String, password: String, user: User) async throws -> AuthDataResult {
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let authResult = try await user.link(with: credential)
            return authResult
        } catch {
            throw error
        }
    }
    
    
    
    func signOut() throws {
        do {
          try Auth.auth().signOut()
        }
        catch {
          throw error
        }
      }
    
    
    
    func deleteAccount(user: User) async throws {
        do {
            try await user.delete()
            await deleteUserDetails(userId: user.uid)
        
        } catch {
                throw error
        }
    }
    
    //MARK: - Database
    
    func fetchUserDetails(userId: String) async throws -> [String: String?] {
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
           "firstName": data?["firstName"] as? String,
           "lastName": data?["lastName"] as? String,
           "displayName": data?["displayName"] as? String,
           "title": data?["title"] as? String,
           "workplace": data?["workplace"] as? String,
           "email": data?["email"] as? String,
           "phone": data?["phone"] as? String,
           "profilePictureURL": data?["profile_picture"] as? String,
           "theme": data?["theme"] as? String
       ]
       
       // sets the card's display name to the user's full name as a default
       if fetchedDetails["displayName"] == nil {
           if let firstName = fetchedDetails["firstName"] as? String, let lastName = fetchedDetails["lastName"] as? String {
               fetchedDetails["displayName"] = firstName + " " + lastName
           } 
       }
        
        return fetchedDetails
       
   }
    
    // Delete information from firestore associated with an account
    private func deleteUserDetails(userId: String) async {}
    
    
    
}
