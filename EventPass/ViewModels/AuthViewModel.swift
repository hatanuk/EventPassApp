//
//  AuthViewModel.swift
//  EventPass
//
//  Created by Andrew A on 07/08/2024.
//

import Foundation
import FirebaseAuth

enum AuthenticationState {
  case authenticated
  case unauthenticated
  case authenticating
}

enum AuthenticationType {
  case withAnonymous
  case withAccount
}


class AuthViewModel: ObservableObject {
     
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordRepeat: String = ""
    
    @Published var acceptedTerms: Bool = false
    
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    
    @Published var userProfile: UserProfile?
    @Published var cardProfile: CardProfile?
    
    @Published var errorMessage = ""
    
    @Published var user: User?
    
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var authenticationType: AuthenticationType = .withAnonymous
    
}

// MARK: - Actions
// methods relating to authentication actions eg. logging in
extension AuthViewModel {
    
    
    func loginEmailPassword() async -> Bool {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            user = authResult.user
            userProfile = UserProfile(id: authResult.user.uid, firstName: firstName, lastName: lastName)
            cardProfile = CardProfile(id: authResult.user.uid)
            print("LOGIN FROM: \(authResult.user.uid)")
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func signUpEmailPassword() async -> Bool {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            user = authResult.user
            userProfile = UserProfile(id: authResult.user.uid, firstName: firstName, lastName: lastName)
            cardProfile = CardProfile(id: authResult.user.uid)
            print("LOGIN FROM: \(authResult.user.uid)")
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func checkAuthenticationState() {
        
        // bypass, remove later
        self.authenticationState = .authenticated
        
        if Auth.auth().currentUser != nil {
            self.authenticationState = .authenticated
        } else {
            self.authenticationState = .authenticating
            loginAnonymously()
        }
    }

    func loginAnonymously() {
        Auth.auth().signInAnonymously() { authResult, error in
            if let error = error {
                print("Error logging in anonymously: \(error)")
                return
            }
            self.authenticationState = .authenticated
        }
    }
}
