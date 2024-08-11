//
//  FormView.swift
//  EventPass
//
//  Created by Andrew A on 10/08/2024.
//

import SwiftUI


extension View {
    
    // This constructs an input element used for user-submitted information such as username, password, etc.
    func InputElement(_ label: String, binding: Binding<String>, maxChar: Int = 30, secure:
                      Bool = false) -> some View {
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
