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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate


    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
       
    }
}
