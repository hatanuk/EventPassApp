//
//  SwiftUIView.swift
//  EventPass

//  Created by Andrew A on 07/08/2024.
//

import SwiftUI

struct ProfileView: View {
    var profile: CardProfile
    
    var profileBorderColors: [Color] = [.red, .green, .blue, .pink, .purple, .cyan, .orange, .yellow, .mint, .teal, .brown]
    
    var gradientColors: [Color] {
        [.white, .white]
    }
    
    var textColor: Color {
        .black
    }
    
    
    var body: some View {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width * 0.9
                let cardHeight = cardWidth / 1.7
                
                VStack {
                    HStack {
                        let url = URL(string: profile.profilePictureURL ?? Constants.defaultProfileImageURL)
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
                            if let displayName = profile.displayName {
                                Text(displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(textColor)
                                  
          
               
                            }
                            
                            if let title = profile.title {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundColor(textColor)
                               
                            }
                            
                            if let workplace = profile.workplace {
                                Text(workplace)
                                    .font(.subheadline)
                                    .foregroundColor(textColor)
                               
                            }
                        }
                        .lineLimit(1)
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding([.top, .horizontal])
                    
                    Divider()
                 
                }
                
                .background(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottomTrailing))
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding()
                .frame(width: cardWidth, height: cardHeight)
            }
  
        }
    }

#Preview {
    ProfileView(profile: Constants.testProfile)
}
