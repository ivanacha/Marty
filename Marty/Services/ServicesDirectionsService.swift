//
//  DirectionsService.swift
//  Marty
//
//  Service layer for directions and route calculation
//  Optimized for MARTA transit system
//

import Foundation
import MapKit
import CoreLocation

protocol DirectionsServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) async throws -> MKRoute
    func calculateTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute
}

final class DirectionsService: DirectionsServiceProtocol {
    static let shared = DirectionsService()
    
    private init() {}
    
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType = .transit) async throws -> MKRoute {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = transportType
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let route = response?.routes.first {
                    continuation.resume(returning: route)
                } else {
                    continuation.resume(throwing: DirectionsError.noRouteFound)
                }
            }
        }
    }
    
    func calculateTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        return try await calculateRoute(from: source, to: destination, transportType: .transit)
    }
}

enum DirectionsError: Error, LocalizedError {
    case noRouteFound
    case invalidCoordinates
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "No route found for the specified destination"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        }
    }
}