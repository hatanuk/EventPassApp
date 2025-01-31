//
//  EventModel.swift
//  EventPass
//
//  Created by Andrew A on 12/09/2024.
//

import Foundation
import SwiftUI

enum EventState {
    case notChecked
    case notJoined
    case joinedAndRetrieving
    case joinedAndRetrieved
}

@MainActor
class EventJoinViewModel: ObservableObject {
    // handles the logic and validation surrounding the joining of an event
    
    @Published var event : EventModel?
    @Published var eventCode : String?
    @Published var navigationPath = NavigationPath()
    @Published var eventState: EventState = .notChecked
    @Published var eventAlertMessage = ""
    @Published var showEventAlert = false
    @Published var isOrganiser: Bool = false
    @Published var isEventCreator: Bool = false
    @Published var userCard: CardModel? = nil
    
    let defaultErrorMessage = "Unable to join event. Please try again later."
    let cardErrorMessage = "Please make sure you have filled out your business card first. You may find the edit screen in the top left corner."
    let invalidCodeErrorMessage = "Please make sure the code is 6 digits long."
    let bannedErrorMessage = "You have been prevented from joining this event. Please contact the organisers to resolve this."
    let eventNotFoundErrorMessage = "Event was not found, please try a different code."

    
    init(event: EventModel?, eventCode: String?) {
        self.event = event
        self.eventCode = eventCode
    }
    
    
    func attemptJoinEvent(code: String) async {
        // check if code is valid, and whether an event associated with it exists
        
        if await prepareCard() {
            // ensures that the user has a sufficiently filled out business card
            
            if EventJoinViewModel.validateEvent(code: code) {
                // event is valid, retrieve it (show alert in case of failure)
                if await retrieveEvent(withCode: code) {
                    
                    guard let event = event, let eventCode = eventCode else {
                        print("issue with accessing event, eventCode")
                        displayError(message: defaultErrorMessage)
                        return
                    }
                    
                    // check if user is banned from event
                    if isUserBanned(event: event) {
                        self.eventCode = nil
                        self.event = nil
                        print("user is banned")
                        displayError(message: bannedErrorMessage)
                        return
                    }
                    
                    // checks if user is an organiser within an event by checking it with Firestore
                    do {
                        isOrganiser = try await isUserOrganiser()
                        isEventCreator = try await isUserEventCreator()
                    } catch {
                        print("issue checking organiser status")
                        displayError(message: defaultErrorMessage)
                        return
                    }
                    
                    if !isOrganiser {
                        print("NOT ORGANISER")
                        do {
                            guard let userID = AuthViewModel.getUserId() else {
                                throw NSError()
                            }
                            let attendee = try await EventJoinViewModel.createAttendeeModel(userID: userID, eventCode: eventCode)
                                try await FirebaseService.addAttendeeToEvent(attendee, eventCode: eventCode)
                            
                        } catch {
                            print("issue creating and saving attendee model")
                            displayError(message: defaultErrorMessage)
                            return
                        }
                    }
                    
                    // finally, navigate to HubView
                    updateNavigationPath()
                    return
                    
                    
                } else {
                    print("not an active event")
                    displayError(message: eventNotFoundErrorMessage)
                    return
                }
            } else {
                displayError(message: invalidCodeErrorMessage)
                return
            }
        }
    }
    
    static func createAttendeeModel(userID: String, eventCode: String) async throws -> Attendee {
        // fetches details using a user's ID to create an Attendee model
        print("about to retrieve")
        let alias = try await FirebaseService.retrieveAlias(fromID: userID)
        print("alias retrieved")
        guard let deviceID = getDeviceID() else {
            print("device error")
            throw NSError(domain: "DeviceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Device ID not available"])
        }
        let cardModel = try await CardModel(fromUserId: userID)
        print("card model created")
        
