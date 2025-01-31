//
//  FormView.swift
//  EventPass
//
//  Created by Andrew A on 10/08/2024.
//

import SwiftUI


extension View {
    // miscellanous view structures for reusability accross multiple views
    
    // this constructs an input element used for user-submitted information such as username, password, etc.
    func InputElement(_ label: String, binding: Binding<String>, maxChar: Int = 30, keyboardType: UIKeyboardType = .default, secure: Bool = false) -> some View {
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
            binding.wrappedValue = newValue.trimmedTo(maxBytes: maxChar)
        }
        .keyboardType(keyboardType)
        .padding(.horizontal, 30)
        .padding(.bottom, 50)
        

    }
    
    // toolbar item that dismisses the current view
    func ToolbarCancelView(_ presentationMode: Binding<PresentationMode>) -> some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark.circle")
                .font(.title)
                .padding()
                .foregroundColor(.red)
        }
    }
    
    func ToolbarCancelViewWithConfirmation(_ presentationMode: Binding<PresentationMode>, _ showConfirmation: Binding<Bool>) -> some View {
        Button(action: {
            showConfirmation.wrappedValue = true
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .padding()
                .foregroundColor(.red)
        }
    }
    
    func ToolbarTitleView(_ title: String, size: CGFloat = 40) -> some View {
        Text(title)
            .font(.system(size: size, weight: .bold, design: .default))
            .foregroundColor(.primary)
            
    }
    
    @ViewBuilder
    func formSection(header: String, binding: Binding<String>, maxChar: Int = 30, keyboardType: UIKeyboardType = .default, numeric: Bool = false) -> some View {
            Section(header) {
                TextField("", text: binding)
                    .onChange(of: binding.wrappedValue) {
                        var updatedText = binding.wrappedValue
                        if numeric {
                            updatedText = binding.wrappedValue.filter { "0123456789".contains($0) }
                        }
                        if updatedText.count > maxChar {
                            binding.wrappedValue = String(updatedText.prefix(maxChar))
                        } else {
                            binding.wrappedValue = updatedText
                        }
                    }
                    .keyboardType(keyboardType)
            }
        }
   
}



struct TabBarView: View {
    @Binding var selectedTab: Int
    let tabs: [(String, String)]
    
    // tabs must be given in the format (title, imageSystemName)
    init(selectedTab: Binding<Int>, tabs: [(String, String)]) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        
    }
    
    
    var body: some View {
        
        HStack {
            ForEach(tabs.indices, id: \.self) { index in
                let (title, imageSystemName) = tabs[index]
                Button(action: {
                    selectedTab = index
                }) {
                    VStack {
                        Image(systemName: selectedTab == index ? "\(imageSystemName).fill" : imageSystemName)
                            .resizable()
                            .scaledToFit()
                        Text(title)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 100)
                if index < tabs.count - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 30)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}


