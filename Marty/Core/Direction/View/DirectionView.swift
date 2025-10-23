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
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(viewModel.searchResults, id: \.self) { item in
                                            Button(action: {
                                                if let coordinate = item.placemark.coordinate as CLLocationCoordinate2D? {
                                                    viewModel.getDirections(to: coordinate)
                                                    searchText = ""
                                                    showingSearchResults = false
                                                    isSearchFieldFocused = false
                                                }
                                            }) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.name ?? "Unknown")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                    if let formattedAddress = viewModel.formatAddress(from: item.placemark) {
                                                        Text(formattedAddress)
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding()
                                            }
                                            Divider()
                                        }
                                    }
                                }
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


#Preview {
    DirectionView()
}
