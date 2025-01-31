//
//  SplashScreenView.swift
//  EventPass
//
//  Created by Andrew A on 27/07/2024.
//

import SwiftUI
import Firebase

struct SplashScreenView: View {
    // the first view upon launching the app
    // contains many initialisation processes, including internet connection, authentication, and event retrieval (in that order)
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var networkViewModel: NetworkViewModel = NetworkViewModel()
    @StateObject var eventViewModel: EventJoinViewModel = EventJoinViewModel(event: nil, eventCode: nil)
    @State private var isShown = true
    
    // visual animation related variables
    @State private var opacity = 0.5
    @State private var size = 0.8
    private let minimumWait = 1.0
    private let animationTime = 1.2
    

    var body: some View {
        if !isShown {
            WelcomeView(eventViewModel: eventViewModel)
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
                        try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(minimumWait))
                            await authViewModel.checkAuthenticationState()
                          
                    
                    }
                }
            }
            
            .onChange(of: authViewModel.authenticationState) {_, newValue in
                if newValue == .authenticated {
                    Task {
                        // attempt to fetch the user's card before joining an event
                        if let id = AuthViewModel.getUserId(), let card = await CardViewModel.retrieveCardIfExists(userID: id) {
                            eventViewModel.userCard = card
                        }
                        await eventViewModel.retrieveLocalStoredEvent()
                    }
                }
            }
            .onChange(of: eventViewModel.eventState) { _, newValue in
                if newValue == .joinedAndRetrieved || newValue == .notJoined {
                    withAnimation(.easeIn(duration: animationTime)) {
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
        else if authViewModel.authenticationState == .authenticating || authViewModel.authenticationState == .unauthenticated {
            Text("Authenticating....")
        } else if eventViewModel.eventState == .joinedAndRetrieving {
            Text("Retrieving Event...")
        } else {
            Text("Success!")
        }
        
    }

}




#Preview {
    SplashScreenView()
        .environmentObject(AuthViewModel())
}
