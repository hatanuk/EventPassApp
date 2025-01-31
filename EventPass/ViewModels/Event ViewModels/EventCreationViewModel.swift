//
//  Event.swift
//  EventPass
//
//  Created by Andrew A on 02/08/2024.
//

import Foundation
import Firebase
import SwiftData


enum OrganiserRetrievalError: Error {
    case failedAtEmail(String, Int, Error)
}


@MainActor
class EventCreationViewModel: ObservableObject {
    // handles the creation of an event
    
     var event: EventModel? = nil
        
     @Published var creatorID: String
     @Published var currentStep: Int = 1
     @Published var title: String = ""
     @Published var startDate: Date = Date()
     @Published var endDate: Date = Date()
     @Published var organisers: [String] = []
     @Published var organiserEmail: String = ""
     @Published var allowBusinessCards: Bool = true
     @Published var acceptTerms: Bool = false
     @Published var isSubmitting: Bool = false
     @Published var showSuccess: Bool = false
     @Published var eventCode: String = ""
    
    init(creatorID: String) {
        self.creatorID = creatorID
    }
    
    
     // error handling
     let defaultErrorMessage = "The event creation was not successful, please try again later"
     @Published var showError: Bool = false
     @Published var errorMessage: String = ""
     
    
    func nextStep() async {
        if isCurrentStepValid() {
            switch currentStep {
                case 1:
                    currentStep += 1
                case 2:
                if validateDate() {
                    currentStep += 1
                }
                case 3:
                if await validateOrganisers() {
                    currentStep += 1
                }
                case 4:
                    currentStep += 1
                case 5:
                    currentStep += 1
                default:
                    break
                }
            }
        }
      
      func previousStep() {
          if currentStep > 1 {
              currentStep -= 1
          }
      }
    
    func isCurrentStepValid() -> Bool {
            switch currentStep {
            case 1:
                // title entry
                return title.count >= Constants.MIN_EVENT_TITLE_LENGTH && title.count <= Constants.MAX_EVENT_TITLE_LENGTH
            case 2:
                // date selection
                return startDate < endDate
            case 3:
                // organizer entry
                return true
            case 4:
                // configurations
                return true
            case 5:
                // review
                return acceptTerms
            default:
                return false
            }
        }
    
    func removeOrganiser(_ organiser: String) {
          organisers.removeAll { $0 == organiser }
      }
    
    func validateDate() -> Bool {
        let calendar = Calendar.current
        if let dayDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day {
            if dayDifference < Constants.MIN_EVENT_DAYS {
                displayError(message: "Event must last at least \(Constants.MIN_EVENT_DAYS) day\((Constants.MIN_EVENT_DAYS > 1) ? "s" : "")")
                return false
           } else if dayDifference > Constants.MAX_EVENT_DAYS {
                displayError(message: "Event must last less than \(Constants.MAX_EVENT_DAYS) days")
               return false
           } else {
               return true
           }
            
        }
        displayError(message: defaultErrorMessage)
        return false
    }
    
    func displayError(message: String) {
        errorMessage = message
        showError = true
    }

    
    func validateOrganisers() async -> Bool {
        
        let allEmailsValid = organisers.allSatisfy{$0.isValidEmail}
        guard allEmailsValid else {
            displayError(message: "Please make sure all emails are valid")
            return false
        }
        
        
        do {
            let organiserIDs = try await retrieveOrganiserIDs()
            if organiserIDs.contains(creatorID) {
                displayError(message: "You can't yourself as an organiser again. You're already one!")
                return false
            }
        } catch {
            switch error {
                case OrganiserRetrievalError.failedAtEmail(let email, let index, let error):
                    displayError(message: "Could not find user with email at position \(index + 1)")
                return false
            default:
                displayError(message: defaultErrorMessage)
                return false
            }
        }
        return true
    }
    
    
    func saveEvent() async -> Bool {
        // final validation check before saving the event in Firebase
        // this is also the point where a unique event code is generated
        isSubmitting = true
        var eventCode: String
        do {
            let organiserIDs = try await retrieveOrganiserIDs()
            startDate = Date()
            let event = createEvent(organiserIDs: organiserIDs)
            eventCode = try await event.generateUniqueCode()
            try await FirebaseService.save(event: event, id: eventCode)
            showSuccess = true
            
            self.eventCode = eventCode
            
        } catch {
            print(error)
            print("DISPLAYING DEFAULT")
            displayError(message: defaultErrorMessage)
            return false
        }
      
       return true
    }
    
    private func updateEvent(eventHierarchy: EventHierarchy) {
        guard let event = event else { return }
        event.title = title
        event.startDate = Date()
        event.endDate = endDate
        event.eventHierarchy = eventHierarchy
    }
    
    
    // retrieves organiser IDs from a String of emails using the userEmailToID collection
    private func retrieveOrganiserIDs() async throws -> [String] {
        var organiserIds: [String] = []

        // does so concurrently
        try await withThrowingTaskGroup(of: String.self) { group in
            for (index, organiser) in organisers.enumerated() {
                group.addTask {
                    do {
                        return try await FirebaseService.retrieveID(fromEmail: organiser)
                    } catch {
                        throw OrganiserRetrievalError.failedAtEmail(organiser, index, error)
                    }
                }
            }
            
            for try await id in group {
                organiserIds.append(id)
            }
        }
        return organiserIds
    }
    
    private func createEvent(organiserIDs: [String]) -> EventModel {
        return EventModel(eventCreatorID: creatorID, eventTitle: title, eventStartDate: startDate, eventEndDate: endDate, eventOrganiserIDs: organiserIDs)
    }
}
