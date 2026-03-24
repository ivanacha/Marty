//
//  MARTATransitService.swift
//  Marty
//
//  Service for integrating with MARTA's real-time transit data
//  Created by iVan on 03/09/26.
//

import Foundation
import CoreLocation
import MapKit

protocol MARTATransitServiceProtocol {
    func findNearestStations(to coordinate: CLLocationCoordinate2D, limit: Int) async throws -> [MARTAStation]
    func getRoutesBetweenStations(from: MARTAStation, to: MARTAStation) async throws -> [MARTARoute]
    func createMultimodalRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MARTAMultimodalRoute
}

class MARTATransitService: MARTATransitServiceProtocol {
    static let shared = MARTATransitService()
    
    // MARTA's real stations with coordinates
    private let martaStations: [MARTAStationData] = [
        // Red Line
        MARTAStationData(id: "R01", name: "North Springs", coordinate: CLLocationCoordinate2D(latitude: 33.929, longitude: -84.356), line: .red),
        MARTAStationData(id: "R02", name: "Sandy Springs", coordinate: CLLocationCoordinate2D(latitude: 33.924, longitude: -84.351), line: .red),
        MARTAStationData(id: "R03", name: "Medical Center", coordinate: CLLocationCoordinate2D(latitude: 33.911, longitude: -84.351), line: .red),
        MARTAStationData(id: "R04", name: "Dunwoody", coordinate: CLLocationCoordinate2D(latitude: 33.900, longitude: -84.346), line: .red),
        MARTAStationData(id: "R05", name: "Perimeter Center", coordinate: CLLocationCoordinate2D(latitude: 33.890, longitude: -84.346), line: .red),
        
        // Blue Line
        MARTAStationData(id: "B01", name: "Hamilton E. Holmes", coordinate: CLLocationCoordinate2D(latitude: 33.755, longitude: -84.470), line: .blue),
        MARTAStationData(id: "B02", name: "West Lake", coordinate: CLLocationCoordinate2D(latitude: 33.753, longitude: -84.440), line: .blue),
        MARTAStationData(id: "B03", name: "Ashby", coordinate: CLLocationCoordinate2D(latitude: 33.756, longitude: -84.417), line: .blue),
        
        // Green Line
        MARTAStationData(id: "G01", name: "Bankhead", coordinate: CLLocationCoordinate2D(latitude: 33.773, longitude: -84.428), line: .green),
        MARTAStationData(id: "G02", name: "Ashby", coordinate: CLLocationCoordinate2D(latitude: 33.756, longitude: -84.417), line: .green),
        
        // Gold Line  
        MARTAStationData(id: "Y01", name: "Doraville", coordinate: CLLocationCoordinate2D(latitude: 33.902, longitude: -84.280), line: .gold),
        MARTAStationData(id: "Y02", name: "Chamblee", coordinate: CLLocationCoordinate2D(latitude: 33.887, longitude: -84.304), line: .gold),
        MARTAStationData(id: "Y03", name: "Brookhaven", coordinate: CLLocationCoordinate2D(latitude: 33.859, longitude: -84.340), line: .gold),
        
        // Central stations (shared by multiple lines)
        MARTAStationData(id: "C01", name: "Five Points", coordinate: CLLocationCoordinate2D(latitude: 33.754, longitude: -84.392), line: .red, additionalLines: [.blue, .green, .gold]),
        MARTAStationData(id: "C02", name: "Peachtree Center", coordinate: CLLocationCoordinate2D(latitude: 33.759, longitude: -84.387), line: .red, additionalLines: [.gold]),
    ]
    
    private init() {}
    
    func findNearestStations(to coordinate: CLLocationCoordinate2D, limit: Int = 3) async throws -> [MARTAStation] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Calculate distances and sort
        let stationsWithDistances = martaStations.map { station in
            let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            let distance = location.distance(from: stationLocation)
            return (station: station, distance: distance)
        }.sorted { $0.distance < $1.distance }
        
        // Convert to MARTAStation and limit results
        return Array(stationsWithDistances.prefix(limit)).map { item in
            MARTAStation(
                name: item.station.name,
                coordinate: item.station.coordinate,
                line: item.station.line,
                distanceFromUser: item.distance
            )
        }
    }
    
    func getRoutesBetweenStations(from: MARTAStation, to: MARTAStation) async throws -> [MARTARoute] {
        // This would integrate with MARTA's actual API
        // For now, return a simplified route
        return [
            MARTARoute(
                fromStation: from,
                toStation: to,
                estimatedTime: TimeInterval(15 * 60), // 15 minutes
                line: from.line
            )
        ]
    }
    
    func createMultimodalRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MARTAMultimodalRoute {
        // Find nearest stations to both source and destination
        let sourceStations = try await findNearestStations(to: source, limit: 2)
        let destinationStations = try await findNearestStations(to: destination, limit: 2)
        
        guard let nearestSourceStation = sourceStations.first,
              let nearestDestinationStation = destinationStations.first else {
            throw MARTATransitError.noStationsFound
        }
        
        // Calculate walking route to source station
        let walkToStation = try await calculateWalkingRoute(from: source, to: nearestSourceStation.coordinate)
        
        // Get transit route between stations
        let transitRoutes = try await getRoutesBetweenStations(from: nearestSourceStation, to: nearestDestinationStation)
        guard let transitRoute = transitRoutes.first else {
            throw MARTATransitError.noTransitRouteFound
        }
        
        // Calculate walking route from destination station
        let walkFromStation = try await calculateWalkingRoute(from: nearestDestinationStation.coordinate, to: destination)
        
        return MARTAMultimodalRoute(
            walkToStation: walkToStation,
            transitRoute: transitRoute,
            walkFromStation: walkFromStation,
            totalEstimatedTime: walkToStation.expectedTravelTime + transitRoute.estimatedTime + walkFromStation.expectedTravelTime
        )
    }
    
    private func calculateWalkingRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        return try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let route = response?.routes.first {
                    continuation.resume(returning: route)
                } else {
                    continuation.resume(throwing: MARTATransitError.noWalkingRouteFound)
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct MARTAStationData {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let line: MARTALine
    let additionalLines: [MARTALine]?
    
    init(id: String, name: String, coordinate: CLLocationCoordinate2D, line: MARTALine, additionalLines: [MARTALine]? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.line = line
        self.additionalLines = additionalLines
    }
}

struct MARTAStation {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let line: MARTALine
    let distanceFromUser: CLLocationDistance?
    
    init(name: String, coordinate: CLLocationCoordinate2D, line: MARTALine, distanceFromUser: CLLocationDistance? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.line = line
        self.distanceFromUser = distanceFromUser
    }
}

struct MARTARoute {
    let fromStation: MARTAStation
    let toStation: MARTAStation
    let estimatedTime: TimeInterval
    let line: MARTALine
}

struct MARTAMultimodalRoute {
    let walkToStation: MKRoute
    let transitRoute: MARTARoute
    let walkFromStation: MKRoute
    let totalEstimatedTime: TimeInterval
}

enum MARTATransitError: Error, LocalizedError {
    case noStationsFound
    case noTransitRouteFound
    case noWalkingRouteFound
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noStationsFound:
            return "No MARTA stations found nearby"
        case .noTransitRouteFound:
            return "No transit route found between stations"
        case .noWalkingRouteFound:
            return "Unable to calculate walking route"
        case .apiError(let message):
            return "MARTA API error: \(message)"
        }
    }
}