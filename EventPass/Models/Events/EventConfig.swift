//
//  EventConfig.swift
//  EventPass
//
//  Created by Andrew A on 15/09/2024.
//

import Foundation

struct EventConfig {
    // stores the configurable options and banned users of an Event
    
    var transmissionsOn: Bool
    var bannedUsers: [Attendee] = []
    
    init(transmissionsOn: Bool, bannedUsers: [Attendee] = []) {
        self.transmissionsOn = transmissionsOn
        self.bannedUsers = bannedUsers
    }
    
    
}
                        

