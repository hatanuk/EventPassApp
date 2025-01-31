//
//  ContentView.swift
//  EventPass
//
//  Created by Andrew A on 03/06/2024.
//

import SwiftUI
import SwiftData

struct WelcomeView: View {
    // serves as the main hub for event joining, creation, account management and card creation
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var eventViewModel: EventJoinViewModel
    
    @State private var eventCode = ""
    @State private var showHelp = false
    @State private var showProgressView = false
    @State private var storedValue: String = ""
    
    var body: some View {
        NavigationStack(path: $eventViewModel.navigationPath) {
            WelcomeViewInterface
        }
        .navigationBarBackButtonHidden(true)
        
        
    }
    
    var WelcomeViewInterface: some View {
        VStack {
            FlavorTextView
            EventInputView
            EventCreatorView
            AccountInfoView
            if showProgressView {
                ProgressView()
            }
            
        }
        .navigationBarItems(
            leading: CardIconView,
            trailing: HelpIconView
        )
        .sheet(isPresented: $showHelp) {
            HelpView
        }
        // code relating to the automatic joining of events
        .navigationDestination(for: EventModel.self) { event in
            
            if let card = eventViewModel.userCard {
                HubView(BLEViewModel: BLEViewModel(userCard: card), eventViewModel: eventViewModel)
                    .id(event)
            } else {
                EmptyView().onAppear {
                    eventViewModel.removeEvent()
                }
            }
        }
        .onAppear {
            if let event = eventViewModel.event {
                print("current event: \(event.title)")
            }
            
        }
        .navigationBarBackButtonHidden(true)
    }
    
    
    
    
    var EventCreatorView: some View {
        Group {
            if let user = authViewModel.user, !user.isAnonymous {
                HStack {
                    Text("Or")
                    
                    NavigationLink(
                        destination: {
                            if eventViewModel.userCard != nil {
                                EventCreationView(userID: user.uid, eventJoinViewModel: eventViewModel)
                            }
                        },
                        label: {
                            Text("create your own")
                        }
                    )
                    .simultaneousGesture(TapGesture().onEnded {
                        // ensures the user has a card prepared, required to navigate to event later
                        Task {
                            await eventViewModel.prepareCard()
                        }
                    })
                }
                .padding(.vertical, -40)
                .font(.headline)
            } else {
                EmptyView()
            }
        }
        
        
    }
    
    
    var HelpIconView: some View {
        Button(action: {
            showHelp.toggle()
        }) {
            Image(systemName: "questionmark.circle")
                .font(.title)
                .foregroundColor(.blue)
        }
        .padding()
    }
    
    var CardIconView: some View {
        NavigationLink(destination: CardCreationView()) {
            Image(systemName: "person.text.rectangle.fill")
                .font(.title)
                .foregroundColor(.blue)
        }
        .padding()
    }
    
    var FlavorTextView: some View {
        VStack(spacing: 20) {
            Text("Welcome.")
                .font(.custom("Freehand", size: 60))
                .fontWeight(.semibold)
            
            Text("Looking to join an event?")
                .font(.system(size: 30))
        }
        .padding(.top, 50)
    }
    
    var NoLoginOptions: some View {
        VStack {
            Text("Not logged in")
                .foregroundColor(.gray)
                .padding(.bottom, 3)
            HStack {
                NavigationLink(destination: SignUpView()) {
                    Text("Sign up")
                        .foregroundColor(.blue)
                }
                
                Text("or")
                    .foregroundColor(.gray)
                
                NavigationLink(destination: LogInView()) {
                    Text("log in")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    var LoggedInOptions: some View {
        VStack {
            if let email = authViewModel.user?.email {
                Text("Logged in as: \(email)")
                    .foregroundColor(.gray)
                    .padding(.bottom, 3)
            }
            Button("Log out") {
                withProgressView {
                    await authViewModel.signOut()
                }
            }
        }
    }
    
    var AccountInfoView: some View {
        Group {
            if let user = authViewModel.user, !user.isAnonymous {
                LoggedInOptions
            } else {
                NoLoginOptions
            }
            
        }
        .scaleEffect(1.2)
        .padding(.horizontal, 35)
        .padding(.bottom, 0)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    
    var HelpView: some View {
        VStack {
            Text("Help Information")
                .font(.largeTitle)
                .padding()
            
            Text("Here you can provide detailed help information for the users.")
                .padding()
            
            Spacer()
            Button("Dismiss") {
                showHelp.toggle()
            }
            .scaleEffect(1.2)
        }
        .padding()
    }
    
    var EventInputView: some View {
        VStack {
            TextField("", text: $eventCode)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .scaleEffect(1.7)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.blue),
                    alignment: .bottom
                )
                .keyboardType(.numberPad)
                .onChange(of: eventCode) { oldValue, newValue in
                    var filtrate = newValue.filter { "0123456789".contains($0) }
                    
                    if filtrate.count > EventModel.EVENT_CODE_LENGTH {
                        filtrate = String(filtrate.prefix(EventModel.EVENT_CODE_LENGTH))
                    }
                    
                    eventCode = filtrate
                }
                .onSubmit {
                    withProgressView {
                        await onSubmit()
                    }
                }
            
            Text("Enter the event code above")
                .foregroundColor(.gray)
                .font(.caption)
                .scaleEffect(1.5)
                .padding(.top, 10)
            
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
        .alert(isPresented: $eventViewModel.showEventAlert) {
            print("alert message: \(eventViewModel.eventAlertMessage)")
            return Alert(
                title: Text("Error"),
                message: Text(eventViewModel.eventAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func onSubmit() async {
        await eventViewModel.attemptJoinEvent(code: eventCode)
    }

            
        
    
    // helper functions
    private func withProgressView(task: @escaping () async -> Void) {
        showProgressView.toggle()
        Task {
            await task()
            showProgressView.toggle()
        }
    }
    
    }
    
   


#Preview {
    WelcomeView(eventViewModel: EventJoinViewModel(event: nil, eventCode: nil))
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(AuthViewModel())
}
