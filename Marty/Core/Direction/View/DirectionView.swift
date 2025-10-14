//
//  DirectionView.swift
//  Marty
//
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
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 12)
                    
                    TextField("Where you going twin?", text: $searchText)
                        .padding(.vertical, 16)
                        .onTapGesture {
                            showingSearchResults = true
                        }
                    
                    Spacer()
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()
                
                Spacer()
                
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
                    
                    // Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GOOD TO KNOW")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Cardboard tickets are soon to be a thing of the past! Information and alternatives")
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
        .sheet(isPresented: $showingSearchResults) {
            SearchResultsView(
                searchText: $searchText,
                onLocationSelected: { location in
                    getDirections(to: location)
                    showingSearchResults = false
                }
            )
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
}


#Preview {
    DirectionView()
}
