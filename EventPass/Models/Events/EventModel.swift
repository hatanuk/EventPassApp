//
//  EventModel.swift
//  EventPass
//
//  Created by Andrew A on 02/08/2024.
//

import Foundation
import Firebase

enum EventError: Error {
    case codeGenerationFailed
    case invalidTitle
    case dateTooShort
    case dateTooLong
    case invalidCreator
    case invalidOrganiserEmail(errorMessage: String)

}


class EventModel: Identifiable, Hashable {
    // represents an event, which exists as a record within Firestore
    
    // conformance to Hashable
      static func == (lhs: EventModel, rhs: EventModel) -> Bool {
          return lhs.title == rhs.title && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
      }

      func hash(into hasher: inout Hasher) {
          hasher.combine(title)
          hasher.combine(startDate)
          hasher.combine(endDate)
          hasher.combine(eventHierarchy.eventCreator)
      }
    //
    
    static let EVENT_CODE_LENGTH = 6
    
    var eventHierarchy: EventHierarchy
    var eventConfig: EventConfig
    var title: String
    var startDate: Date
    var endDate: Date
    var attendees: [Attendee]
    
    
    init(eventCreatorID: String, eventTitle: String, eventStartDate: Date, eventEndDate: Date, eventOrganiserIDs: [String]?, transmissionsOn: Bool = true, attendees: [Attendee] = [], bannedUsers: [Attendee] = []) {
        self.title = eventTitle
        self.startDate = eventStartDate
        self.endDate = eventEndDate
        self.eventHierarchy = EventHierarchy(eventCreator: eventCreatorID, eventOrganisers: eventOrganiserIDs)
        self.eventConfig = EventConfig(transmissionsOn: transmissionsOn, bannedUsers: bannedUsers)
        self.attendees = attendees
    }
    
    init(eventTitle: String, eventStartDate: Date, eventEndDate: Date, eventHierarchy: EventHierarchy, transmissionsOn: Bool = true, attendees: [Attendee] = [], bannedUsers: [Attendee] = []) {
        self.title = eventTitle
        self.startDate = eventStartDate
        self.endDate = eventEndDate
        self.eventHierarchy = eventHierarchy
        self.eventConfig = EventConfig(transmissionsOn: transmissionsOn, bannedUsers: bannedUsers)
        self.attendees = attendees
    }


    // attempts to generate a unique six-digit code that is not already used by an active event
    func generateUniqueCode() async throws -> String {
        let MAX_RETRIES = 30
        
        // the six digit code is generated via a hash of the event creator's ID and a random seed
        let hashId = eventHierarchy.eventCreator
        var hashSalt = Int.random(in: 1...300)
        var hash = abs(_combine_into_hash(inputs: hashId, hashSalt))
        var code = String(String(hash).prefix(EventModel.EVENT_CODE_LENGTH))
        
        // if the hash is already used by another event, regenerate the salt and try again for MAX_RETRIES
        var tries = 0
        while (( try? await FirebaseService.eventExists(withCode: code)) != false) {
            hashSalt = Int.random(in: 1...300)
            hash = abs(_combine_into_hash(inputs: hashId, hashSalt))
            code = String(String(hash).prefix(EventModel.EVENT_CODE_LENGTH))
            tries += 1
            if tries >= MAX_RETRIES {
                throw EventError.codeGenerationFailed
            }
        }
        return code

    }
    
    static func isValidCode(_ code: String) -> Bool {
        // for validation purposes
        return code.count == EventModel.EVENT_CODE_LENGTH && code.allSatisfy { $0.isNumber }
    }
        
    
    private func _combine_into_hash(inputs: AnyHashable...) -> Int {
        var hasher = Hasher()
        for input in inputs {
            hasher.combine(input)
        }
        return hasher.finalize()
    }
    
    

}


