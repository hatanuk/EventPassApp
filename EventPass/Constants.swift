//
//  Constants.swift
//  EventPass
//
//  Created by Andrew A on 23/06/2024.
//

import Foundation
import CoreBluetooth

struct Constants {
    
    // BLE
    static let serviceUUID = CBUUID(string: "264CE6E8-8C39-4FE4-957F-8D3CFD69D326")
    static let characteristicUUID = CBUUID(string: "F828A7AA-36E8-408C-9A58-59AB568AF40E")
    
    // Configs
    static let MIN_EVENT_DAYS = 1
    static let MAX_EVENT_DAYS = 90
    
    static let MAX_EVENT_TITLE_LENGTH = 30
    static let MIN_EVENT_TITLE_LENGTH = 2
    
    
    static let defaultProfileImageURL = "https://avatars.githubusercontent.com/u/583231?v=4"
    
    static let defaultColorTheme = ColorThemes.coolBlue
    
    static let unspecifiedDisplayName = "Your name"
    
    static let testProfile = CardModel(
        id: "BQKO55THO3YkvvD2AEQz8fuHulq1",
        alias: "JumpingTiger34",
        displayName: "Jane Smith",
        title: "Software Engineer",
        workplace: "Tech Company",
        email: "john.doe@example.com",
        phone: "1234567890",
        profilePictureURL: Constants.defaultProfileImageURL,
        theme: .sunset
    )
    
    static let testProfile2 = CardModel(
        id: "3434343",
        alias: "FocusedKoala23",
        displayName: "Jane Smith",
        title: "Software Engineer",
        workplace: "Tech Company",
        email: "jane.doe@example.com",
        phone: "344567890",
        profilePictureURL: Constants.defaultProfileImageURL,
        theme: .silverEdge
    )
    
    static let testProfile3 = CardModel(
        id: "BQKO55THO3YkvvD2AEQz8fuHulq1",
        alias: "GreatKoala13",
        displayName: "Jeremy Apple",
        title: "The Master",
        workplace: "Wizard Emporium",
        email: "ilovemagic@gmail.com",
        phone: "123456789",
        profilePictureURL: Constants.defaultProfileImageURL,
        theme: .midnight
    )
    
    
    static let testEventAttendee1 = Attendee(eventId: "708179", id: testProfile.id, alias: testProfile.alias, deviceId: "", joinDate: Date(timeIntervalSince1970: 0), card: testProfile)
    static let testEventAttendee2 = Attendee(eventId: "123456", id: testProfile2.id, alias: testProfile2.alias, deviceId: "244353", joinDate: Date(timeIntervalSince1970: 0), card: testProfile2)
    
    static let testEvent = EventModel(eventCreatorID: "wFky0kd69VSBC06PkBOhixKvue13", eventTitle: "Event Enthusiast Conference", eventStartDate: Date(), eventEndDate: Date(timeIntervalSinceNow: 1_000_000), eventOrganiserIDs: nil, attendees: [testEventAttendee1, testEventAttendee2])
    
    
    static let aliasFirst = ["Agile", "Brave", "Clever", "Daring", "Energetic", "Fierce", "Gentle", "Happy", "Icy", "Jolly", "Kind", "Lively", "Mighty", "Nimble", "Optimistic", "Playful", "Quick", "Radiant", "Strong", "Tough", "Uplifted", "Vivid", "Wise", "Zealous", "Bold", "Calm", "Dazzling", "Eager", "Fearless", "Graceful", "Heroic", "Impressive", "Joyful", "Keen", "Loyal", "Magnetic", "Noble", "Outgoing", "Peaceful", "Quirky", "Resilient", "Sincere", "Tenacious", "Unique", "Vibrant", "Whimsical", "Youthful", "Zesty", "Adventurous", "Breezy", "Courageous", "Determined", "Excited", "Friendly", "Gracious", "Hopeful", "Innovative", "Jovial", "Knowledgeable", "Luminous", "Motivated", "Neat", "Observant", "Patient", "Quiet", "Reliable", "Supportive", "Thoughtful", "Understanding", "Valiant", "Witty", "Zippy", "Ambitious", "Bright", "Charming", "Dynamic", "Efficient", "Focused", "Generous", "Humble", "Inspiring", "Jubilant", "Kinetic", "Lucky", "Mature", "Nurturing", "Optimistic", "Powerful", "Quick-witted", "Resourceful", "Skilled", "Trustworthy", "Upright", "Vigorous", "Wanderlust", "Zealous", "Creative", "Curious", "Cool", "Great"]

    
    static let aliasSecond = ["Tiger", "Eagle", "Lion", "Shark", "Dragon", "Panther", "Wolf", "Fox", "Bear", "Falcon", "Hawk", "Cheetah", "Cougar", "Jaguar", "Leopard", "Puma", "Raven", "Owl", "Viper", "Cobra", "Python", "Raccoon", "Koala", "Kangaroo", "Penguin", "Rhino", "Bison", "Elk", "Buffalo", "Moose", "Stag", "Deer", "Beaver", "Otter", "Swan", "Goose", "Duck", "Dolphin", "Whale", "Sealion", "Octopus", "Seahorse", "Turtle", "Crab", "Lobster", "Stingray", "Jellyfish", "Starfish", "Walrus", "Pelican", "Heron", "Flamingo", "Toucan", "Parrot", "Bat", "Wombat", "Sloth", "Armadillo", "Meerkat", "Hyena", "Jackal", "Gazelle", "Zebra", "Elephant", "Giraffe", "Hippo", "Crocodile", "Alligator", "Monitor", "Iguana", "Chameleon", "Gecko", "Quokka", "Ocelot", "Lynx", "Mongoose", "Ferret", "Llama", "Alpaca", "Donkey", "Mule", "Horse", "Mustang", "Pony", "Stallion", "Mare", "Rooster", "Hen", "Peacock", "Swallow", "Raven", "Magpie", "Vulture", "Condor", "Buzzard", "Crow", "Falcon", "Gorilla", "Chimp", "Koala"]
    
    
    
}
