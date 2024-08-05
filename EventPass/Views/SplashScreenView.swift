//
//  SplashScreenView.swift
//  EventPass
//
//  Created by Andrew A on 27/07/2024.
//

import SwiftUI
import Network
import Firebase

struct SplashScreenView: View {
    @State private var isConnected = false
    @State private var isAuthenticated = false
    @State private var isActive = true
    
    // visual animation related variables
    @State private var opacity = 0.5
    @State private var size = 0.8
    
    private let minimumWait = 2.0
    private let animationTime = 1.2

    var body: some View {
        if !isActive {
            WelcomeView()
        } else {
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                TextBlurb
            }
            .opacity(opacity)
            .scaleEffect(size)
            
            .onAppear {
                withAnimation(.spring(duration: animationTime)) {
                    self.opacity = 1.0
                    self.size = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + minimumWait) {
                    checkInternetConnection()
                }
                
                
            }
            .onChange(of: isConnected) { _, newValue in
                if newValue {
                    checkAuthenticationState()
                }
            }
            
            .onChange(of: isAuthenticated) {_, newValue in
                if newValue {
                    withAnimation(.easeIn(duration: animationTime)){
                        isActive = false
                    }
                }
            }
        }
    }
    
    var TextBlurb: some View {
        
        if !isConnected {
            Text("Connecting...")
        }
        else if !isAuthenticated {
            Text("Authenticating....")
        } else {
            Text("Success!")
        }
        
    }

    func checkInternetConnection() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectionMonitor")
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    isConnected = true
                } else {
                    isConnected = false
                }
            }
        }
        monitor.start(queue: queue)
    }

    func checkAuthenticationState() {
        isAuthenticated = true
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        } else {
            loginAnonymously()
        }
    }

    func loginAnonymously() {
        Auth.auth().signInAnonymously() { authResult, error in
            if let error = error {
                print("Error logging in anonymously: \(error)")
                return
            }
            isAuthenticated = true
        }
    }
}




#Preview {
    SplashScreenView()
}
