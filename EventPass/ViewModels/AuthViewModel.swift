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
    case passwordMismatch, invalidEmail, shortPassword, weakPassword, emailInUse
}

class AuthViewModel: ObservableObject {
    // handles authentication-related logic with Firebase Auth
    
    // minimum amount of characters for a valid password
    let MIN_PASS_LENGTH = 8
    let defaultErrorMessage = "The operation was unsuccessful, please try again later"
     
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
    

    private func validateSignUp() throws {
        // ensures details are within the required parameters
        
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
            try FirebaseService.signOut()
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
    
    static func getUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func getAlias() async -> String? {
        if let id = AuthViewModel.getUserId() {
            return try? await FirebaseService.retrieveAlias(fromID: id)
        } else {
            return nil
        }
    }
    
    func signUpEmailPassword() async -> Bool {
        // signing up
        
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
            // validation
            try validateSignUp()
            
            let authResult = try await FirebaseService.signUp(email: email, password: password, user: user)
            await updateUser(to: authResult.user)
            try await saveNewUserDetails(userId: authResult.user.uid, firstName: currentFirstName, lastName: currentLastName)
            try await FirebaseService.mapIDToEmail(userId: authResult.user.uid, email: email)
            print("SIGNUP FROM: \(authResult.user.uid)")
            return true
            
        }
        
        catch SignUpError.invalidEmail {
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
        } catch SignUpError.emailInUse {
            await updateErrorMessage(to: "Email is already in use, please try another one.")
            return false
        } catch {
            await updateErrorMessage(to: defaultErrorMessage)
            print("SIGNUP ERROR: \(error)")
            return false
        }
    }
    
    func signInAnonymously() async -> Bool {
        // this occurs for fresh users, providing them with an alias mapping and clearing previous UserDefault caches
        
        guard Auth.auth().currentUser == nil || Auth.auth().currentUser?.isAnonymous == false else {
            await updateUser(to: Auth.auth().currentUser)
        
            print("Already signed in as anonymous user: \(Auth.auth().currentUser?.uid ?? "")")
            return true
          }
        
        CardViewModel.deleteLocalCard()
        
        do {
            let authResult = try await FirebaseService.signInAnonymously()
            try await FirebaseService.mapAliasToID(userID: authResult.user.uid)
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
        // logging in
        
        guard let user = user, user.isAnonymous else {
            await updateErrorMessage(to: "Already signed in!")
            return false
        }
        
        do {
            let authResult = try await FirebaseService.signIn(email: email, password: password)
            await updateUser(to: authResult.user)
            print("LOGIN FROM: \(authResult.user.uid)")
            return true
            
        } catch let error as NSError {
            if error.code == AuthErrorCode.invalidCredential.rawValue {
                await updateErrorMessage(to: "Incorrect user/password combination")
            } else if error.code == AuthErrorCode.invalidEmail.rawValue ||  error.code == AuthErrorCode.missingEmail.rawValue{
                await updateErrorMessage(to: "Please enter a valid email.")
            } else {
                await updateErrorMessage(to: "Unable to log in. Please try again later.")
                print("Unexpected error: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    func signOut() async -> Bool {
        do {
            clearAllUserDefaults()
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
        
        if Auth.auth().currentUser != nil {
            print("already authenticaed")
            await updateUser(to: Auth.auth().currentUser)
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
    
    private func clearAllUserDefaults() {
        // clears all user defaults upon signout
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        UserDefaults.standard.synchronize()
    }
    
    
    private func saveNewUserDetails(userId: String, firstName: String, lastName: String) async throws {
        let alias = try await FirebaseService.retrieveAlias(fromID: userId)
        let newUser = CardModel(id: userId, alias: alias, firstName: firstName, lastName: lastName)
        try await FirebaseService.save(card: newUser)
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
