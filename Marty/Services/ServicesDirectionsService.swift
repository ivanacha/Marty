//
//  DirectionsService.swift
//  Marty
//
//  Service layer for directions and route calculation
//  Optimized for MARTA transit system with fallback to walking
//

import Foundation
import MapKit
import CoreLocation

protocol DirectionsServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) async throws -> MKRoute
    func calculateTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute
    func calculateHybridTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute
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
        // First try to get a transit route
        do {
            let transitRoute = try await calculateRoute(from: source, to: destination, transportType: .transit)
            
            // Check if the route actually contains transit (MARTA) steps
            let hasTransitSteps = transitRoute.steps.contains { step in
                step.instructions.lowercased().contains("marta") || 
                step.instructions.lowercased().contains("train") ||
                step.instructions.lowercased().contains("rail") ||
                step.transportType == .transit
            }
            
            if hasTransitSteps {
                return transitRoute
            } else {
                // If no transit steps found, fall back to hybrid approach
                return try await calculateHybridTransitRoute(from: source, to: destination)
            }
        } catch {
            // If transit route fails, try hybrid approach
            return try await calculateHybridTransitRoute(from: source, to: destination)
        }
    }
    
    func calculateHybridTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        // This is a simplified version - in a real app, you'd want to:
        // 1. Find the nearest MARTA stations to both source and destination
        // 2. Calculate walking routes to/from stations
        // 3. Calculate transit route between stations
        // 4. Combine all segments
        
        // For now, return a walking route as a fallback
        do {
            return try await calculateRoute(from: source, to: destination, transportType: .walking)
        } catch {
            throw DirectionsError.noRouteFound
        }
    }
}

enum DirectionsError: Error, LocalizedError {
    case noRouteFound
    case invalidCoordinates
    case noTransitAvailable
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "No route found for the specified destination"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        case .noTransitAvailable:
            return "No MARTA transit route available. Showing walking directions to nearest station."
        }
    }
}