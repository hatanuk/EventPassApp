//
//  Attendee.swift
//  EventPass
//
//  Created by Andrew A on 15/09/2024.
//

import Foundation

struct Attendee: Hashable {
    // represents a user who has joined a specific Event
    
    var eventId: String
    var id: String
    var alias: String
    var deviceId: String
    var joinDate: Date
    var card: CardModel
    
    // hashable conformance
    static func == (lhs: Attendee, rhs: Attendee) -> Bool {
        return lhs.id == rhs.id && lhs.eventId == rhs.eventId
    }
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(eventId)
        }
    
}
