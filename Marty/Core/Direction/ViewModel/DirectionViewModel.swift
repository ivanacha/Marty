//
//  DirectionViewModel.swift
//  Marty
//
//  Created by iVan on 10/15/25.
//

import Foundation
import MapKit
import Combine
import SwiftUI

@MainActor
class DirectionViewModel: ObservableObject {
    
    // The ModelView should include all the functions executed in the main View.
    @Published private var savedLocations: [SavedLocation] = []
    @Published var locationManager = LocationManager()
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var currentRoute: RouteInfo?
    @Published var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880), // Atlanta
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe location changes and update region
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateRegion(with: location)
            }
            .store(in: &cancellables)
    }

    private func updateRegion(with location: CLLocation) {
        region = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func navigateToSavedLocation(type: LocationType) {
        // Implement navigation to saved location
        if let savedLocation = savedLocations.first(where: { $0.type == type }) {
            getDirections(to: savedLocation.coordinate, destinationName: savedLocation.address)
        } else {
            // Prompt user to set up the location
        }
    }

    func getDirections(to destination: CLLocationCoordinate2D, destinationName: String? = nil) {
        guard let userLocation = locationManager.location?.coordinate else {
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .transit // For MARTA transit

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            Task { @MainActor in
                if let error = error {
                    print("Directions error: \(error.localizedDescription)")
                    // Could set an error state here
                    return
                }

                guard let route = response?.routes.first else {
                    print("No routes found")
                    return
                }

                // Store the route information
                self.currentRoute = RouteInfo(
                    route: route,
                    destination: destination,
                    destinationName: destinationName
                )
            }
        }
    }

    func clearRoute() {
        currentRoute = nil
    }
    
    func formatAddress(from placemark: MKPlacemark) -> String? {
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

    func searchLocation(query: String) {
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
            Task { @MainActor in
                self.isSearching = false
                if let response = response {
                    self.searchResults = response.mapItems
                }
            }
        }
    }

}
