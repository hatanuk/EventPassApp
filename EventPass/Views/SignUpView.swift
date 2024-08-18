//
//  SignUpView.swift
//  EventPass
//
//  Created by Andrew A on 30/07/2024.
//

import SwiftUI



struct SignUpView: View {
    
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var focusedField: FocusedField?
    
    @State private var showTerms = false
    @State private var errorShown = false
    
    private var canConfirm: Bool {
        return viewModel.acceptedTerms && viewModel.allPropertiesFilled()
    }
    
    enum FocusedField {
        case firstName
        case lastName
        case email
        case password
        case passwordRepeat
    }
    

    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    InputElement("First Name", binding: $viewModel.firstName)
                        .focused($focusedField, equals: .firstName)
                    InputElement("Last Name", binding: $viewModel.lastName)
                        .focused($focusedField, equals: .lastName)
                }
                InputElement("Email", binding: $viewModel.email, maxChar: 50)
                    .focused($focusedField, equals: .email)
                InputElement("Password", binding: $viewModel.password, maxChar: 100, secure: true)
                    .focused($focusedField, equals: .password)
                InputElement("Re-enter Password", binding: $viewModel.passwordRepeat, maxChar: 100, secure: true)
                    .focused($focusedField, equals: .passwordRepeat)
                
                TermsAcceptanceView
                Spacer()
                ConfirmButtonView
                    .padding(.vertical, 40)
                
            }
            .alert(viewModel.errorMessage, isPresented: $errorShown) {
                Button("OK", role: .cancel) { 
                    Task {
                        await viewModel.updateErrorMessage(to: "")
                    }
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if newValue.count > 0 {
                   errorShown = true
                }
            }
            .onDisappear {
                Task {
                    await viewModel.clearAllValues()
                }
            }
           
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {ToolbarTitleView("Sign up")}
            ToolbarItem(placement: .navigationBarTrailing) {ToolbarCancelView(presentationMode)}
           
        }
        .sheet(isPresented: $showTerms) {
            TermsView
        }
        .onSubmit {
            switch focusedField {
            case .firstName:
                focusedField = .lastName
            case .lastName:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .passwordRepeat
            default:
                focusedField = nil
            }
            
        }
    }
    
    var TermsAcceptanceView: some View {
        HStack {
            Toggle(isOn: $viewModel.acceptedTerms, label: {
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
            var success: Bool = false
            Task {
                print("current user: " + (viewModel.user?.uid ?? "none"))
                success = await viewModel.signUpEmailPassword()
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
        } label : {
            Text("Confirm")
            .frame(width:150, height:60)
            .scaleEffect(1.3)
            .bold()
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius:30, style: .continuous)
                    .fill(LinearGradient(colors: canConfirm ? [.blue, .cyan] : [.gray, .gray],
                                         startPoint: .top, endPoint: .bottomTrailing))
            )
            .foregroundColor(canConfirm ? Color.blue : Color.gray)
            .animation(.linear(duration: 0.2), value: canConfirm)
        }
        .disabled(!canConfirm)

    }
    
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environmentObject(AuthViewModel())
}
