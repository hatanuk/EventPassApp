//
//  HubView.swift
//  EventPass
//
//  Created by Andrew A on 02/08/2024.
//

import SwiftUI

struct CardView: View {
    var body: some View {
    
        ZStack{
            
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.red, .cyan], startPoint: .top, endPoint: .bottomTrailing))
            
            
            RoundedRectangle(cornerRadius: 0)
                .size(CGSize(width: 70, height: 70))
                .padding()
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            
        
              
        }
        .frame(width:250, height:150)
        .scaleEffect(1.5)
    }
}

#Preview {
    CardView()
}
