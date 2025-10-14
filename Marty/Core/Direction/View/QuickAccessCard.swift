//
//  QuickAccessCard.swift
//  Marty
//
//  Created by iVan on 10/14/25.
//

import SwiftUI

struct QuickAccessCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if title.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    QuickAccessCard(
        icon: "house.fill",
        title: "Home",
        color: Color.blue
    ) {
        // Navigate to home
    }
}
