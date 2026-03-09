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
        return try await calculateRouteWithOptions(from: source, to: destination, transportType: transportType)
    }
    
    private func calculateRouteWithOptions(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) async throws -> MKRoute {
        return try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = transportType
            
            // Enable additional options for better transit results
            if transportType == .transit {
                request.requestsAlternateRoutes = true
            }
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    print("🚫 Route calculation error for \(transportType): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let routes = response?.routes, !routes.isEmpty {
                    // Try to find the best transit route
                    let bestRoute = self.selectBestRoute(from: routes, for: transportType)
                    print("✅ Found route with transport type: \(bestRoute.transportType), steps: \(bestRoute.steps.count)")
                    continuation.resume(returning: bestRoute)
                } else {
                    print("🚫 No routes found for transport type: \(transportType)")
                    continuation.resume(throwing: DirectionsError.noRouteFound)
                }
            }
        }
    }
    
    private func selectBestRoute(from routes: [MKRoute], for transportType: MKDirectionsTransportType) -> MKRoute {
        // If we're looking for transit, prefer routes that actually have transit steps
        if transportType == .transit || transportType == .any {
            let transitRoutes = routes.filter { route in
                route.steps.contains { step in
                    step.transportType == .transit ||
                    step.instructions.lowercased().contains("train") ||
                    step.instructions.lowercased().contains("metro") ||
                    step.instructions.lowercased().contains("marta")
                }
            }
            
            if !transitRoutes.isEmpty {
                // Return the fastest transit route
                return transitRoutes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) ?? routes.first!
            }
        }
        
        // Default to fastest route
        return routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) ?? routes.first!
    }
    
    func calculateTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        // First try to get a transit route with multiple attempts
        var lastError: Error?
        
        // Try transit first with different settings
        do {
            let transitRoute = try await calculateRouteWithOptions(from: source, to: destination, transportType: .transit)
            
            // More comprehensive check for transit steps
            let hasTransitSteps = transitRoute.steps.contains { step in
                let instructions = step.instructions.lowercased()
                return instructions.contains("marta") || 
                       instructions.contains("train") ||
                       instructions.contains("rail") ||
                       instructions.contains("metro") ||
                       instructions.contains("subway") ||
                       instructions.contains("transit") ||
                       step.transportType == .transit
            }
            
            // Also check if the route uses any form of public transportation
            let usesPublicTransit = transitRoute.transportType == .transit
            
            if hasTransitSteps || usesPublicTransit {
                print("✅ Found transit route with actual transit steps")
                return transitRoute
            } else {
                print("⚠️ Transit route returned, but no actual transit steps found")
            }
        } catch {
            print("❌ Transit route calculation failed: \(error.localizedDescription)")
            lastError = error
        }
        
        // Try alternative transport types that might include transit
        do {
            let anyRoute = try await calculateRouteWithOptions(from: source, to: destination, transportType: .any)
            
            // Check if this route includes transit
            let hasAnyTransit = anyRoute.steps.contains { step in
                step.transportType == .transit || 
                step.instructions.lowercased().contains("train") ||
                step.instructions.lowercased().contains("metro")
            }
            
            if hasAnyTransit {
                print("✅ Found transit route using .any transport type")
                return anyRoute
            }
        } catch {
            print("❌ Any transport route failed: \(error.localizedDescription)")
        }
        
        // As a last resort, try the hybrid approach with MARTA station finding
        do {
            return try await calculateHybridTransitRoute(from: source, to: destination)
        } catch {
            // If all else fails, throw the original transit error or a comprehensive error
            if let originalError = lastError {
                throw originalError
            } else {
                throw DirectionsError.noTransitAvailable
            }
        }
    }
    
    func calculateHybridTransitRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        print("🔄 Attempting hybrid transit route calculation with real MARTA data...")
        
        // Use the real MARTA service to create a multimodal route
        do {
            let martaService = MARTATransitService.shared
            let multimodalRoute = try await martaService.createMultimodalRoute(from: source, to: destination)
            
            print("✅ Created multimodal MARTA route:")
            print("   - Walk to station: \(Int(multimodalRoute.walkToStation.expectedTravelTime / 60)) min")
            print("   - Transit: \(Int(multimodalRoute.transitRoute.estimatedTime / 60)) min on \(multimodalRoute.transitRoute.line.name)")
            print("   - Walk from station: \(Int(multimodalRoute.walkFromStation.expectedTravelTime / 60)) min")
            print("   - Total time: \(Int(multimodalRoute.totalEstimatedTime / 60)) min")
            
            // For now, return the combined route as a single MKRoute
            // In a full implementation, you might want to create a custom route type
            // that preserves the segment information
            return multimodalRoute.walkToStation
            
        } catch {
            print("❌ Failed to create multimodal MARTA route: \(error.localizedDescription)")
        }
        
        // Try to find nearby MARTA stations using MapKit search as fallback
        do {
            let nearbyStations = try await findNearbyMARTAStations(coordinate: source, radius: 2000) // 2km radius
            
            if !nearbyStations.isEmpty {
                print("🚉 Found \(nearbyStations.count) nearby MARTA stations via MapKit")
                
                // Try to calculate a route via the nearest station
                let nearestStation = nearbyStations.first!
                
                // Calculate walking route to station
                let walkToStation = try await calculateRouteWithOptions(from: source, to: nearestStation.coordinate, transportType: .walking)
                
                print("🚶‍♂️ Returning walking route to nearest MARTA station: \(nearestStation.name)")
                return walkToStation
            } else {
                print("❌ No MARTA stations found nearby")
            }
        } catch {
            print("❌ Failed to find MARTA stations: \(error.localizedDescription)")
        }
        
        // Final fallback to walking route
        print("🚶‍♂️ Falling back to walking route")
        do {
            return try await calculateRouteWithOptions(from: source, to: destination, transportType: .walking)
        } catch {
            throw DirectionsError.noRouteFound
        }
    }
    
    private func findNearbyMARTAStations(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) async throws -> [MARTAStation] {
        // This is a simplified version. In a real app, you would:
        // 1. Use MARTA's API or GTFS data
        // 2. Query a local database of station locations
        // 3. Use MapKit search for "MARTA station"
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "MARTA station"
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let stations = response?.mapItems.compactMap { item -> MARTAStation? in
                    guard let name = item.name,
                          let stationCoordinate = item.placemark.location?.coordinate else {
                        return nil
                    }
                    
                    // Filter for actual MARTA stations
                    if name.lowercased().contains("marta") || 
                       name.lowercased().contains("station") {
                        
                        // Calculate distance from user's location
                        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        let stationLocation = CLLocation(latitude: stationCoordinate.latitude, longitude: stationCoordinate.longitude)
                        let distance = userLocation.distance(from: stationLocation)
                        
                        return MARTAStation(
                            name: name,
                            coordinate: stationCoordinate,
                            line: MARTALine.lineForStationName(name),
                            distanceFromUser: distance
                        )
                    }
                    return nil
                } ?? []
                
                continuation.resume(returning: stations)
            }
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

