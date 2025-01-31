//
//  OrganiserHubView.swift
//  EventPass
//
//  Created by Andrew A on 24/10/2024.
//

import SwiftUI
import CoreBluetooth

struct OrganiserHubView: View {
    // view presented to event organisers which have joined the event
    
    let tabsMain = [("Attendee Info", "person.2.circle"),
                ("Configurations", "gearshape")]
    
    @StateObject var eventViewModel: EventOrganiserViewModel
    
    @State var connectedUsersStack: [Attendee] = []
    @State var transmissionsStack: [CardModel] = []
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    
    
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var selectedAttendeeTab = 0
    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    // for readability
    private var event: EventModel {
           eventViewModel.event
       }
    private var eventCode: String {
        eventViewModel.eventCode
       }
    
    // passed properties from parent HubView
    var leaveEvent: () -> Void
    var leaveEventAlert: Alert
    
    
    
    var body: some View {
        VStack {
          
            if (selectedTab == 0) {
                AttendeesTabView(connectedUsersStack: $connectedUsersStack, transmissionsStack: $transmissionsStack, searchText: $searchText, selectedAttendeeTab: $selectedAttendeeTab, eventViewModel: eventViewModel, updateData: updateData)
            } else if (selectedTab == 1) {
                EventSettingsTabView(eventViewModel: eventViewModel, showDeleteConfirmation: $showDeleteConfirmation, deleteEvent: deleteEvent)
            }
            
            TabBarView(selectedTab: $selectedTab, tabs: tabsMain)
                .frame(alignment: .bottom)
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
        .padding(.top, 20)
        .onAppear {
            EventJoinViewModel.storeEventLocally(code: eventViewModel.eventCode)
            updateData()
        }
        .onReceive(timer) { _ in
            print("its update time")
                           updateData()
                       }
        .navigationBarBackButtonHidden(true)
     
    
        // alert handling
        .alert(isPresented: Binding(get: {
            showDeleteConfirmation || eventViewModel.showError || showLeaveConfirmation
        }, set: { newValue in
            showDeleteConfirmation = newValue
            eventViewModel.showError = newValue
            showLeaveConfirmation = newValue
        })) {
            if showDeleteConfirmation {
                return Alert(
                    title: Text("Delete Event"),
                    message: Text("Are you sure you want to delete the event? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete"), action: deleteEvent),
                    secondaryButton: .cancel()
                )
            } else if eventViewModel.showError {
                return Alert(
                    title: Text("Error"),
                    message: Text(eventViewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return leaveEventAlert
            }
        }

    }
    
    var header: some View {
        VStack {
            Text("\(event.title)")
                .font(.headline)
            Text("Until \(formatDate(event.endDate))")
                .font(.subheadline)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm',' MMM dd',' yyyy"
        return dateFormatter.string(from: date)
    }
    
    private func deleteEvent() {
        var success: Bool = false
        Task {
            success = await eventViewModel.attemptEventDeletion()
        }
        if success {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func updateData() {
      
        Task {
            if await !eventViewModel.refreshEvent() {
                print("event just stopped existing")
                leaveEvent()
            }
        }
        
        connectedUsersStack = event.attendees
        transmissionsStack = event.attendees.map{$0.card}
    }
  
}

struct AttendeesTabView: View {
    
    let tabsAttendee = [("Transmissions", "person.text.rectangle"),
                ("Connected Users", "person")]
    
    @Binding var connectedUsersStack: [Attendee]
    @Binding var transmissionsStack: [CardModel]
    @Binding var searchText: String
    @Binding var selectedAttendeeTab: Int
    @StateObject var eventViewModel: EventOrganiserViewModel
    var updateData: () -> Void
    
    private var event: EventModel {
           eventViewModel.event
       }
    private var eventCode: String {
        eventViewModel.eventCode
       }
    
    var body: some View {
        
        Button(action: {
            Task {
                let attendee = try? await EventJoinViewModel.createAttendeeModel(userID: "BQKO55THO3YkvvD2AEQz8fuHulq1", eventCode: eventViewModel.eventCode)
                if let attendee = attendee {
                    try? await FirebaseService.addAttendeeToEvent(attendee, eventCode: eventViewModel.eventCode)
                }
            }
        }) {
            Text("Add attendee")
            
        }
        
        Button(action: {
            Task {
                try? await FirebaseService.removeAllAttendees(eventCode: eventViewModel.eventCode)
            }
        }) {
            Text("Remove all")
        }
        TabBarView(selectedTab: $selectedAttendeeTab, tabs: tabsAttendee)
        SearchBarView($searchText)
        
        if selectedAttendeeTab == 0 {
            // Transmissions tab //
            ScrollView {
                VStack(spacing: 0) {
                    
                    ForEach(filteredTransmissions, id: \.self) { transmission in
                    
                        return GroupBox(label: Text(transmission.alias)) {
                            CardView(card: transmission)
                        }
                        
                    }
                }
                .padding(.horizontal)
            }
            
        } else {
            // Connected users tab //
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredUsers, id: \.self) { attendee in
                        AttendeeView(eventViewModel: eventViewModel, connectedUsersStack: $connectedUsersStack, attendee: attendee, updateData: updateData)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var filteredUsers: [Attendee] {
        if searchText.isEmpty {
            return connectedUsersStack
        } else {
            return connectedUsersStack.filter { $0.alias.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var filteredTransmissions: [CardModel] {
        if searchText.isEmpty {
            return transmissionsStack
        } else {
            return transmissionsStack.filter {_ in 
                true
            }
        }
    }
}

struct EventSettingsTabView: View {
    
    @State private var allowAttendeeTransmission = true
    @StateObject var eventViewModel: EventOrganiserViewModel
    @Binding var showDeleteConfirmation: Bool
    var deleteEvent: () -> Void
    
    private var event: EventModel {
           eventViewModel.event
       }
    private var eventCode: String {
        eventViewModel.eventCode
       }

    
    var body: some View {
        Form {
            Section(header: Text("Event Code")) {
                Text(eventCode)
            }
            Section {
                Toggle(isOn: $allowAttendeeTransmission) {
                    Text("Allow Attendee Transmissions")
                } 
                Button(action: {
                    Task {
           
                        await eventViewModel.saveConfigurations(transmissionsOn: allowAttendeeTransmission)
                    }
                }) {
                    Text("Save Changes")
                }
            }
        
            if eventViewModel.isEventCreator {
                Section {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Event").foregroundColor(.red)
                    }
                }
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            return Alert(
                title: Text("Delete Event"),
                message: Text("Are you sure you want to delete the event? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                   deleteEvent()
                },
                secondaryButton: .cancel()
            )
        }
        
    }
}



struct AttendeeView: View {
    @StateObject var eventViewModel: EventOrganiserViewModel
    @State var banConfirmationShown = false
    @Binding var connectedUsersStack: [Attendee]
    let attendee: Attendee
    var updateData: () -> Void
    
    
    var body: some View {
        HStack {
            Text(attendee.alias)
            Spacer()
            Button(action: {
                    banConfirmationShown = true
            }) {
                Text("Ban").foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .alert("Are you sure?", isPresented: $banConfirmationShown) {
            Button("Ban User", role: .destructive) {
                onBan()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove this user from the event.")
        }
    }
    
    private func onBan() {
        print("Trying to ban \(attendee.id)")
        connectedUsersStack = connectedUsersStack.filter() { $0.id != attendee.id }
        Task {
            await eventViewModel.saveConfigurations(bannedUser: attendee)
        }
    }
    
}

var testLeaveEventAlert =  Alert(
    title: Text("Leave Event"),
    message: Text("Are you sure you want to leave the event? This action cannot be undone."),
    primaryButton: .destructive(Text("Leave")) {
        // this would call leaveEvent in the real alert
    },
    secondaryButton: .cancel()
)

#Preview {
    NavigationStack {
        OrganiserHubView(eventViewModel: EventOrganiserViewModel(event: Constants.testEvent, eventCode: "123456", userID: "243432", isEventCreator: true), leaveEvent: {}, leaveEventAlert: testLeaveEventAlert)
    }
}
