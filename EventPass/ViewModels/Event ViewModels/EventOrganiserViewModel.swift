//
//  EventOrganiserViewModel.swift
//  EventPass
//
//  Created by Andrew A on 25/10/2024.
//

import Foundation
import FirebaseFirestore


enum EventDeletionError: Error {
    case userIdAuthenticationFailure
}


@MainActor
class EventOrganiserViewModel: ObservableObject {
    // handles the management of an event by organisers
    
    @Published var event : EventModel
    @Published var eventCode : String
    @Published var isEventCreator: Bool
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var userID: String
    
    init(event: EventModel, eventCode: String, userID: String, isEventCreator: Bool) {
        self.event = event
        self.eventCode = eventCode
        self.isEventCreator = isEventCreator
        self.userID = userID
    }
    
    
    func refreshEvent() async -> Bool {
        // fetches updated event details from Firestore
        do {
            event = try await FirebaseService.retrieveEvent(fromCode: eventCode)
            return true
        } catch FirestoreErrorCode.unavailable {
            // if check can't be performed due to connectivity issues, assume event still exists
            return true
        } catch {
            // event does not exist
            return false
        }
    }
    
    func saveConfigurations(transmissionsOn: Bool? = nil, bannedUser: Attendee? = nil) async {
        // pushes changed configs to Firestore
        
        if let transmissionsOn = transmissionsOn {
            event.eventConfig.transmissionsOn = transmissionsOn
        }
        if let bannedUser = bannedUser, !event.eventConfig.bannedUsers.contains(bannedUser) {
            event.eventConfig.bannedUsers.append(bannedUser)
            event.attendees.removeAll(where: {$0 == bannedUser})
        }
        
        do  {
            try await FirebaseService.save(event: event, id: eventCode)
        } catch {
            displayError(message: "Configurations could not be saved, please try again later.")
        }
        
    }
    
    func attemptEventDeletion() async -> Bool {
        // deletes the event from Firestore, only available for the event creator

        do {
            guard let userId = AuthViewModel.getUserId(), userId == event.eventHierarchy.eventCreator else {
                throw EventDeletionError.userIdAuthenticationFailure
            }
            try await FirebaseService.deleteEvent(eventCode: eventCode)
        } catch {
            displayError(message: "Event deletion could not be completed.")
            return false
        }
        EventJoinViewModel.deleteLocalStoredEvent()
        return true
    }
    
    private func displayError(message: String) {
        errorMessage = message
        showError = true
    }
    
    
}
