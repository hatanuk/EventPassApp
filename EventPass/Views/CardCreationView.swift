//
//  CardCreationView.swift
//  EventPass
//
//  Created by Andrew A on 12/08/2024.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct CardCreationView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = CardViewModel()
    @FocusState private var focusedField: FocusedField?
    @Environment(\.presentationMode) var presentationMode
    
    var fullName: String {
        if let firstName = viewModel.card.firstName, let lastName = viewModel.card.lastName {
            return firstName + " " + lastName
        } else {
            return ""
        }
    }
    
    @State var errorShown = false


    enum FocusedField {
          case displayName, title, workplace, email, phone, theme, photo
      }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
    
                cardPreview()

                cardEditFields()

                saveButton()
            }
        }
        .onAppear(perform: handleOnAppear)
        .onSubmit(handleOnSubmit)
        .alert(viewModel.errorMessage, isPresented: $errorShown) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = ""
            }
        }
        .onChange(of: viewModel.errorMessage) {
            if viewModel.errorMessage.count > 0 {
                errorShown = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ToolbarTitleView("Edit Business Card", size: 30)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func cardPreview() -> some View {
        CardView(card: viewModel.card)
        
    }
    
    private func cardEditFields() -> some View {
        Form {
            
            formSection(header: "Specify name on card:", binding: $viewModel.displayName, maxChar: 50)
                .focused($focusedField, equals: .displayName)
            formSection(header: "Specify a title:", binding: $viewModel.title, maxChar: 50)
                .focused($focusedField, equals: .title)

            formSection(header: "Specify a workplace:", binding: $viewModel.workplace, maxChar: 50)
                .focused($focusedField, equals: .workplace)

            formSection(header: "Specify a public email:", binding: $viewModel.email, maxChar: 50, keyboardType: .emailAddress)
                .focused($focusedField, equals: .email)

            formSection(header: "Specify a public phone number:", binding: $viewModel.phone, maxChar: 15, keyboardType: .numberPad, numeric: true)
                .focused($focusedField, equals: .phone)
            themePickerSection()
            
            

        }
    }
    
    private func themePickerSection() -> some View {
     
            return Section("Choose a theme:") {
                Picker("Theme", selection: $viewModel.theme) {
                    ForEach(ColorThemes.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized)
                    }
                }
                .focused($focusedField, equals: .theme)
            }
        
       }
       
      
    
    private func saveButton() -> some View {
        Button(action: {
            Task {
                focusedField = nil
                if await viewModel.validateInputs() {
                    await viewModel.save()
                    await MainActor.run {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    errorShown = true
                }
            }
        }) {
            Text("Save")
                .frame(maxWidth: .infinity)
                .frame(height: 20)
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleOnAppear() {
        let id = authViewModel.getUserId()
        if let id = id {
            viewModel.id = id
        } else {
            // user account is not found, must be an error
            presentationMode.wrappedValue.dismiss()
        }
        Task {
            await viewModel.load()
        }
        
    }
    
    private func handleOnSubmit() {
        switch focusedField {
        case .displayName: focusedField = .title
        case .title: focusedField = .workplace
        case .workplace: focusedField = .email
        case .email: focusedField = .phone
        case .phone: focusedField = .theme
        case .theme: focusedField = nil
        default: focusedField = .displayName
        }
    }
}


  

#Preview {
    NavigationStack {
        CardCreationView()
            .environmentObject(AuthViewModel())
    }
}