        return Attendee(eventId: eventCode, id: userID, alias: alias, deviceId: deviceID, joinDate: Date(), card: cardModel)
    }
    
    static func getDeviceID() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    
    private func isUserBanned(event: EventModel) -> Bool {
        var isBanned = false
        if let userID = AuthViewModel.getUserId() {
            if event.eventConfig.bannedUsers.contains(where: {$0.id == userID}) {
                isBanned = true
            }
            if let deviceID = EventJoinViewModel.getDeviceID(), event.eventConfig.bannedUsers.contains(where: {$0.deviceId == deviceID}) {
                print("DeviceID: \(deviceID)")
                isBanned = true
            }
        }
        return isBanned
    }
    
    private func isUserOrganiser() async throws -> Bool {
        if let userID = AuthViewModel.getUserId(), let eventCode = eventCode {
            return try await FirebaseService.checkIfUser(is: .eventOrganiser, userID: userID, eventCode: eventCode)
        } else {
            return false
        }
       
    }
    
    private func isUserEventCreator() async throws -> Bool {
        if let userID = AuthViewModel.getUserId(), let eventCode = eventCode {
            return try await FirebaseService.checkIfUser(is: .eventCreator, userID: userID, eventCode: eventCode)
        } else {
            return false
        }
    }
    
    func updateNavigationPath() {
        // Updates the navigation path by adding (or removing) an event from it
        // The navigation path generates a HubView with the associated event
            if let event = event {
                navigationPath = NavigationPath([event])
                print("Set navigationPath with event")
                print("\(navigationPath)")
            } else {
                navigationPath = NavigationPath()
                print("Cleared navigationPath")
            }
       }
    
    
    static func validateEvent(code: String) -> Bool {
        // checks whether the event code is in a valid format
        if code.count != EventModel.EVENT_CODE_LENGTH {
            return false
        }
       return true
    }
    
    func retrieveEvent(withCode code: String) async -> Bool {
        // retrieves an event and sets own properties accordingly
        var event : EventModel
        do {
            event = try await FirebaseService.retrieveEvent(fromCode: code)
            
            self.eventCode = code
            self.event = event

            return true

        } catch {
            print("error retrieving event")
            return false
        }
      
    }
    
    static func storeEventLocally(code: String) {
        // stores a joined event on-device to directly transition to upon launch
        
        guard EventModel.isValidCode(code) else {
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(code, forKey: "joinedEventCode")
        print("event stored locally: \(code)")
    }
    
    func retrieveLocalStoredEvent() async {
        // retrieves the event code from UserDefaults, if it exists, and attempts to fetch the event's details from Firestore
        
        // if the user's card isn't available, don't join the event
        if self.userCard == nil {
            eventState = .notJoined
            return
        }
        
        // sets Event property if one was joined and saved locally
        let defaults = UserDefaults.standard
        if let eventCode = defaults.string(forKey: "joinedEventCode"), EventModel.isValidCode(eventCode)  {
            eventState = .joinedAndRetrieving
            do {
                print("event code, fetching from FireBase: \(eventCode)")
                event = try await FirebaseService.retrieveEvent(fromCode: eventCode)
                self.eventCode = eventCode
                
                if let id = AuthViewModel.getUserId() {
                    if id == event?.eventHierarchy.eventCreator {
                        isEventCreator = true
                    } else if event?.eventHierarchy.eventOrganisers.contains(id) == true {
                        isOrganiser = true
                    }
                }
                
            } catch {
                // Event has likely expired, delete it from local storage
                print("error fetching local event: \(error)")
                EventJoinViewModel.deleteLocalStoredEvent()
            }
        } else {
            print("no event stored")
        }
        
        if event != nil {
            eventState = .joinedAndRetrieved
        } else {
            eventState = .notJoined
        }
        // adds the event to the navigation path
        updateNavigationPath()
    }

    static func deleteLocalStoredEvent() {
        // deletes the local event from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "joinedEventCode")
    }
    
    func removeEvent() {
        self.event = nil
        self.eventCode = nil
        updateNavigationPath()
    }
    
    func leaveEvent() async {
        // removes event code from UserDefault and removes the departing Attendee from Firestore
        // also stops event listener
        EventJoinViewModel.deleteLocalStoredEvent()
        BLEViewModel.clearSavedCards()
        
        do {
            if let userID = AuthViewModel.getUserId(), let eventCode = eventCode, isOrganiser == false && isEventCreator == false {
                try await FirebaseService.removeAttendeeFromEvent(attendeeID: userID, eventCode: eventCode)
            }
        } catch {
            return
        }
                
        
    }
    
    func prepareCard() async -> Bool {
        // retrieves a locally stored card, or fetches it from Firestore. returns true if one exists, false if not.
        
        if let userID = AuthViewModel.getUserId() {
            userCard = await CardViewModel.retrieveCardIfExists(userID: userID)
        }
        
        if userCard == nil {
            displayError(message: cardErrorMessage)
            return false
        } else {
            return true
        }
    }
    
    func displayError(message: String) {
        eventAlertMessage = message
        showEventAlert.toggle()
    }
    

    
}
