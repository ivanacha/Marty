//
//  SearchResultsView.swift
//  Marty
//
//  Created by iVan on 10/14/25.
//

import SwiftUI
import MapKit

struct SearchResultsView: View {
    @Binding var searchText: String
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    let onLocationSelected: (CLLocationCoordinate2D) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Search field
                TextField("Search for a place", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { oldValue, newValue in
                        searchLocation(query: newValue)
                    }
                
                if isSearching {
                    ProgressView()
                        .padding()
                }
                
                List(searchResults, id: \.self) { item in
                    Button(action: {
                        if let coordinate = item.placemark.coordinate as CLLocationCoordinate2D? {
                            onLocationSelected(coordinate)
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                                .lineLimit(1)
                            if let formattedAddress = formatAddress(from: item.placemark) {
                                Text(formattedAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
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
