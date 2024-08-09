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
    
    @Published var errorMessage = ""
    
    @Published var user: User?
    
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var authenticationType: AuthenticationType = .withAnonymous
    
    private var userModel = UserModel()
    
}

// MARK: - Actions
// methods relating to authentication actions eg. logging in
extension AuthViewModel {
    
    func clearAllValues() {
        email = ""
        password = ""
        passwordRepeat = ""
        firstName = ""
        lastName = ""
    }
    
    func allPropertiesFilled() -> Bool {
        return !email.isEmpty && !password.isEmpty && !passwordRepeat.isEmpty && !firstName.isEmpty && !lastName.isEmpty
    }
    
    
    
    func signInEmailPassword() async -> Bool {
        do {
            let authResult = try await userModel.signIn(email: email, password: password)
            user = authResult.user
            print("LOGIN FROM: \(authResult.user.uid)")
            authenticationState = .authenticated
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            print("ANONYMOUS LOGIN ERROR: \(errorMessage)")
            return false
        }
    }
    
    func signInAnonymously() async -> Bool {
        
        do {
            let authResult = try await userModel.signInAnonymously()
            user = authResult.user
            print("ANONYMOUS LOGIN FROM: \(authResult.user.uid)")
            authenticationState = .authenticated
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("ANONYMOUS LOGIN ERROR: \(errorMessage)")
            return false
        }
        
    }
    
    func signUpEmailPassword() async -> Bool {
        do {
            let authResult = try await userModel.signUp(email: email, password: password)
            user = authResult.user
            print("SIGNUP FROM: \(authResult.user.uid)")
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            print("SIGNUP ERROR: \(errorMessage)")
            return false
        }
    }
    
    func checkAuthenticationState() {
        
        // bypass, remove later
        self.authenticationState = .authenticated
        
        if user != nil {
            self.authenticationState = .authenticated
        } else {
            self.authenticationState = .authenticating
        }
    }

    
}
