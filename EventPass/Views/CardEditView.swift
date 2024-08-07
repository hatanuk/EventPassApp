//
//  CardEditView.swift
//  EventPass
//
//  Created by Andrew A on 03/08/2024.
//

import SwiftUI
import Combine
import FirebaseAnalytics



struct CardEditView: View {
    //@StateObject var viewModel = CardViewModel()
  @State private var presentingProfileScreen = false

  enum Field {
    case color
    case movie
    case food
    case city
  }

  @FocusState private var focusedField: Field?

  var body: some View {
    NavigationStack {
      Form {
        Section("What's your favourite number?") {
          Stepper(value: $viewModel.favourite.number, in: 0...100) {
            Text("\(viewModel.favourite.number)")
          }
        }

        Section("What's your favourite color?") {
          ColorPicker(selection: $viewModel.favourite.color) {
            Text("\(viewModel.favourite.color.toHex ?? "")")
          }
        }

        Section("What's your favourite movie?") {
          TextField("", text: $viewModel.favourite.movie)
            .focused($focusedField, equals: .movie)
        }

        Section("What's your favourite food?") {
          TextField("", text: $viewModel.favourite.food)
            .focused($focusedField, equals: .food)
        }

        Section("What's your favourite city?") {
          TextField("", text: $viewModel.favourite.city)
            .focused($focusedField, equals: .city)
        }

        Section("Make your favourites public?") {
          Toggle(isOn: $viewModel.favourite.isPublic) {
            Text("\(viewModel.favourite.isPublic ? "Yes" : "No")")
          }
        }

        Button {
          viewModel.saveFavourite()
          focusedField = nil
        } label: {
          Text("Save")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.blue)
        .listRowInsets(EdgeInsets())
      }
      .onAppear {
        viewModel.fetchFavourite()
      }
      .onDisappear {
        viewModel.saveFavourite()
      }
      .onSubmit {
        switch focusedField {
        case .movie:
          focusedField = .food
        case .food:
          focusedField = .city
        case .city:
          focusedField = .none
        default:
          print("Default")
        }
      }
      .listStyle(.plain)
      .toolbar {
        Button(action: { presentingProfileScreen.toggle() }) {
          Image(systemName: "person.circle")
        }
      }
      .sheet(isPresented: $presentingProfileScreen) {
        NavigationView {
          WelcomeView()
            .environmentObject(authenticationViewModel)
        }
      }
      .navigationTitle("My Favourites")
      .analyticsScreen(name: "\(MyFavouritesView.self)")
    }
  }
}
