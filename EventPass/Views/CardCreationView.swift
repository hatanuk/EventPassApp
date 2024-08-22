//
//  CardCreationView.swift
//  EventPass
//
//  Created by Andrew A on 12/08/2024.
//

import SwiftUI

struct CardCreationView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = CardViewModel()
    @FocusState private var focusedField: FocusedField?
    @Environment(\.presentationMode) var presentationMode

    enum FocusedField {
        case title
        case workplace
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
    
                businessCardPreview()

                cardEditFields()

                saveButton()
            }
        }
        .onAppear(perform: handleOnAppear)
        .onSubmit(handleOnSubmit)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ToolbarTitleView("Edit Business Card", size: 30)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ToolbarCancelView(presentationMode)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func businessCardPreview() -> some View {
        CardView(profile: Constants.testProfile)
    }
    
    private func cardEditFields() -> some View {
        Form {
            ForEach(0..<3) { _ in
                Section("Specify a title:") {
                    TextField("", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                }

                Section("Specify a workplace:") {
                    TextField("", text: $viewModel.workplace)
                        .focused($focusedField, equals: .workplace)
                }
            }
        }
    }
    
    private func saveButton() -> some View {
        Button(action: {
            Task {
                await viewModel.save()
            }
            focusedField = nil
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
    }
    
    private func handleOnSubmit() {
        switch focusedField {
        case .title:
            focusedField = .workplace
        case .workplace:
            focusedField = nil
        default:
            focusedField = .title
        }
    }
}


  

#Preview {
    NavigationStack {
        CardCreationView()
            .environmentObject(AuthViewModel())
    }
}
