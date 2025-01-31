//
//  EventHierarchy.swift
//  EventPass
//
//  Created by Andrew A on 02/09/2024.
//

import Foundation

enum Roles {
    case Attendee
    case eventCreator
    case eventOrganiser
}

struct EventHierarchy {
    // provides information on the event creator and optional organisers
    
    var eventCreator: String
    var eventOrganisers: [String]
    
    init(eventCreator: String, eventOrganisers: [String]?) {
        self.eventCreator = eventCreator
        
        if let eventOrganisers = eventOrganisers {
            self.eventOrganisers = eventOrganisers
        } else {
            self.eventOrganisers = []
        }
        
    }
}
                        
