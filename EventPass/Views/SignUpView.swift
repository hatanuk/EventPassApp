//
//  SignUpView.swift
//  EventPass
//
//  Created by Andrew A on 30/07/2024.
//

import SwiftUI

enum FocusedField {
    case firstName
    case lastName
    case email
    case password
    case passwordRepeat
   }

struct SignUpView: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var focusedField: FocusedField?
    
    @State private var showTerms = false
    @State private var errorShown = false
    
    private var canConfirm: Bool {
        return viewModel.acceptedTerms && viewModel.allPropertiesFilled()
    }
    
    
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    InputElement("First Name", binding: $viewModel.firstName, focusedFieldName: .firstName)
                    InputElement("Last Name", binding: $viewModel.lastName, focusedFieldName: .lastName)
                }
                InputElement("Email", binding: $viewModel.email, focusedFieldName: .email)
                InputElement("Password", binding: $viewModel.password, focusedFieldName: .password, secure: true)
                InputElement("Re-enter Password", binding: $viewModel.passwordRepeat,  focusedFieldName: .passwordRepeat, secure: true)
                
                TermsAcceptanceView
                Spacer()
                ConfirmButtonView
                    .padding(.vertical, 40)
                
            }
            .alert(viewModel.errorMessage, isPresented: $errorShown) {
                Button("OK", role: .cancel) { 
                    viewModel.errorMessage = ""
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if newValue.count > 0 {
                   errorShown = true
                }
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
                success = await viewModel.signInEmailPassword()
            }
            if success {
                presentationMode.wrappedValue.dismiss()
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
    
        func InputElement(_ label: String, binding: Binding<String>, focusedFieldName: FocusedField, maxChar: Int = 20, secure: Bool = false) -> some View {
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
            .focused($focusedField, equals: focusedFieldName)

        }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environmentObject(AuthViewModel())
}
