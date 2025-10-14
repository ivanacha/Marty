//
//  TicketView.swift
//  Marty
//
//  Created by iVan on 10/11/25.
//

import SwiftUI

struct TicketView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.black)
            }
        }
        
    }
}

#Preview {
    TicketView()
}
