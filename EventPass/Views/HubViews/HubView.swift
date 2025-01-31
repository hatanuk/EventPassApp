//
//  AttendeeHubView.swift
//  EventPass
//
//  Created by Andrew A on 02/08/2024.
//

import SwiftUI
import CoreBluetooth



struct HubView: View {
    // transient view which is used for navigation to either OrganiserHubView or AttendeeHubView
    // contains initialisation logic as well as mutual components
    
    let tabs = [("Card Requests", "giftcard"),
                ("Who's nearby", "person.2.circle"),
                ("Saved Cards", "person.text.rectangle")
    ]
    
    @ObservedObject var BLEViewModel: BLEViewModel
    @ObservedObject var eventViewModel: EventJoinViewModel
    @Environment(\.presentationMode) var presentationMode
    

    var body: some View {
        if let userID = AuthViewModel.getUserId(), let event =  eventViewModel.event, let eventCode = eventViewModel.eventCode {
            if eventViewModel.isOrganiser ||  eventViewModel.isEventCreator {
                OrganiserHubView(eventViewModel: EventOrganiserViewModel(event: event, eventCode: eventCode, userID: userID, isEventCreator: eventViewModel.isEventCreator), leaveEvent: leaveEvent, leaveEventAlert: leaveEventAlert)
            } else {
                AttendeeHubView(BLEViewModel: BLEViewModel, event: event, eventCode: eventCode, leaveEvent: leaveEvent, leaveEventAlert: leaveEventAlert)
            }
            
        } else {
           
            Text("Error authenticating. Please exit event.")
                .onAppear {
                    EventJoinViewModel.deleteLocalStoredEvent()
                }
            
        }
        
      
    }
    
    
    // mutual views/functions that are used by both types of views
    var leaveEventAlert: Alert {
        Alert(
            title: Text("Leave Event"),
            message: Text("Are you sure you want to leave the event?"),
            primaryButton: .destructive(Text("Leave")) {
                leaveEvent()
            },
            secondaryButton: .cancel()
        )
    }
    
    private func leaveEvent() {
            Task {
                await eventViewModel.leaveEvent()
            }
        
            presentationMode.wrappedValue.dismiss()
        }
}
   
