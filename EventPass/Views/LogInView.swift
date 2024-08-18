//
//  LogInView.swift
//  EventPass
//
//  Created by Andrew A on 10/08/2024.
//

import SwiftUI

struct LogInView: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var focusedField: FocusedField?
    
    @State private var showForgotPassword = false
    @State private var errorShown = false
    
    private var canConfirm: Bool {
        return viewModel.email.count > 0 && viewModel.password.count > 0
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    enum FocusedField {
        case firstName
        case lastName
        case email
        case password
        case passwordRepeat
    }
    
    
    var body: some View {
       
        NavigationStack {
            VStack {
                InputElement("Email", binding: $viewModel.email, maxChar: 50)
                    .focused($focusedField, equals: .email)
                InputElement("Password", binding: $viewModel.password, maxChar: 100, secure: true)
                    .focused($focusedField, equals: .password)
                    .padding(.bottom, -30)
                ConfirmButtonView
                    .padding(.vertical, 40)
                ForgotPasswordButton
                    .scaleEffect(1.2)
            }
            .padding()
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
            ToolbarItem(placement: .principal) {ToolbarTitleView("Log in")}
            ToolbarItem(placement: .navigationBarTrailing) {ToolbarCancelView(presentationMode)}
           
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            default:
                focusedField = nil
            }
            
        }
        
    }
    
    var ForgotPasswordButton: some View {
        Button(action: {
            showForgotPassword.toggle()
            }
        ) {
            Text("Forgot password?")
        }
    }
    
    var ForgotPasswordView: some View {
        Text("Sorry about that.")
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
        
}


#Preview {
    
    NavigationStack {
        LogInView()
    }
    .environmentObject(AuthViewModel())
}
