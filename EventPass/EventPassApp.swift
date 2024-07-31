//
//  EventPassApp.swift
//  EventPass
//
//  Created by Andrew A on 03/06/2024.
//

import SwiftUI
import SwiftData

import SwiftUI
import FirebaseCore


// Firebase Boilerplate
// An AppDelegate is responsible for handling respondng to app-level events such as
// launching or termination
// This code configures Firebase upon a completed launch
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}


@main
struct EventPassApp: App {
    
    // SwiftUI Boilerplate
    var sharedModelContainer: ModelContainer = {
        // Schema is created with a generic Item - modify this later
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate


    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
        .modelContainer(sharedModelContainer)
    }
}
