//
//  SignUpView.swift
//  EventPass
//
//  Created by Andrew A on 30/07/2024.
//

import SwiftUI

struct SignUpView: View {
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordRepeat = ""
    @State private var acceptedTerms = false
    @State private var showTerms = false
    
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    InputElement("First Name", binding: $firstName)
                    InputElement("Last Name", binding: $lastName)
                }
                InputElement("Email", binding: $email)
                InputElement("Password", binding: $password, secure: true)
                InputElement("Re-enter Password", binding: $passwordRepeat, secure: true)
                
                TermsAcceptanceView
                Spacer()
                ConfirmButtonView
                    .padding(.vertical, 40)
                
            }
           
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {ToolbarTitleView}
            ToolbarItem(placement: .navigationBarTrailing) {ToolbarCancelView}
           
        }
        .sheet(isPresented: $showTerms) {
            TermsView
        }
        
    }
    
    var TermsAcceptanceView: some View {
        HStack {
           Toggle(isOn: $acceptedTerms, label: {
                VStack(alignment: .leading) {
                    Text("By toggling this button, I accept the")
                    Button(action: {
                        showTerms.toggle()
                        }
                    ) {
                        Text("terms and conditions")
                    }
                }
            })
              
        }
        .padding(.horizontal, 30)
    }
    
    var TermsView: some View {
        VStack {
            Text("Terms and Conditions")
                .font(.largeTitle)
                .padding()
            
            Text("You agree to enter a soul contract with this company.")
                .padding()
            
            Spacer()
            Button("Dismiss") {
                showTerms.toggle()
            }
            .scaleEffect(1.2)
        }
        .padding()
    }
     
    var ConfirmButtonView: some View {
        
        Button {
            
        } label : {
            Text("Confirm")
            .frame(width:150, height:60)
            .scaleEffect(1.3)
            .bold()
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius:30, style: .continuous)
                    .fill(LinearGradient(colors: acceptedTerms ? [.blue, .cyan] : [.gray, .gray],
                                         startPoint: .top, endPoint: .bottomTrailing))
            )
            .foregroundColor(acceptedTerms ? Color.blue : Color.gray)
            .animation(.linear(duration: 0.2), value: acceptedTerms)
        }
        .disabled(!acceptedTerms)

    }
    
    var ToolbarTitleView: some View {
        Text("Sign Up")
            .font(.system(size: 40))

    }
    
    var ToolbarCancelView: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark.circle")
                .font(.title)
                .padding()
                .foregroundColor(.red)
        }
    }
    
    func InputElement(_ label: String, binding: Binding<String>, maxChar: Int = 20, secure: Bool = false) -> some View {
        let field = secure ? AnyView(SecureField(label, text: binding)) : AnyView(TextField(label, text: binding))
        
        return field
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .scaleEffect(1.2)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.blue),
                alignment: .bottom
            )
            .onChange(of: binding.wrappedValue) { oldValue, newValue in
                if newValue.count > maxChar {
                    binding.wrappedValue = oldValue
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)

        }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
