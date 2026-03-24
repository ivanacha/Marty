//
//  DirectionViewModel.swift
//  Marty
//
//  Main coordinator ViewModel that orchestrates map, search, and route functionality
//  Optimized for faster loading with lazy initialization and dependency injection
//

import Foundation
import MapKit
import Combine
import SwiftUI

@MainActor
final class DirectionViewModel: ObservableObject {
    
    // MARK: - Child ViewModels (Lazy Loading)
    private lazy var _mapViewModel = MapViewModel()
    private lazy var _searchViewModel = SearchViewModel()
    private lazy var _routeViewModel = RouteViewModel()
    
    var mapViewModel: MapViewModel {
        return _mapViewModel
    }
    
    var searchViewModel: SearchViewModel {
        return _searchViewModel
    }
    
    var routeViewModel: RouteViewModel {
        return _routeViewModel
    }
    
    // MARK: - Published Properties (Forwarding from child ViewModels)
    @Published var region: MapCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var currentRoute: RouteInfo?
    @Published var isCalculatingRoute = false
    
    private var cancellables = Set<AnyCancellable>()
    private var bindingsSetUp = false

    init() {}

    private func setupBindings() {
        guard !bindingsSetUp else { return }
        bindingsSetUp = true
        // Forward map region changes
        _mapViewModel.$region
            .receive(on: DispatchQueue.main)
            .assign(to: \.region, on: self)
            .store(in: &cancellables)
        
        // Forward search results
        _searchViewModel.$searchResults
            .receive(on: DispatchQueue.main)
            .assign(to: \.searchResults, on: self)
            .store(in: &cancellables)
        
        _searchViewModel.$isSearching
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSearching, on: self)
            .store(in: &cancellables)
        
        // Forward route information
        _routeViewModel.$currentRoute
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentRoute, on: self)
            .store(in: &cancellables)
        
        _routeViewModel.$isCalculatingRoute
            .receive(on: DispatchQueue.main)
            .assign(to: \.isCalculatingRoute, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Convenience Methods (Delegation)
    func requestLocationPermission() {
        setupBindings()
        mapViewModel.requestLocationPermission()
    }
    
    func startLocationUpdates() {
        setupBindings()
        mapViewModel.startLocationUpdates()
    }
    
    func centerOnUserLocation() {
        mapViewModel.centerOnUserLocation()
    }
    
    func searchLocation(query: String) {
        // MapCameraPosition is not destructurable; derive a region from the current user location if available.
        if let userLocation = mapViewModel.userLocation {
            let currentRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            searchViewModel.searchLocations(query: query, in: currentRegion)
        } else {
            searchViewModel.searchLocations(query: query)
        }
    }
    
    func getDirections(to destination: CLLocationCoordinate2D, destinationName: String? = nil) {
        routeViewModel.calculateRoute(to: destination, destinationName: destinationName)
    }
    
    func navigateToSavedLocation(type: LocationType) {
        routeViewModel.navigateToSavedLocation(type: type)
    }
    
    func clearRoute() {
        routeViewModel.clearRoute()
    }
    
    func formatAddress(from placemark: MKPlacemark) -> String? {
        return searchViewModel.formatAddress(from: placemark)
    }
}
