//
//  SwiftUIView.swift
//  EventPass
//
//  Created by Andrew A on 04/08/2024.
//

import SwiftUI

enum ColorThemes {
    case midnight
    case sunset
    case coolBlue
    
    var gradientColors: [Color] {
        switch self {
        case .coolBlue:
            return [.blue, .cyan]
        case .midnight:
            return [.black, .blue]
        case .sunset:
            return [.red, .orange]
        }
    }
    
    var textColor: Color {
        switch self {
        case .coolBlue:
            return .white
        case .midnight:
            return .white
        case .sunset:
            return .white
        }
    }
}

struct CardView: View {
    var profile: CardProfile
    
    
    @State var theme: ColorThemes = .coolBlue
    
    var gradientColors: [Color] {
        theme.gradientColors
    }
    
    var textColor: Color {
        theme.textColor
    }
    
    
    var body: some View {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width * 0.9
                let cardHeight = cardWidth / 1.7
                
                VStack {
                    HStack {
                        if let urlString = profile.profilePictureURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } placeholder: {
                                ProgressView()
                            }
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
                                    .lineLimit(1)
                            }
                            
                            if let workplace = profile.workplace {
                                Text(workplace)
                                    .font(.subheadline)
                                    .foregroundColor(textColor)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding([.top, .horizontal])
                    
                    Divider()
                 
                    
                    VStack(alignment: .leading, spacing: 5) {   Spacer()
                        if let email = profile.email {
                            HStack {
                                Image(systemName: "envelope")
                                Text(email)
                                    .lineLimit(1)
                            }
                            .font(.subheadline)
                            .foregroundColor(textColor)
                        }
                        
                        if let phone = profile.phone {
                            HStack {
                                Image(systemName: "phone")
                                Text(phone)
                                    .lineLimit(1)
                            }
                            .font(.subheadline)
                            .foregroundColor(textColor)
                        }
                    }
                    .padding([.bottom, .horizontal])
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
    CardView(profile: Constants.testProfile)
}
