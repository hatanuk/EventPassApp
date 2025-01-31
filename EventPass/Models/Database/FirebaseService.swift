//
//  UserProfile.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum UserError: Error {
    case userNotFound
}

enum DatabaseError: Error {
    case documentNotFound
    case invalidData
    case invalidArgument
}

let eventCollection = "activeEvents"
let aliasMappingCollection = "userAliasToID"
let emailMappingCollection = "userEmailToID"
let userDetailsCollection = "userDetails"

class FirebaseService {
    // this class is responsible for handling user-related Firebase operations
    // all exposed methods are static and there is no need for instantiation, hence:
    private init() {}
    
    private static var db = Firestore.firestore()
    
    
    // MARK: - Authentication
    
    static func signIn(email: String, password: String) async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            return authResult
        } catch {
            throw error
        }
    }
    
    static func signInAnonymously() async throws -> AuthDataResult {
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            return authResult
        } catch {
            throw error
        }
    }
    
 
    
    static func signUp(email: String, password: String, user: User) async throws -> AuthDataResult {
        
        do {
            let db = Firestore.firestore()
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let authResult = try await user.link(with: credential)
            return authResult
        } catch let error as NSError where error.domain == AuthErrorDomain && error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
            throw SignUpError.emailInUse
        } catch {
            throw error
        }
        
    }

    
    static func signOut() throws {
        do {
          try Auth.auth().signOut()
        }
        catch {
          throw error
        }
      }
    
    
    
    static func deleteAccount(user: User) async throws {
        do {
            try await user.delete()
            try await deleteDetails(userId: user.uid)
            try await deleteEmailToIDMapping(userId: user.uid)
            try await deleteAliasToIDMapping(userId: user.uid)
        
        } catch {
                throw error
        }
    }
    
    //MARK: - Firebase Operations
    
    static func eventExists(withCode code: String) async throws -> Bool {
        do {
            let document = try await db.collection(eventCollection).document(code).getDocument()
            if document.exists {
                return true
            } else {
                return false
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Retrieve Operations
    
    static func retrieveAlias(fromID userId: String) async throws -> String {
        let querySnapshot = try await db.collection(aliasMappingCollection).getDocuments()

        for document in querySnapshot.documents {
            if let id = document.data()["id"] as? String, id == userId{
                return document.documentID
            }
        }
        throw UserError.userNotFound
    }
    

    
    static func retrieveEvent(fromCode code: String) async throws -> EventModel {
        var document: DocumentSnapshot?
        
        guard EventModel.isValidCode(code) else {
            throw DatabaseError.invalidArgument
        }
        
        do {
            document = try await db.collection(eventCollection).document(code).getDocument()
            
            guard let data = document?.data() else {
                throw DatabaseError.documentNotFound
            }
            
            guard let title = data["title"] as? String,
                  let startDateTimestamp = data["startDate"] as? Timestamp,
                  let endDateTimestamp = data["endDate"] as? Timestamp,
                  let eventHierarchyData = data["hierarchy"] as? [String: Any],
                  let eventConfigData = data["config"] as? [String: Any],
                  let transmissionsOn = eventConfigData["transmissionsOn"] as? Bool,
                  let bannedUsersData = eventConfigData["bannedUsers"] as? [[String: Any]],
                  let attendeesData = data["attendees"] as? [[String: Any]] else {
                throw DatabaseError.invalidData
            }
            
            let startDate = startDateTimestamp.dateValue()
            let endDate = endDateTimestamp.dateValue()
            
            let eventCreator = eventHierarchyData["eventCreator"] as? String ?? ""
            let eventOrganisers = eventHierarchyData["eventOrganisers"] as? [String]
            let eventHierarchy = EventHierarchy(eventCreator: eventCreator, eventOrganisers: eventOrganisers)
            
            
            let attendees = await convertAttendeesForModel(attendeesData, eventId: code)
            let bannedUsers = await convertAttendeesForModel(bannedUsersData, eventId: code)
            
            let event = EventModel(eventTitle: title, eventStartDate: startDate, eventEndDate: endDate, eventHierarchy: eventHierarchy, transmissionsOn: transmissionsOn, attendees: attendees, bannedUsers: bannedUsers)
            
            return event
            
        } catch let error as NSError {
            if error.domain == FirestoreErrorDomain {
                if error.code == FirestoreErrorCode.notFound.rawValue {
                    print("Event not found")
                } else {
                    print("Firestore error: \(error.localizedDescription)")
                }
            } else {
                print("Unknown error: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    static func retrieveID(fromEmail email: String) async throws -> String {
       var document: DocumentSnapshot?
       document = try await db.collection(emailMappingCollection).document(email).getDocument()
       let data = document?.data()
       if let id = data?["id"] as? String {
           return id
       } else {
           throw UserError.userNotFound
       }
    }
    
    static func retrieveDetails(fromUserId userId: String) async throws -> [String: String?] {
        var document: DocumentSnapshot?
        document = try await db.collection(userDetailsCollection).document(userId).getDocument()
       
       guard let document = document, document.exists else {
           print("No card details associated with user found")
           throw DatabaseError.documentNotFound
       }
       
       let fetchedDetails = convertFetchedDetailsToDict(document)
        
        return fetchedDetails
       
   }
    
    static func checkIfUser(is role: Roles, userID: String, eventCode: String) async throws -> Bool {
        var document: DocumentSnapshot?
        document = try await db.collection(eventCollection).document(eventCode).getDocument()
     
       
        guard let document = document, document.exists, let data = document.data() else {
           print("Event does not exist")
           throw DatabaseError.documentNotFound
       }
        
        
        guard let hierarchy = data["hierarchy"] as? [String: Any],
              let organiserIDs = hierarchy["eventOrganisers"] as? [String],
              let eventCreatorID = hierarchy["eventCreator"] as? String
        else {
            print("invalid data")
            throw DatabaseError.invalidData}
        
        switch role {
        case .eventCreator:
            return eventCreatorID == userID
        case .eventOrganiser:
            return organiserIDs.contains(userID) || eventCreatorID == userID
        case .Attendee:
            return !organiserIDs.contains(userID) && !(eventCreatorID == userID)
        }
       
    }
   
    

    
    // MARK: - Delete Operations
    
    
    static func removeAttendeeFromEvent(_ attendee: Attendee, eventCode: String) async throws {
        
        let db = Firestore.firestore()
        let attendeeID = attendee.id
        
        // fetches the event's document
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(eventCollection).document(eventCode).getDocument { (documentSnapshot, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let document = documentSnapshot, document.exists, var attendees = document.data()?["attendees"] as? [[String: Any]] else {
                    continuation.resume(throwing: NSError(domain: "EventError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event or attendees not found"]))
                    return
                }
                
                // removes the attendee (that has left) from the array
                attendees.removeAll { attendee in
                    if let id = attendee["id"] as? String {
                        return id == attendeeID
                    }
                    return false
                }
                
                // updates the document with the filtered attendees array
                db.collection(eventCollection).document(eventCode).updateData([
                    "attendees": attendees
                ]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    
    static func removeAttendeeFromEvent(attendeeID: String, eventCode: String) async throws {
        
        // function override which accepts attendeeID instead of an Attendee model
        
        // fetches the event's document
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(eventCollection).document(eventCode).getDocument { (documentSnapshot, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let document = documentSnapshot, document.exists, var attendees = document.data()?["attendees"] as? [[String: Any]] else {
                    continuation.resume(throwing: NSError(domain: "EventError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event or attendees not found"]))
                    return
                }
                
                // removes the attendee (that has left) from the array
                attendees.removeAll { attendee in
                    if let id = attendee["id"] as? String {
                        return id == attendeeID
                    }
                    return false
                }
                
                // updates the document with the filtered attendees array
                db.collection(eventCollection).document(eventCode).updateData([
                    "attendees": attendees
                ]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // deletes an entire event
    static func deleteEvent(eventCode: String) async throws {
        try await db.collection(eventCollection).document(eventCode).delete()
    }
    
    // deletes the user's email-to-ID mapping
    private static func deleteEmailToIDMapping(userId: String) async throws {
        let document = try await db.collection(emailMappingCollection).document(userId).getDocument()
        try await document.reference.delete()
    }
    
    // deletes the user's alias-to-ID mapping
    private static func deleteAliasToIDMapping(userId: String) async throws {
        let document = try await db.collection(aliasMappingCollection).document(userId).getDocument()
        try await document.reference.delete()
    }
    
    
    
    // delete card details associated with an account
    private static func deleteDetails(userId: String) async throws {
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            
                // deletes the user's card details
                db.collection(userDetailsCollection).document(userId).delete() { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        
            
    }
    
    // removes all attendees from an event. mainly for testing purposes
    static func removeAllAttendees(eventCode: String) async throws {
        try await db.collection(eventCollection).document(eventCode).updateData([
              "attendees": []
          ])
    }

    
    // MARK: - Save Operations
    
    
    static func addAttendeeToEvent(_ attendee: Attendee, eventCode: String) async throws {
        
        let convertedAttendees = await convertAttendeesForFirestore([attendee])
        let attendeeDict: [String: Any]
        
        if convertedAttendees.count > 0 {
            attendeeDict = convertedAttendees[0]
        } else {
            // convertAttendees returned an empty array; the attendee doesn't exist
            throw NSError()
        }
        
        // updates the document with the additional attendee
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(eventCollection).document(eventCode).updateData([
                        "attendees": FieldValue.arrayUnion([attendeeDict])
                    ]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
              
                }
            }
        }
        
    }
    
    static func mapIDToEmail(userId: String, email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(emailMappingCollection).document(email).setData(["id" : userId]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
    }
    
    static func mapAliasToID(userID: String) async throws {
        let alias = try await generateUniqueAlias()
        try await db.collection(aliasMappingCollection).document(alias).setData(["id" : userID])
    }
    
    
    static func save(card: CardModel) async throws {
        // saves a user's details to Firestore
        
        // conversion of card data to a Firestore collection-friendly format
        let cardData = convertCardForFirestore(card)
        
        try await db.collection(userDetailsCollection).document(card.id).setData(cardData)
    }

    
    
    static func save(event: EventModel, id: String) async throws {
        // saves an event to Firestore
        
        // conversion of event data, attendees and banned users to a Firestore collection-friendly format
        let attendees = await convertAttendeesForFirestore(event.attendees)
        let bannedUsers = await convertAttendeesForFirestore(event.eventConfig.bannedUsers)
        let eventData: [String: Any] = [
            "title": event.title,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "hierarchy": [
                "eventCreator": event.eventHierarchy.eventCreator,
                "eventOrganisers": event.eventHierarchy.eventOrganisers,
            ],
            "config": [
                "transmissionsOn": event.eventConfig.transmissionsOn,
                "bannedUsers": bannedUsers
            ],
            "attendees": attendees
        ]
   
        try await db.collection(eventCollection).document(id).setData(eventData)
    }

    
    // MARK: - Helper Functions
    
    private static func generateUniqueAlias() async throws -> String {
        
        func aliasExists(_ alias: String) async -> Bool {
            do {
                let document = try await FirebaseService.db.collection(aliasMappingCollection).document(alias).getDocument()
                return document.exists
            } catch {
                return true
            }
        }
        
        var potentialAlias: String
        for _ in 0...100 {
            potentialAlias = Constants.aliasFirst.randomElement()! + Constants.aliasSecond.randomElement()! + String(Int.random(in: 10...99))
            if await !aliasExists(potentialAlias) {
                return potentialAlias
            }
        }
        
        throw NSError(domain: "AliasError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to generate unique alias"])
    }
    
    static private func convertAttendeesForFirestore(_ attendees: [Attendee]) async -> [[String: Any]] {
        let attendeeIDs = attendees.map { $0.id }
        guard !attendeeIDs.isEmpty else {
              return []
          }
        // fetch details in batch
        do {
            let detailsSnapshot = try await db.collection(userDetailsCollection)
                .whereField(FieldPath.documentID(), in: attendeeIDs)
                .getDocuments()
            
            let detailsDict = detailsSnapshot.documents.reduce(into: [String: [String: Any]]()) { result, document in
                result[document.documentID] = document.data()
            }
            let convertedAttendees = attendees.compactMap { attendee -> [String: Any]? in
                if let detail = detailsDict[attendee.id] {
                    return [
                        "id": attendee.id,
                        "alias": attendee.alias,
                        "details": detail,
                        "deviceId": attendee.deviceId,
                        "joinDate": attendee.joinDate
                    ]
                } else {
                    print("(WARNING): Attendee \(attendee.id) has no details.")
                    return nil
                }
            }
            
            return convertedAttendees
            
        } catch {
            print("(ERROR): Failed to fetch attendee details - \(error)")
            return []
        }
    }

    
    static private func convertAttendeesForModel(_ attendees: [[String: Any]], eventId: String) async -> [Attendee] {
        // Converts Attendee models to a model representation
        var convertedAttendees: [Attendee] = []
        var attendeeModel: Attendee
        var card: CardModel
        
        for attendee in attendees {
            
            guard let id = attendee["id"] as? String,
                  let alias = attendee["alias"] as? String,
                  let deviceId = attendee["deviceId"] as? String,
                  let joinDate = attendee["joinDate"] as? Timestamp,
                  let detailsDict = attendee["details"] as? [String: Any] else {
                print("(WARNING): Attendee missing required fields")
                continue
            }
            
            let joinDateValue = joinDate.dateValue()
            
      
            card = CardModel(id: id,
                             alias: alias,
                             displayName: detailsDict["displayName"] as? String,
                             title: detailsDict["title"] as? String,
                             workplace: detailsDict["workplace"] as? String,
                             email: detailsDict["email"] as? String,
                             phone: detailsDict["phone"] as? String,
                             profilePictureURL: detailsDict["profilePictureURL"] as? String,
                             theme: ColorThemes(id: Int(detailsDict["theme"] as? String ?? "0") ?? 0)
                             )
    
            
           attendeeModel = Attendee(eventId: eventId,
                                    id: id,
                                    alias: alias,
                                    deviceId: deviceId,
                                    joinDate: joinDateValue,
                                    card: card)
            
            convertedAttendees.append(attendeeModel)
        }
        
        return convertedAttendees
    }
    
    
    static private func convertFetchedDetailsToDict(_ document: DocumentSnapshot?) -> [String: String?] {
        // converts a document of details to a dictionary representation
        let data = document?.data()
        return [
            "id": document?.documentID,
            "alias": data?["alias"] as? String,
            "displayName": data?["displayName"] as? String,
            "title": data?["title"] as? String,
            "workplace": data?["workplace"] as? String,
            "email": data?["email"] as? String,
            "phone": data?["phone"] as? String,
            "profilePictureURL": data?["profile_picture"] as? String,
            "theme": data?["theme"] as? String
        ]
    }
    
    static private func convertCardForFirestore(_ card: CardModel) -> [String: Any] {
        return [
            "alias": card.alias,
            "displayName": card.displayName ?? "",
            "workplace": card.workplace ?? "",
            "title": card.title ?? "",
            "email": card.email ?? "",
            "phone": card.phone ?? "",
            "profile_picture": card.profilePictureURL ?? "",
            "theme": String(card.theme.id),
        ]
    }
    
    
}
