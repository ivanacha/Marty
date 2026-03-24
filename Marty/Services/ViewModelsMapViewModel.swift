//
//  MapViewModel.swift
//  Marty
//
//  ViewModel responsible for map display and camera positioning
//  Optimized with lazy loading and efficient updates
//

import Foundation
import MapKit
import SwiftUI
import CoreLocation
import Combine

@MainActor
final class MapViewModel: ObservableObject {
    @Published var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var hasInitiallyPositioned = false
    
    // Designated initializer without default argument to avoid nonisolated evaluation
    init(locationService: LocationServiceProtocol) {
        self.locationService = locationService
        setupLocationObservers()
    }
    
    // Convenience initializer that resolves the default dependency on the main actor
    convenience init() {
        self.init(locationService: ServiceContainer.shared.locationService)
    }
    
    private func setupLocationObservers() {
        // Observe location updates
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.userLocation = location
                if let location = location {
                    self?.updateRegionForLocation(location)
                }
            }
            .store(in: &cancellables)
        
        // Observe authorization changes
        locationService.authorizationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
            .store(in: &cancellables)
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func startLocationUpdates() {
        locationService.startLocationUpdates()
    }
    
    private func updateRegionForLocation(_ location: CLLocation) {
        guard !hasInitiallyPositioned else { return }
        
        hasInitiallyPositioned = true
        
        // Position user location in upper portion of screen
        let offsetLatitude = location.coordinate.latitude - 0.003
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: offsetLatitude,
            longitude: location.coordinate.longitude
        )
        
        let newRegion = MKCoordinateRegion(
            center: adjustedCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        region = .region(newRegion)
    }
    
    func centerOnUserLocation() {
        guard let location = userLocation else {
            startLocationUpdates()
            return
        }
        
        let offsetLatitude = location.coordinate.latitude - 0.003
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: offsetLatitude,
            longitude: location.coordinate.longitude
        )
        
        let newRegion = MKCoordinateRegion(
            center: adjustedCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        region = .region(newRegion)
    }
    
    func setRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)) {
        let newRegion = MKCoordinateRegion(center: center, span: span)
        region = .region(newRegion)
    }
}
