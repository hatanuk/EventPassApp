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
    
    func signUp(email: String, password: String) async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
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
    
    func fetchUserDetails(userId: String) async {
        
        db.collection("userDetails").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                var fetchedDetails: [String: String?] = [
                    "id": userId,
                    "firstName": data?["firstName"] as? String?,
                    "lastName": data?["lastName"] as? String?,
                    "displayName": data?["displayName"] as? String?,
                    "title": data?["title"] as? String?,
                    "workplace": data?["workplace"] as? String?,
                    "email": data?["email"] as? String?,
                    "phone": data?["phone"] as? String?,
                    "profilePictureURL": data?["profile_picture"] as? String ?? Constants.defaultProfileImageURL
                ]
                
                // sets the card's display name to the user's full name as a default
                guard let _ = fetchedDetails["displayName"] else {
                    if let firstName = fetchedDetails["firstName"], let lastName = fetchedDetails["lastName"] {
                        fetchedDetails["displayName"] = firstName + " " + lastName
                    } else {
                        fetchedDetails["displayName"] = "(unknown)"
                    }
                    
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    // Delete information from firestore associated with an account
    private func deleteUserDetails(userId: String) async {}
    
    
    
}
