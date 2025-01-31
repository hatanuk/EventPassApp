//
//  AttendeeHubView.swift
//  EventPass
//
//  Created by Andrew A on 24/10/2024.
//

import SwiftUI
import CoreBluetooth
import FirebaseFirestore


struct AttendeeHubView: View {
    // view presented to regular attendees which have joined the event

    
    let tabs = [("Card Requests", "giftcard"),
        ("Who's nearby", "person.2.circle"),
        ("Saved Cards", "person.text.rectangle")
    ]
    
    @ObservedObject var BLEViewModel: BLEViewModel
    @State var event: EventModel
    @State var eventCode: String
    @State private var searchText = ""
    @State private var selectedTab = 1
    @State private var showLeaveConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    // Update timer to keep up-to-date with changing event configurations
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    
    // passed properties from parent HubView
    var leaveEvent: () -> Void
    var leaveEventAlert: Alert

    var body: some View {
        
        Button("Add Card Requests") {
            BLEViewModel.cardRequestsStack.append(Constants.testProfile3)
        }
        
        VStack {
            toggleTransmission
            
            if (selectedTab == 1) {
                NearbyTabView(profileStack: $BLEViewModel.discoveredUsers, searchText: $searchText, event: $event, BLEViewModel: BLEViewModel)
            } else if (selectedTab == 2) {
                SavedCardTabView(searchText: $searchText, BLEViewModel: BLEViewModel)
                    .onAppear{BLEViewModel.updateSavedCards()}
            } else if (selectedTab == 0) {
                CardRequestView(searchText: $searchText, BLEViewModel: BLEViewModel)
            }
            
            TabBarView(selectedTab: $selectedTab, tabs: tabs)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                header
                
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ToolbarCancelViewWithConfirmation(presentationMode, $showLeaveConfirmation)
                    .frame(width: 60)
                
            }
            
        }
        .alert(isPresented: $showLeaveConfirmation) {
                leaveEventAlert
                }
                .navigationBarBackButtonHidden(true)
                
        .padding(.top, 20)
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            EventJoinViewModel.storeEventLocally(code: eventCode)
        }
        .onChange(of: BLEViewModel.isTransmitting) {
            // ensure transmission can't be toggled on if disabled by event config
            if !event.eventConfig.transmissionsOn {
                BLEViewModel.isTransmitting = false
            }
        }
        .onReceive(timer) { _ in
            Task {
                print("updating")
                await updateEvent()
            }
        }
    }
    
    // for toggling BLE functionality
    var toggleTransmission: some View {
        Toggle(isOn: $BLEViewModel.isTransmitting) {
            Text("Currently Transmitting")
        }
        .disabled(!(event.eventConfig.transmissionsOn))
        
        .padding()
    }
    
    // this function runs periodically to reflect changed configurations and such. in case the event is not found during retrieval, the event has likely expired, and an exit is made.
    func updateEvent() async {
        do {
            self.event = try await FirebaseService.retrieveEvent(fromCode: eventCode)
        } catch let error as NSError {
            if error.domain == FirestoreErrorDomain, error.code == FirestoreErrorCode.notFound.rawValue {
                leaveEvent()
            }
        }
    }
    
    // appears on the top and gives info on event
    var header: some View{
            VStack {
                Text("\(event.title)")
                    .font(.headline)
                Text("Until \(formatDate(event.endDate))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                   
                    
            }
    }
    
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm',' MMM dd',' yyyy"
            return dateFormatter.string(from: date)
        }
    
}


struct NearbyTabView: View {
    
    @Binding var profileStack: [UserModel]
    @Binding var searchText: String
    @Binding var event: EventModel
    @State var showUser: Bool = false
    @State var focusedUser: UserModel? = nil
    @ObservedObject var BLEViewModel: BLEViewModel
    
