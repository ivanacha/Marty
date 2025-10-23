//
//  DirectionView.swift
//  Marty
//  Direction feature for navigating to locations using MARTA transit
//  Created by iVan on 10/13/25.
//

import SwiftUI
import MapKit

struct DirectionView: View {
    @StateObject var viewModel = DirectionViewModel()
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Computed property to bridge FocusState to Binding
    private var isSearchFieldFocusedBinding: Binding<Bool> {
        Binding(
            get: { isSearchFieldFocused },
            set: { isSearchFieldFocused = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Background Map
            Map(position: $viewModel.region) {
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            // Foreground UI
            VStack(spacing: 0) {
                Spacer()
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 12)

                    TextField("Where do you want to go?", text: $searchText)
                        .padding(.vertical, 16)
                        .focused($isSearchFieldFocused)
                        .onChange(of: searchText) { oldValue, newValue in
                            viewModel.searchLocation(query: newValue)
                        }
                        .onChange(of: isSearchFieldFocused) { oldValue, newValue in
                            showingSearchResults = newValue
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchResults = []
//                            isSearchFieldFocused = false
//                            showingSearchResults = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()


                // Show directions if available, otherwise show quick access and search
                if let routeInfo = viewModel.currentRoute {
                    // Directions Display
                    DirectionsDisplayView(viewModel: viewModel, routeInfo: routeInfo)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                } else {
                    // Quick Access Cards
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            QuickAccessCard(
                                icon: "house.fill",
                                title: "Home",
                                color: Color.blue
                            ) {
                                // Navigate to home
                                viewModel.navigateToSavedLocation(type: .home)
                            }

                            QuickAccessCard(
                                icon: "briefcase.fill",
                                title: "Work",
                                color: Color.blue
                            ) {
                                // Navigate to work
                                viewModel.navigateToSavedLocation(type: .work)
                            }

                            QuickAccessCard(
                                icon: "plus",
                                title: "",
                                color: Color.blue
                            ) {
                                // Add new location
                            }
                        }
                        .padding(.horizontal)

                        // Info Card or Search Results
                        if showingSearchResults {
                            // Inline Search Results
                            VStack(spacing: 0) {
                                if viewModel.isSearching {
                                    ProgressView()
                                        .padding()
                                }

                                if !searchText.isEmpty && !viewModel.searchResults.isEmpty {
                                    SearchResultsView(
                                        viewModel: viewModel,
                                        searchText: $searchText,
                                        showingSearchResults: $showingSearchResults,
                                        isSearchFieldFocused: isSearchFieldFocusedBinding
                                    )
                                    .frame(maxHeight: 300)
                                } else if !searchText.isEmpty && !viewModel.isSearching {
                                    Text("No results found")
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        } else {
                            // Info Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("GOOD TO KNOW")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)

                                Text("Physical tickets are soon to be a thing of the past! Information and alternatives")
                                    .font(.body)

                                Image(systemName: "ticket")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
    }

}


#Preview {
    DirectionView()
}
