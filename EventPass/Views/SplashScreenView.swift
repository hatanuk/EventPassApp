//
//  SplashScreenView.swift
//  EventPass
//
//  Created by Andrew A on 27/07/2024.
//

import SwiftUI
import Firebase

struct SplashScreenView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var networkViewModel: NetworkViewModel = NetworkViewModel()

    @State private var isShown = true

    // visual animation related variables
    @State private var opacity = 0.5
    @State private var size = 0.8
    
    private let minimumWait = 2.0
    private let animationTime = 1.2

    var body: some View {
        if !isShown {
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
                
                // DispatchQueue is here to purposefully delay the loading sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + minimumWait) {
                    networkViewModel.checkInternetConnection()
                }
                
                
            }
            .onChange(of: networkViewModel.connectionState) { _, newValue in
                if newValue == .connected {
                    Task {
                        await authViewModel.checkAuthenticationState()
                    }
                }
            }
            
            .onChange(of: authViewModel.authenticationState) {_, newValue in
                
                if newValue == .authenticated {
                    withAnimation(.easeIn(duration: animationTime)){
                        isShown = false
                    }
                }
            }
        }
    }
    
    var TextBlurb: some View {
        
        if networkViewModel.connectionState == .connecting {
            Text("Connecting...")
        }
        else if authViewModel.authenticationState == .authenticating {
            Text("Authenticating....")
        } else {
            Text("Success!")
        }
        
    }

}




#Preview {
    SplashScreenView()
        .environmentObject(AuthViewModel())
}
