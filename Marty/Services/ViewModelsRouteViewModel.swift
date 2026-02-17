//
//  RouteViewModel.swift
//  Marty
//
//  ViewModel responsible for route calculation and navigation
//  Separated from map and search concerns
//

import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
final class RouteViewModel: ObservableObject {
    @Published var currentRoute: RouteInfo?
    @Published var isCalculatingRoute = false
    @Published var routeError: Error?
    @Published var savedLocations: [SavedLocation] = []
    
    private let directionsService: DirectionsServiceProtocol
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Designated initializer for dependency injection (no default args to avoid isolation issues)
    init(
        directionsService: DirectionsServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.directionsService = directionsService
        self.locationService = locationService
    }
    
    // Convenience initializer resolving shared instances on the main actor
    convenience init() {
        self.init(
            directionsService: DirectionsService.shared,
            locationService: LocationService.shared
        )
    }
    
    func calculateRoute(to destination: CLLocationCoordinate2D, destinationName: String? = nil) {
        guard let userLocation = locationService.location?.coordinate else {
            routeError = RouteError.userLocationUnavailable
            return
        }
        
        isCalculatingRoute = true
        routeError = nil
        
        Task {
            do {
                let route = try await directionsService.calculateTransitRoute(
                    from: userLocation,
                    to: destination
                )
                
                await MainActor.run {
                    self.currentRoute = RouteInfo(
                        route: route,
                        destination: destination,
                        destinationName: destinationName
                    )
                    self.isCalculatingRoute = false
                }
            } catch {
                await MainActor.run {
                    self.routeError = error
                    self.isCalculatingRoute = false
                }
            }
        }
    }
    
    func navigateToSavedLocation(type: LocationType) {
        guard let savedLocation = savedLocations.first(where: { $0.type == type }) else {
            routeError = RouteError.savedLocationNotFound
            return
        }
        
        calculateRoute(to: savedLocation.coordinate, destinationName: savedLocation.address)
    }
    
    func clearRoute() {
        currentRoute = nil
        routeError = nil
    }
    
    func addSavedLocation(_ location: SavedLocation) {
        // Remove existing location of the same type
        savedLocations.removeAll { $0.type == location.type }
        savedLocations.append(location)
        // TODO: Persist to SwiftData
    }
    
    func removeSavedLocation(type: LocationType) {
        savedLocations.removeAll { $0.type == type }
        // TODO: Update SwiftData
    }
}

enum RouteError: Error, LocalizedError {
    case userLocationUnavailable
    case savedLocationNotFound
    
    var errorDescription: String? {
        switch self {
        case .userLocationUnavailable:
            return "User location is not available. Please enable location services."
        case .savedLocationNotFound:
            return "Saved location not found. Please set up the location first."
        }
    }
}
