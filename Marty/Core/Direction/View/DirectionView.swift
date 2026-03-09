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
    
    // Route related properties
    @State private var showRoute = false
    @State private var routeDisplaying = false
    
    // Computed property to bridge FocusState to Binding
    private var isSearchFieldFocusedBinding: Binding<Bool> {
        Binding(
            get: { isSearchFieldFocused },
            set: { isSearchFieldFocused = $0 }
        )
    }
    
    // Explicit binding to the view model's region to avoid dynamicMember wrapper issues
    private var regionBinding: Binding<MapCameraPosition> {
        Binding<MapCameraPosition>(
            get: { viewModel.region },
            set: { viewModel.region = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Background Map
            Map(position: regionBinding) {
                UserAnnotation()
                    .tint(.blue)
                
                // Display route segments if available
                if let currentRoute = viewModel.currentRoute {
                    // Destination marker
                    Marker(currentRoute.destinationName ?? "Destination", coordinate: currentRoute.destination)
                        .tint(.red)
                    
                    // Route segments with color coding
                    ForEach(currentRoute.segments) { segment in
                        MapPolyline(segment.polyline)
                            .stroke(segment.type.color, style: segment.type.strokeStyle)
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                // Allow free camera movement - don't force back to user location
            }
            .safeAreaPadding(.top)
            .onAppear {
                // Request location permission and start location updates when view appears
                viewModel.requestLocationPermission()
                viewModel.startLocationUpdates()
            }
            .onChange(of: viewModel.currentRoute?.id) { oldValue, newValue in
                // Adjust map region when route is calculated
                if let route = viewModel.currentRoute {
                    let rect = route.route.polyline.boundingMapRect
                    let region = MKCoordinateRegion(rect)
                    // Add some padding to the region
                    let expandedRegion = MKCoordinateRegion(
                        center: region.center,
                        span: MKCoordinateSpan(
                            latitudeDelta: region.span.latitudeDelta * 1.2,
                            longitudeDelta: region.span.longitudeDelta * 1.2
                        )
                    )
                    viewModel.region = .region(expandedRegion)
                }
            }
            
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
                            // Hide quick access cards immediately when user starts typing
                            if !newValue.isEmpty {
                                showingSearchResults = true
                            } else if !isSearchFieldFocused {
                                showingSearchResults = false
                            }
                            // Perform the search
                            viewModel.searchLocation(query: newValue)
                        }
                        .onChange(of: isSearchFieldFocused) { oldValue, newValue in
                            showingSearchResults = newValue
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchResults = []
                            isSearchFieldFocused = false
                            showingSearchResults = false
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
                if let currentRoute = viewModel.currentRoute {
                    // Route Information Card
                    RouteInfoCard(routeInfo: currentRoute, onClearRoute: {
                        viewModel.clearRoute()
                        showRoute = false
                    })
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else if viewModel.isCalculatingRoute {
                    // Loading state for route calculation
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Calculating MARTA route...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else {
                    // Quick Access Cards
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            QuickAccessCard(
                                icon: "house.fill",
                                title: "Home",
                                color: Color.orange
                            ) {
                                // Navigate to home
                                viewModel.navigateToSavedLocation(type: .home)
                            }

                            QuickAccessCard(
                                icon: "briefcase.fill",
                                title: "Work",
                                color: Color.yellow
                            ) {
                                // Navigate to work
                                viewModel.navigateToSavedLocation(type: .work)
                            }

                            QuickAccessCard(
                                icon: "plus",
                                title: "",
                                color: Color.teal
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

                                Image(systemName: "exclamationmark.triangle")
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
