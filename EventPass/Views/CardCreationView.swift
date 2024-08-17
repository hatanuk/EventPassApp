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
    NavigationStack {
      Form {
          
            Section("Specify a title:") {
                TextField("", text: $viewModel.title)
                .focused($focusedField, equals: .title)
            }

            Section("Specify a workplace:") {
                TextField("", text: $viewModel.workplace)
                .focused($focusedField, equals: .workplace)
            }
        

        Button {
          viewModel.save()
          focusedField = nil
        } label: {
          Text("Save")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowInsets(EdgeInsets())
      }
      .onAppear {
          let id = authViewModel.getUserId()
          
          if let id = id {
              viewModel.id = id
          } else {
              // user account is not found, must be an error
              presentationMode.wrappedValue.dismiss()
          }
      }
      .onSubmit {
        switch focusedField {
        case .title:
          focusedField = .workplace
        case .workplace:
          focusedField = nil
        default:
          focusedField = .title
        }
      }
      .listStyle(.plain)
     
      .navigationTitle("Business Card")
    }
  }
}


  

#Preview {
    CardCreationView()
        .environmentObject(AuthViewModel())
}
