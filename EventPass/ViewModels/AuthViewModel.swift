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
    
    // minimum amount of characters for a valid password
    let MIN_PASS_LENGTH = 8
    let defaultErrorMessage = "The operation was unsuccesful, please try again later"
     
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
    
}


extension AuthViewModel {
    
    
    
    // Validation
    
    private func validateSignUp() throws {
        
        let containsCapitalLetter = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let containsNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        if (!email.isValidEmail) {
            throw SignUpError.invalidEmail
        } else if (password != passwordRepeat) {
            throw SignUpError.passwordMismatch
        } else if (password.count < MIN_PASS_LENGTH) {
            throw SignUpError.shortPassword
        } else if (!containsCapitalLetter || !containsNumber) {
            throw SignUpError.weakPassword
        }
    }
    
    
    private func signOutSafely() async {
        do {
            try UserService.signOut()
            await updateUser(to: nil)
        } catch {
            print("ERROR SAFELY SIGNING OUT: \(error)")
        }

    }
    
    
    
// MARK: - Actions
// methods relating to authentication actions eg. logging in
// these are public
    
    func allPropertiesFilled() -> Bool {
        return !email.isEmpty && !password.isEmpty && !passwordRepeat.isEmpty && !firstName.isEmpty && !lastName.isEmpty
    }
    
    func emailPasswordFilled() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    func clearAllValues() async {
        await MainActor.run {
            email = ""
            password = ""
            passwordRepeat = ""
            firstName = ""
            lastName = ""
            errorMessage = ""
            acceptedTerms = false
        }
    }
    
    func getUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func signUpEmailPassword() async -> Bool {
        
        let currentFirstName = firstName
        let currentLastName = lastName
        
        // Sign up is accomplished by linking a mandatory anonymous account with a username-password credential.
        // Users should be signed in anonymously during launch but perform this check either way
        guard let user = user else {
            _ = await signInAnonymously()
            await updateErrorMessage(to: defaultErrorMessage)
            return false
    
        }
        
        // If the user is not anonymous, they must already be signed in
        guard user.isAnonymous else {
            await updateErrorMessage(to: "Already signed in!")
            return false
        }
        
        do {
            // Validation
            try validateSignUp()
            
            let authResult = try await UserService.signUp(email: email, password: password, user: user)
            await updateUser(to: authResult.user)
            try await saveNewUserDetails(userId: user.uid, firstName: currentFirstName, lastName: currentLastName)
            print("SIGNUP FROM: \(authResult.user.uid)")
            return true
            
        } catch SignUpError.invalidEmail {
            await updateErrorMessage(to: "Invalid email address")
            return false
        } catch SignUpError.passwordMismatch {
            await updateErrorMessage(to: "Passwords do not match")
            return false
        } catch SignUpError.shortPassword {
            await updateErrorMessage(to:  "Password must be at least \(MIN_PASS_LENGTH) characters")
            return false
        } catch SignUpError.weakPassword {
            await updateErrorMessage(to: "Password must contain at least one capital letter and one number")
            return false
        } catch {
            await updateErrorMessage(to: defaultErrorMessage)
            print("SIGNUP ERROR: \(error)")
            return false
        }
    }
    
    func signInAnonymously() async -> Bool {
        
        do {
            let authResult = try await UserService.signInAnonymously()
            await updateUser(to: authResult.user)
            print("ANONYMOUS LOGIN FROM: \(authResult.user.uid)")
            return true
        } catch {
            await updateErrorMessage(to: defaultErrorMessage)
            print("ANONYMOUS LOGIN ERROR: \(errorMessage)")
            return false
        }
        
    }
    
    func signInEmailPassword() async -> Bool {
       
        
        guard let user = user, user.isAnonymous else {
            await updateErrorMessage(to: "Already signed in!")
            return false
        }
        
        do {
            await signOutSafely()
            let authResult = try await UserService.signIn(email: email, password: password)
            await updateUser(to: authResult.user)
            print("LOGIN FROM: \(authResult.user.uid)")
            return true
            
        } catch AuthErrorCode.invalidEmail {
            await updateErrorMessage(to: "Please make sure the email was entered correctly")
            return false
        } catch AuthErrorCode.wrongPassword, AuthErrorCode.userNotFound{
            await updateErrorMessage(to: "Incorrect user/password combination")
            return false
        } catch {
            await updateErrorMessage(to: defaultErrorMessage)
            print("LOGIN ERROR: \(error)")
            return false
        }
    }
    
    func signOut() async -> Bool {
        do {
            // Signs the user out and then generates them a new anonymous account
            await signOutSafely()
            if await signInAnonymously() {
                return true
            } else {
                throw NSError()
            }
        } catch {
            await updateErrorMessage(to: defaultErrorMessage)
            print("SIGNOUT ERROR: \(error)")
            return false
        }
    }
    
    func checkAuthenticationState() async {
        
        if user != nil {
            await updateAuthenticationState(to: .authenticated)
        } else {
            await updateAuthenticationState(to: .authenticating)
            let success = await signInAnonymously()
            if success {
                await updateAuthenticationState(to: .authenticated)
            }

        }
    }
    
    // MARK: Helper functions
    
    private func saveNewUserDetails(userId: String, firstName: String, lastName: String) async throws {
        let newUser = CardProfile(id: userId, firstName: firstName, lastName: lastName)
        try await UserService.saveUserDetails(fromCard: newUser)
    }

}

extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

// MARK: - Setters

// Published variables must be altered on the main thread, and these wrappings facilitate that

extension AuthViewModel {

    func updateEmail(to newEmail: String) async {
        await MainActor.run {
            self.email = newEmail
        }
    }

    func updatePassword(to newPassword: String) async {
        await MainActor.run {
            self.password = newPassword
        }
    }

    func updatePasswordRepeat(to newPasswordRepeat: String) async {
        await MainActor.run {
            self.passwordRepeat = newPasswordRepeat
        }
    }

    func updateAcceptedTerms(to newAcceptedTerms: Bool) async {
        await MainActor.run {
            self.acceptedTerms = newAcceptedTerms
        }
    }

    func updateFirstName(to newFirstName: String) async {
        await MainActor.run {
            self.firstName = newFirstName
        }
    }

    func updateLastName(to newLastName: String) async {
        await MainActor.run {
            self.lastName = newLastName
        }
    }

    func updateErrorMessage(to newErrorMessage: String) async {
        await MainActor.run {
            self.errorMessage = newErrorMessage
        }
    }

    func updateUser(to newUser: User?) async {
        await MainActor.run {
            self.user = newUser
        }
    }

    func updateAuthenticationState(to newState: AuthenticationState) async {
        await MainActor.run {
            self.authenticationState = newState
        }
    }

    func updateAuthenticationType(to newType: AuthenticationType) async {
        await MainActor.run {
            self.authenticationType = newType
        }
    }
}
