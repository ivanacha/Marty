//
//  MartyTabView.swift
//  Marty
//
//  Created by iVan on 10/10/25.
//

import SwiftUI

struct MartyTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @State private var showTicket = false
    @State private var recentlySelectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DirectionView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "location.fill" : "location")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Directions")
                }
                .onAppear { selectedTab = 0 }
                .tag(0)
            
            //ExploreView()
            Text("Second Tab")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Maps")
                }
                .onAppear { selectedTab = 1 }
                .tag(1)
            
            Text("")
                .tabItem {
                    Image(systemName: "ticket")
                }
                .onAppear { selectedTab = 2 }
                .tag(2)
            
            //ActivityView()
            Text("Third Tab")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                }
                .onAppear { selectedTab = 3 }
                .tag(3)
            
            //CurrentUserProfileView()
            Text("User Profile")
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                }
                .onAppear { selectedTab = 4 }
                .tag(4)

        }
        .onChange(of: selectedTab) { newValue, _ in
            recentlySelectedTab = newValue
            if selectedTab == 2 {
                showTicket = true
            }
        }
        .sheet(isPresented: $showTicket, onDismiss: {
            selectedTab = recentlySelectedTab
        }, content: {
//            Ticket `View
        })
        .tint(.black)
    }
}

#Preview {
    MartyTabView()
}
