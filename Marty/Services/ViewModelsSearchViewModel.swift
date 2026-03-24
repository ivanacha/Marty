//
//  SearchViewModel.swift
//  Marty
//
//  ViewModel responsible only for search functionality
//  Follows single responsibility principle
//

import Foundation
import MapKit
import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    
    private let searchService: SearchServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(searchService: SearchServiceProtocol? = nil) {
        self.searchService = searchService ?? SearchService.shared
    }
    
    func searchLocations(query: String, in region: MKCoordinateRegion? = nil) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                let results = try await searchService.searchLocations(query: query, in: region)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchError = error
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }
    
    func clearResults() {
        searchResults = []
        searchError = nil
    }
    
    func formatAddress(from placemark: MKPlacemark) -> String? {
        var components: [String] = []
        
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            components.append("\(subThoroughfare) \(thoroughfare)")
        } else if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let city = placemark.locality {
            components.append(city)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
