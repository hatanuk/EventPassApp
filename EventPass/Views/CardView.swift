//
//  SwiftUIView.swift
//  EventPass
//
//  Created by Andrew A on 04/08/2024.
//

import SwiftUI
import PhoneNumberKit


enum ColorThemes: String, CaseIterable {
    case midnight
    case sunset
    case coolBlue
    
    init(id: Int) {
            switch id {
            case 0:
                self = .coolBlue
            case 1:
                self = .sunset
            case 2:
                self = .midnight
            default:
                self = Constants.defaultColorTheme
            }
        }
    
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
        case .coolBlue, .midnight, .sunset:
            return .white
        }
    }
    
    var id: Int {
            switch self {
            case .coolBlue:
                return 0
            case .sunset:
                return 1
            case .midnight:
                return 2
            }
        }
}


struct CardView: View {
    var card: CardProfile

    
    var body: some View {
      

            VStack {
                cardHeader()
                Divider().background(card.theme.textColor)
                    .padding(.bottom, 8)
                cardFooter()
            }
            .padding()
            .frame(width: 350, height: 200)
            .background(LinearGradient(colors: card.theme.gradientColors, startPoint: .top, endPoint: .bottomTrailing))
            .cornerRadius(10)
            .shadow(radius: 10)
        
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func cardHeader() -> some View {
        HStack(spacing: 12) {
            
            let urlString = card.profilePictureURL ?? Constants.defaultProfileImageURL
            if let url = URL(string: urlString) {
               AsyncImage(url: url) { image in
                   image
                       .resizable()
                       .aspectRatio(contentMode: .fill)
                       .frame(width: 70, height: 70)
                       .clipShape(Circle())
                       .shadow(radius: 5)
               } placeholder: {
                   ProgressView()
               }
           }
           
           profileDetails()
           Spacer()
       }
    }
    
    
    
    private func profileDetails() -> some View {
        
        // In case displayName is not defined, either use
        // the user's firstName + lastName, or a default
        var fallback: String
        if let firstName = card.firstName, let lastName = card.lastName {
            fallback = firstName + " " + lastName
        } else {
            fallback = Constants.unspecifiedDisplayName
        }
        
        return VStack(alignment: .leading, spacing: 10) {
            
            let displayName = card.displayName ?? fallback
            Text(displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(card.theme.textColor)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            if let title = card.title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(card.theme.textColor)
                    .lineLimit(1)
            }
            
            if let workplace = card.workplace {
                Text(workplace)
                    .font(.subheadline)
                    .foregroundColor(card.theme.textColor)
                    .lineLimit(1)
            }
        }
    }
    
    private func cardFooter() -> some View {
        // Phone number parsing using PhoneNumberKit
            
        return VStack(alignment: .leading, spacing: 4) {
            if let email = card.email {
                HStack {
                    Image(systemName: "envelope")
                    Text(email)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(card.theme.textColor)
            }
            
            if let phone = card.phone {
                
                HStack {
                    Image(systemName: "phone")
                    Text(PartialFormatter().formatPartial("+" + phone) )
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(card.theme.textColor)
            }
        }
    }
}

#Preview {
    VStack {
        CardView(card: Constants.testProfile)
        CardView(card: Constants.testProfile2)
    }
   
}
