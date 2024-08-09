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

enum SignUpError: Error {
    case passwordMismatch, invalidEmail, shortPassword, weakPassword
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
    
    func validateSignUp() throws {
        
        let containsCapitalLetter = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let containsNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        if (!email.isValidEmail) {
            throw SignUpError.invalidEmail
        } else if (password != passwordRepeat) {
            throw SignUpError.passwordMismatch
        } else if (password.count < 6) {
            throw SignUpError.shortPassword
        } else if (!containsCapitalLetter || !containsNumber) {
            throw SignUpError.weakPassword
        }
    }
    
// MARK: - Actions
// methods relating to authentication actions eg. logging in
    
    func signUpEmailPassword() async -> Bool {
        
        do {
            // Validation
            try validateSignUp()
            
            
            let authResult = try await userModel.signIn(email: email, password: password)
            user = authResult.user
            print("SIGNUP FROM: \(authResult.user.uid)")
            authenticationState = .authenticated
            return true
            
        } catch SignUpError.invalidEmail {
            errorMessage = "Invalid email address"
            return false
        } catch SignUpError.passwordMismatch {
            errorMessage = "Passwords do not match"
            return false
        } catch SignUpError.shortPassword {
            errorMessage = "Password must be at least 6 characters"
            return false
        } catch SignUpError.weakPassword {
            errorMessage = "Password must contain at least one capital letter and one number"
            return false
        } catch {
            errorMessage = error.localizedDescription
            print("SIGNUP ERROR: \(error)")
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
    
    func signInEmailPassword() async -> Bool {
        do {
            let authResult = try await userModel.signIn(email: email, password: password)
            user = authResult.user
            print("LOGIN FROM: \(authResult.user.uid)")
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            print("LOGIN ERROR: \(error)")
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

extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