    var body: some View {
        
        SearchBarView($searchText)
        
        ZStack {
            ScrollView {
                VStack(spacing: 10) {
                    if BLEViewModel.isTransmitting {
                    // only show nearby users if transmissions are on
                        ForEach(filteredUsers(searchText, userStack: profileStack)) { user in
                            ProfileView(user: user)
                                .onTapGesture {
                                    showUser = true
                                    focusedUser = user
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if showUser {
                
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showUser = false
                        focusedUser = nil
                    }
                    .zIndex(1)
                userInfo(user: focusedUser, BLEViewModel: BLEViewModel, showUser: $showUser, focusedUser: $focusedUser)
                    .zIndex(2)
                
                
            }
        }
        .animation(.easeInOut, value: showUser)
        
        
    }
}


struct SavedCardTabView: View {
    
    @Binding var searchText: String
    @State var showCard: Bool = false
    @State var focusedCard: CardModel? = nil
    @ObservedObject var BLEViewModel: BLEViewModel

    
    var body: some View {
        
        SearchBarView($searchText)
        
        ZStack {
            
            VStack {
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredCards(searchText, cardStack: BLEViewModel.savedCardsStack)) { card in
                          
                            ProfileView(user: UserModel(fromCard: card))
                                .onTapGesture {
                                    showCard = true
                                    focusedCard = card
                                       
                                }
                                .zIndex(0)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            if showCard {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showCard = false
                        focusedCard = nil
                    }
                    .zIndex(1)
                cardInfo(card: focusedCard)
                    .zIndex(2)
                
            }
            
            
        }
        .animation(.easeInOut, value: showCard)
        .onAppear {
            BLEViewModel.updateSavedCards()
        }
        
        
    }
    


}

struct CardRequestView: View {
    
    @Binding var searchText: String
    @State var showCard: Bool = false
    @State var focusedCard: CardModel? = nil
    @State var showSendBackCard = false
    @ObservedObject var BLEViewModel: BLEViewModel
    
    var body: some View {
        SearchBarView($searchText)
        ZStack{
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredCards(searchText, cardStack: BLEViewModel.cardRequestsStack)) { card in
                            
                            ProfileView(user: UserModel(fromCard: card))
                                .onTapGesture {
                                    showCard = true
                                    focusedCard = card
                                       
                                }
                                .zIndex(0)
                            
                        }
                    }
                    .padding(.horizontal)
                }
            }
            if showCard {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showCard = false
                        focusedCard = nil
                    }
                    .zIndex(1)
                    cardInfo(card: focusedCard, interaction:  AnyView(requestOptions(card: focusedCard)))
                    .zIndex(2)
                
            }
        }
        .animation(.easeInOut, value: showCard)
        .alert(isPresented: $showSendBackCard) {
            Alert(title: Text("Send back card?"), message: Text("Would you like to send your own card back to this user?"), primaryButton: .default(Text("Yes")) {
                Task {
                    BLEViewModel.sendCardRequest(to: UserModel(fromCard: focusedCard!))
                }
            }, secondaryButton: .cancel())
        }
    }
    
    func requestOptions(card: CardModel?) -> some View {
        VStack{
            if let card = card {
                Button {
                    BLEViewModel.addCardToLocalDB(card)
                    showSendBackCard = true
                    showCard = false
                    focusedCard = nil
                    BLEViewModel.cardRequestsStack.removeAll(where: {$0 == card})
                } label: {
                    Text("Accept and save card")
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
     
}

struct userInfo: View {
    
    var user: UserModel?
    @ObservedObject var BLEViewModel: BLEViewModel
    @Binding var showUser: Bool
    @Binding var focusedUser: UserModel?
    
    var body: some View {
        
        VStack {
            if let user = user {
                ProfileView(user: user)
                Button {
                    Task {
                        BLEViewModel.sendCardRequest(to: user)
                    }
                    showUser = false
                    focusedUser = nil
                } label: {
                    Text("Send your card!")
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .frame(maxWidth: 300)
    }
    
}

struct cardInfo: View {
    
    var card: CardModel?
    var interaction: AnyView?
    
    var body: some View {
        
        VStack {
            if let card = card {
       
                CardView(card: card)
                if let interaction = interaction {
                    interaction
                }
            }
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .frame(maxWidth: 300)
    }
}




struct SearchBarView: View {
    @Binding var searchText: String
    
    init(_ searchText: Binding<String>) {
        self._searchText = searchText
    }
    var body: some View {
      
        TextField("Search", text: $searchText)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    
    }
}

// these two functions are used for filtering by search text
func filteredUsers(_ searchText: String, userStack: [UserModel]) -> [UserModel] {
    if searchText.isEmpty {
        return userStack
    } else {
        return userStack.filter { $0.displayName?.localizedCaseInsensitiveContains(searchText) ?? false}
    }
}

func filteredCards(_ searchText: String, cardStack: [CardModel]) -> [CardModel] {
    if searchText.isEmpty {
        return cardStack
    } else {
        return cardStack.filter { $0.displayName?.localizedCaseInsensitiveContains(searchText) ?? false}
    }
}


#Preview {
    NavigationStack {
        VStack{
            AttendeeHubView(BLEViewModel: BLEViewModel(userCard: Constants.testProfile3), event: Constants.testEvent, eventCode: "12345", leaveEvent: {}, leaveEventAlert: testLeaveEventAlert)
        }
    }
}
