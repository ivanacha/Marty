//
//  DirectionView.swift
//  Marty
//  Direction feature for navigating to locations using MARTA transit
//  Created by iVan on 10/13/25.
//

import SwiftUI
import MapKit

struct DirectionView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880), // Atlanta
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var savedLocations: [SavedLocation] = []
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background Map
            Map(position: $region) {
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
                            searchLocation(query: newValue)
                        }
                        .onChange(of: isSearchFieldFocused) { oldValue, newValue in
                            showingSearchResults = newValue
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
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
                            navigateToSavedLocation(type: .home)
                        }
                        
                        QuickAccessCard(
                            icon: "briefcase.fill",
                            title: "Work",
                            color: Color.blue
                        ) {
                            // Navigate to work
                            navigateToSavedLocation(type: .work)
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
                            if isSearching {
                                ProgressView()
                                    .padding()
                            }

                            if !searchText.isEmpty && !searchResults.isEmpty {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(searchResults, id: \.self) { item in
                                            Button(action: {
                                                if let coordinate = item.placemark.coordinate as CLLocationCoordinate2D? {
                                                    getDirections(to: coordinate)
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
                                                    if let formattedAddress = formatAddress(from: item.placemark) {
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
                            } else if !searchText.isEmpty && !isSearching {
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
        .onChange(of: locationManager.location) { oldValue, newLocation in
            if let location = newLocation {
                region = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
    
    private func navigateToSavedLocation(type: LocationType) {
        // Implement navigation to saved location
        if let savedLocation = savedLocations.first(where: { $0.type == type }) {
            getDirections(to: savedLocation.coordinate)
        } else {
            // Prompt user to set up the location
        }
    }
    
    private func getDirections(to destination: CLLocationCoordinate2D) {
        guard let userLocation = locationManager.location?.coordinate else {
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .transit // For MARTA transit
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Directions error: \(error.localizedDescription)")
                return
            }
            
            guard let route = response?.routes.first else { return }
            // Handle route - navigate to directions display view
            print("Route found: \(route.distance) meters, \(route.expectedTravelTime) seconds")
            parseTransitSteps(route: route)
        }
    }
    
    func parseTransitSteps(route: MKRoute) {
        for step in route.steps {
            if let transitInstructions = step.instructions as String? {
                // Check if it's a MARTA route
                if transitInstructions.contains("MARTA") {
                    print("MARTA Step: \(transitInstructions)")
                    // Extract line color, station names, etc.
                }
            }
        }
    }

    private func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // Focus on Atlanta area for MARTA
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }

    private func formatAddress(from placemark: MKPlacemark) -> String? {
        var components: [String] = []

        // Add street address (thorough fare + sub thorough fare if available)
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            components.append("\(subThoroughfare) \(thoroughfare)")
        } else if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }

        // Add city (locality)
        if let city = placemark.locality {
            components.append(city)
        }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}


#Preview {
    DirectionView()
}
