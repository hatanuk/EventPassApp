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
    var profile: CardProfile
    @State var theme: ColorThemes = .coolBlue
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.9
            let cardHeight = cardWidth / 1.6

            VStack {
                cardHeader()
                Divider().background(theme.textColor)
                    .padding(.bottom, 8)
                cardFooter()
            }
            .padding()
            .frame(width: cardWidth, height: cardHeight)
            .background(LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottomTrailing))
            .cornerRadius(10)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func cardHeader() -> some View {
        HStack(spacing: 12) {
            if let urlString = profile.profilePictureURL, let url = URL(string: urlString) {
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
        VStack(alignment: .leading, spacing: 10) {
            if let displayName = profile.displayName {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            
            if let title = profile.title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
            }
            
            if let workplace = profile.workplace {
                Text(workplace)
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
            }
        }
    }
    
    private func cardFooter() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let email = profile.email {
                HStack {
                    Image(systemName: "envelope")
                    Text(email)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(theme.textColor)
            }
            
            if let phone = profile.phone {
                HStack {
                    Image(systemName: "phone")
                    Text(phone)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(theme.textColor)
            }
        }
    }
}

#Preview {
    VStack {
        CardView(profile: Constants.testProfile)
        CardView(profile: Constants.testProfile2)
    }
   
}
