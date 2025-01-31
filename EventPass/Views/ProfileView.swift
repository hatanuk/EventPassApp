//
//  SwiftUIView.swift
//  EventPass

//  Created by Andrew A on 07/08/2024.
//

import SwiftUI
import CoreBluetooth

struct ProfileView: View {
    // reduced form of a CardView which displays basic information that is transmitted over BLE
    
    var user: UserModel
    
    var profileBorderColors: [Color] = [.red, .green, .blue, .pink, .purple, .cyan, .orange, .yellow, .mint, .teal, .brown]
    
    var gradientColors: [Color] {
        [.white, .white]
    }
    
    var textColor: Color {
        .black
    }
    
    
    var body: some View {
                
                VStack {
                    HStack {
                        let url = URL(string: user.profilePictureURL ?? Constants.defaultProfileImageURL)
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } placeholder: {
                                ProgressView()
                            }.overlay {
                                Circle().stroke(profileBorderColors.randomElement() ?? .red, lineWidth: 3)
                            }
                           
                        VStack(alignment: .leading) {
                            if let displayName = user.displayName {
                                Text(displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(textColor)
                                  
               
                            }
                            
                            if let title = user.title {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundColor(textColor)
                               
                            }
                            
                            if let workplace = user.workplace {
                                Text(workplace)
                                    .font(.subheadline)
                                    .foregroundColor(textColor)
                               
                            }
                      
                        }
                        .lineLimit(1)
                        .padding(.leading, 10)
                        
             
                    }
                    .padding([.top, .horizontal])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                 
                }
                
                .background(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottomTrailing))
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding()
                .frame(width: 400, height: 130)
            }
  
    }


#Preview {
    ProfileView(user: UserModel(fromCard: Constants.testProfile))
}
