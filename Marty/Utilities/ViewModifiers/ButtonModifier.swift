//
//  ButtonModifier.swift
//  Marty
//
//  Created by iVan on 10/10/25.
//

import SwiftUI

struct ButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .fontWeight(.semibold)
            .frame(width: 350, height: 40)
            .background(colorScheme == .dark ? .white : .black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
