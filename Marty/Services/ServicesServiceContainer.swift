//
//  ServiceContainer.swift
//  Marty
//
//  Dependency injection container for services
//  Enables lazy loading and better testability
//

import Foundation
import SwiftUI

@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {}
    
    // MARK: - Service Instances (Lazy Loading)
    lazy var locationService: LocationServiceProtocol = LocationService.shared
    lazy var searchService: SearchServiceProtocol = SearchService.shared
    lazy var directionsService: DirectionsServiceProtocol = DirectionsService.shared
    
    // MARK: - Testing Support
    func setLocationService(_ service: LocationServiceProtocol) {
        self.locationService = service
    }
    
    func setSearchService(_ service: SearchServiceProtocol) {
        self.searchService = service
    }
    
    func setDirectionsService(_ service: DirectionsServiceProtocol) {
        self.directionsService = service
    }
}

// MARK: - Environment Key for SwiftUI
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
