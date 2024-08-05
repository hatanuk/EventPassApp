//
//  ContentView.swift
//  EventPass
//
//  Created by Andrew A on 03/06/2024.
//

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @ObservedObject private var bluetoothVM = BLEViewModel()
    
    @State private var eventCode = ""
    @State private var showHelp = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                FlavorTextView
                Spacer()
                EventInputView
                Spacer()
                AccountInfoView
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationBarItems(trailing: HelpIconView)
            .sheet(isPresented: $showHelp) {
                HelpView
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    var HelpIconView: some View {
        Button(action: {
                showHelp.toggle()
            }) {
                Image(systemName: "questionmark.circle")
                .font(.title)
                .foregroundColor(.blue)
            }
            .padding()
    }
    
    var FlavorTextView: some View {
        VStack(spacing: 20) {
            Text("Welcome.")
                .font(.custom("Freehand", size: 60))
                .fontWeight(.semibold)
            
            Text("Looking to join an event?")
                .font(.system(size: 30))
            
        }
        .padding(.top, 40)
    }
    
    var AccountInfoView: some View {
        VStack {
            Text("Not logged in")
                .foregroundColor(.gray)
                .padding(.bottom, 3)
            HStack {
                
                NavigationLink(destination: SignUpView()) {
                    Text("Sign up")
                        .foregroundColor(.blue)
                }
                
                Text("or")
                    .foregroundColor(.gray)
                
                NavigationLink(destination: WelcomeView()) {
                    Text("log in")
                        .foregroundColor(.blue)
                }
                
            }
        }
        .scaleEffect(1.2)
        .padding(.horizontal, 35)
        .padding(.bottom, 20)
        .fontWeight(.semibold)
    }
    
    var HelpView: some View {
        VStack {
            Text("Help Information")
                .font(.largeTitle)
                .padding()
            
            Text("Here you can provide detailed help information for the users.")
                .padding()
            
            Spacer()
            Button("Dismiss") {
                showHelp.toggle()
            }
            .scaleEffect(1.2)
        }
        .padding()
    }
    
    var EventInputView: some View {
        
    VStack {
        TextField("", text: $eventCode)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .scaleEffect(1.7)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.blue),
                alignment: .bottom
            )
            .keyboardType(.numberPad)
            .onChange(of: eventCode) { oldValue, newValue in
                // filters through every character in the string to check that it is a numeral
                var filtrate = newValue.filter {"0123456789".contains($0)}
                
                if filtrate.count > 6 {
                    filtrate = String(filtrate.prefix(6))
                }
                
                eventCode = filtrate
                
            }
        
        Text("Enter the event code above")
            .foregroundColor(.gray)
            .font(.caption)
            .scaleEffect(1.5)
            .padding(.top, 10)
    }
    .padding(.horizontal)
    .padding(.bottom, 50)
    }
}
    


    
    
#Preview {
    WelcomeView()
        .modelContainer(for: Item.self, inMemory: true)
}
