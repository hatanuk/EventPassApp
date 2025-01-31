//
//  EventCreationView.swift
//  EventPass
//
//  Created by Andrew A on 22/10/2024.
//

import SwiftUI

struct EventCreationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: EventCreationViewModel
    @ObservedObject var eventJoinViewModel: EventJoinViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var showPrivacy = false
    
    init(userID: String, eventJoinViewModel: EventJoinViewModel) {
        self.eventJoinViewModel = eventJoinViewModel
        _viewModel = StateObject(wrappedValue: EventCreationViewModel(creatorID: userID))
    }
    
    
    var body: some View {
        VStack {
            Spacer()
            if viewModel.showSuccess {
                creationSuccessView
                
            }
            else if viewModel.isSubmitting {
                ProgressView("Just one second...")
            } else {
                eventDetailEntryView
            }
        }
        .padding()
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
               }
        .sheet(isPresented: $showPrivacy) {
            privacyView
        }
    }
    
    var privacyView: some View {
        VStack {
            Text("Privacy Policy")
                .font(.largeTitle)
                .padding()
            
            Text("Privacy policy will be included here")
                .padding()
            
            Spacer()
            Button("Dismiss") {
                showPrivacy.toggle()
            }
            .scaleEffect(1.2)
        }
        .padding()
    }
    
    var creationSuccessView: some View {
        
        VStack(spacing: 20) {
            Spacer()
            Text("Your event was created!")
                .font(.system(size: 25))
                .bold()
            Text("The event code is: ")
            Text("\(viewModel.eventCode)")
                       .font(.system(.body, design: .monospaced))
                       .bold()
                       .padding()
                       .background(Color(.systemGray6))
                       .cornerRadius(8)
                       .overlay(
                           RoundedRectangle(cornerRadius: 8)
                               .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                       )
                       .contextMenu {
                           Button(action: {
                               UIPasteboard.general.string = viewModel.eventCode
                           }) {
                               Text("Copy")
                               Image(systemName: "doc.on.doc")
                           }
                       }
            Text("Remember to share this code with your attendees. If you'd like to view it again, you can find it in the Configurations tab of your organiser panel.")
            Spacer()
        }
        .frame(alignment: .center)
        .multilineTextAlignment(.center)
        
     
    }
    
    var eventDetailEntryView: some View {
        
        VStack {
            Spacer()
            ZStack {
                if viewModel.currentStep == 1 {
                    eventNameStep
                        .transition(.asymmetric(insertion: .slide, removal: .opacity)) // Slide in, fade out
                }
                if viewModel.currentStep == 2 {
                    eventDateStep
                        .transition(.asymmetric(insertion: .slide, removal: .opacity))
                }
                if viewModel.currentStep == 3 {
                    eventOrganisersStep
                        .transition(.asymmetric(insertion: .slide, removal: .opacity))
                }
                if viewModel.currentStep == 4 {
                    eventSettingsStep
                        .transition(.asymmetric(insertion: .slide, removal: .opacity))
                }
                if viewModel.currentStep == 5 {
                    reviewStep
                        .transition(.asymmetric(insertion: .slide, removal: .opacity))
                }
            }
          
            Spacer()
            stepTraversalButtons
        }
        .animation(Animation.easeInOut(duration: 0.5), value: viewModel.currentStep)
    }
    
    // MARK: - Step Traversal Buttons
    var stepTraversalButtons: some View {
        HStack {
            
            if viewModel.currentStep > 1 {
               Button(action: {
                   viewModel.previousStep()
               }) {
                   Text("Back")
                       .foregroundColor(.white)
                   
                       .frame(maxWidth: .infinity)
                       .frame(height: 50)
                       .background(Color.blue)
                       .cornerRadius(10)
                       .padding(.top, 20)
               }
               .frame(height: 50)
           }
            if viewModel.currentStep < 5 {
                Button(action: {
                    Task {
                        await viewModel.nextStep()
                    }
                    
                }) {
                    Text("Continue")
                        .foregroundColor(.white)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.isCurrentStepValid() ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .padding(.top, 20)
                }
                .disabled(!viewModel.isCurrentStepValid())
                .frame(height: 50)
            }
        }
    }
    
    // MARK: - Event Name Step
    var eventNameStep: some View {
        VStack(spacing: 40) {
            Text("What's the name of your event?")
                .font(.system(size: 25))
                .bold()
                .frame(alignment: .center)
                .multilineTextAlignment(.center)
            
            TextField("Enter event name", text: $viewModel.title)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
            
            if viewModel.showError {
                Text("Max character limit: 30")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Event Date Step
    var eventDateStep: some View {
        VStack(spacing: 20) {
            Text("When will the event end?")
                .font(.system(size: 25))
                .bold()
                .frame(alignment: .center)
                .multilineTextAlignment(.center)
            
            HStack {
                
                VStack {
       
                    DatePicker("", selection: $viewModel.endDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Event Organisers Step
    var eventOrganisersStep: some View {
        
        VStack(spacing: 20) {
            VStack {
                Spacer(minLength: 200)
                Text("Invite additional Event Organizers")
                    .font(.system(size: 25))
                    .bold()
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
                
                TextField("Enter Organizer Email", text: $viewModel.organiserEmail)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 1)
                
                Button(action: {
                    if !viewModel.organiserEmail.isEmpty {
                        viewModel.organisers.append(viewModel.organiserEmail)
                        viewModel.organiserEmail = ""
                    }
                }) {
                    Text("Add Organizer")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            List {
                ForEach(viewModel.organisers, id: \.self) { organiser in
                    Text(organiser)
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeOrganiser(organiser)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Event Settings Step
    var eventSettingsStep: some View {
        VStack(spacing: 20) {
            Text("Some additional settings")
                .font(.system(size: 25))
                .bold()
                .frame(alignment: .center)
                .multilineTextAlignment(.center)
            
            HStack {
                Text("Allow Business Card transmissions from visitors")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("", isOn: $viewModel.allowBusinessCards)
                    .labelsHidden()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .padding(.horizontal)
    }
    
    
    // MARK: - Review Step
    var reviewStep: some View {
        VStack(spacing: 20) {
            Text("Review your event details")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Display all the event details for final confirmation
            VStack(alignment: .leading, spacing: 10) {
                Text("Event Name: \(viewModel.title)")
                Text("From: \(viewModel.startDate, style: .date) \(viewModel.startDate, style: .time)")
                Text("Until: \(viewModel.endDate, style: .date) \(viewModel.endDate, style: .time)")
                Text("Organizers:")
                ForEach(viewModel.organisers, id: \.self) { organiser in
                    Text("- \(organiser)")
                }
                Text("Business Card Transmissions: \(viewModel.allowBusinessCards ? "On" : "Off")")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 1)
            
            VStack(alignment: .leading) {
                Toggle("I accept the terms of the", isOn: $viewModel.acceptTerms)
                Button(action: {
                    showPrivacy.toggle()
                    }
                ) {
                    Text("privacy policy")
                }
            }
            
           
            
            Button(action: {
                Task  {
                    await _ = viewModel.saveEvent()
                }
            }) {
                Text("Submit")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.acceptTerms ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.acceptTerms)
        }
        .padding()
    }
}



struct EventCreationView_Previews: PreviewProvider {
    static var previews: some View {
        EventCreationView(userID: "1234", eventJoinViewModel: EventJoinViewModel(event: nil, eventCode: nil))
            .environmentObject(AuthViewModel())
    }
}
