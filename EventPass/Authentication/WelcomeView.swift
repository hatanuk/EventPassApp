//
//  WelcomeView.swift
//  EventPass
//
//  Created by Andrew A on 12/06/2024.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            
        }.navigationTitle("Welcome")
            
            
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
