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
        isCalculatingRoute = true
        routeError = nil
        
        Task {
            do {
                // Ensure we have a user location; if not, try to obtain one with a short timeout
                let sourceCoordinate = try await ensureUserCoordinate(timeout: 5.0)
                
                let route = try await directionsService.calculateTransitRoute(
                    from: sourceCoordinate,
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
    
    // MARK: - Private helpers
    
    private func ensureUserCoordinate(timeout: TimeInterval) async throws -> CLLocationCoordinate2D {
        // If we already have a location, use it immediately
        if let coord = locationService.location?.coordinate {
            return coord
        }
        
        // Start updates and await the first non-nil location with a timeout
        locationService.startLocationUpdates()
        
        // Bridge the Combine publisher to async and wait for the first non-nil value
        let coordinate = try await withThrowingTaskGroup(of: CLLocationCoordinate2D.self) { group -> CLLocationCoordinate2D in
            // Task 1: Wait for first non-nil location
            group.addTask { [locationPublisher = locationService.locationPublisher] in
                try await withCheckedThrowingContinuation { continuation in
                    var cancellable: AnyCancellable?
                    cancellable = locationPublisher
                        .compactMap { $0?.coordinate }
                        .first()
                        .sink { _ in
                            // completion ignored; continuation handled on value
                        } receiveValue: { coord in
                            cancellable?.cancel()
                            continuation.resume(returning: coord)
                        }
                }
            }
            
            // Task 2: Timeout
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw RouteError.userLocationUnavailable
            }
            
            // Return whichever finishes first
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
        
        return coordinate
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
