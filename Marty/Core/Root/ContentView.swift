//
//  ContentView.swift
//  Marty
//
//  Created by iVan on 10/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        Group {
            // Later modification should be done to display proper homepage if the user is signed in
            /*
             if viewModel.userSession != nil {
                             // If the user is signed in show TabView
                             HomeTabView()
                         } else {
                             LoginView()
                         }
             
             */
            MartyTabView()
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
